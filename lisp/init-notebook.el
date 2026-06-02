;; -*- lexical-binding: t; -*-
;; init-notebook.el -- Jupyter, code-cells

;; Jupyter (like molten-nvim)
;; NOTE: :build (:not compile) prevents byte-compilation.
;; See: https://github.com/emacs-jupyter/jupyter/issues/613
(use-package jupyter
  :straight (:build (:not compile))
  :commands (jupyter-run-repl jupyter-connect-repl jupyter-server-list-kernels
             jupyter-eval-region jupyter-repl-associate-buffer)
  :config
  (setq jupyter-repl-echo-eval-p t
        jupyter-eval-use-overlays t)

  ;; Suppress all jupyter popup windows
  (add-to-list 'display-buffer-alist
               '("\\*jupyter-" (display-buffer-no-window) (allow-no-window . t)))

  ;; Fix: python-ts-mode is not derived from python-mode
  (defun jupyter-eval-display-with-overlay-p ()
    (and jupyter-eval-use-overlays jupyter-current-client))

  ;; --- Per-cell image capture (store raw data for dynamic sizing) ---
  (defvar my/jupyter-current-cell-end nil
    "Cell-end position of the currently evaluating cell.")

  (defvar my/jupyter-cell-images (make-hash-table :test 'eql)
    "Hash table mapping cell-end positions to raw image data (DATA . TYPE) pairs.")

  (advice-add 'jupyter-insert-image :after
              (lambda (data type &optional metadata)
                (when my/jupyter-current-cell-end
                  (puthash my/jupyter-current-cell-end
                           (cons (cons data type)
                                 (gethash my/jupyter-current-cell-end
                                          my/jupyter-cell-images))
                           my/jupyter-cell-images)))))

;; --- CUI image support via kitty-graphics ---
;; jupyter filters out image MIME types in terminal Emacs via
;; jupyter-nongraphic-mime-types (which excludes image/png etc.).
;; When kitty-graphics is active, dynamically bind the nongraphic list
;; to the full jupyter-mime-types so images are processed and
;; jupyter-insert-image fires (our :after advice captures the raw data).
(with-eval-after-load 'jupyter-mime
  (advice-add 'jupyter-insert :around
              (lambda (orig-fn &rest args)
                (if (bound-and-true-p kitty-graphics-mode)
                    (let ((jupyter-nongraphic-mime-types jupyter-mime-types))
                      (apply orig-fn args))
                  (apply orig-fn args)))))

;; --- Inline display functions ---
(defvar-local my/jupyter-cell-overlays nil
  "Alist of (CELL-END . OVERLAY) for inline outputs.")

(defvar my/jupyter-temp-image-files nil
  "List of temp image files created for kitty-graphics display.")

(defun my/jupyter--make-image-string (data type)
  "Create image propertized string from DATA of TYPE, sized to ~60% of window width."
  (let ((max-w (min 640 (floor (* (window-pixel-width) 0.6)))))
    (propertize " " 'display
                (create-image data type 'data :max-width max-w))))

(defun my/jupyter-clear-cell-overlay (pos)
  "Remove inline overlay near POS."
  (setq my/jupyter-cell-overlays
        (cl-remove-if
         (lambda (pair)
           (when (<= (abs (- (car pair) pos)) 2)
             (let ((ov (cdr pair)))
               (if (and (bound-and-true-p kitty-graphics-mode)
                        (fboundp 'kitty-gfx--remove-overlay))
                   (kitty-gfx--remove-overlay ov)
                 (delete-overlay ov)))
             t))
         my/jupyter-cell-overlays)))

(defun my/jupyter-clear-all-overlays ()
  "Clear all inline cell output overlays."
  (interactive)
  (dolist (pair my/jupyter-cell-overlays)
    (let ((ov (cdr pair)))
      (if (and (bound-and-true-p kitty-graphics-mode)
               (fboundp 'kitty-gfx--remove-overlay))
          (kitty-gfx--remove-overlay ov)
        (delete-overlay ov))))
  (setq my/jupyter-cell-overlays nil)
  (clrhash my/jupyter-cell-images)
  (setq my/jupyter-current-cell-end nil)
  ;; Clean up temp image files
  (dolist (f my/jupyter-temp-image-files)
    (when (file-exists-p f) (delete-file f)))
  (setq my/jupyter-temp-image-files nil)
  (setq my/jupyter--override-kitty-inhibit nil)
  (when (fboundp 'jupyter-eval-remove-overlays)
    (jupyter-eval-remove-overlays)))

;; --- Override kitty-gfx refresh for jupyter images ---
;; kitty-gfx's native refresh cannot be made to work reliably (the
;; inhibition check is not the only blocker).  Instead we manually
;; delete all placements on scroll and let kitty-gfx re-place the
;; visible ones.
(defvar my/jupyter--override-kitty-inhibit nil
  "When non-nil, jupyter scroll handler manages kitty image lifecycle.")
(defvar my/jupyter--scroll-guard nil
  "Non-nil while scroll handler is active (prevents re-entrancy).")
(defvar my/jupyter--scroll-timer nil
  "Debounce timer for scroll refresh.")
(defvar my/jupyter--refresh-guard nil
  "Non-nil while kitty-gfx--refresh is running (prevents re-entrancy).")
(defvar my/jupyter--redisplay-timer nil
  "Debounce timer for post-command redisplay.")
(defvar my/jupyter--avoiding-overlay nil
  "Non-nil while moving cursor out of image overlay.")

(with-eval-after-load 'kitty-graphics
  ;; Bypass inhibition so kitty-gfx--refresh can run after our deletions
  (advice-add 'kitty-gfx--refresh-inhibited-p :around
              (lambda (orig-fn)
                (if my/jupyter--override-kitty-inhibit nil (funcall orig-fn))))

  ;; Debounce post-command redisplay to prevent flicker on cursor movement
  (advice-add 'kitty-gfx--on-redisplay :around
              (lambda (orig-fn)
                (if my/jupyter--override-kitty-inhibit
                    (progn
                      (when my/jupyter--redisplay-timer
                        (cancel-timer my/jupyter--redisplay-timer))
                      (setq my/jupyter--redisplay-timer
                            (run-with-idle-timer
                             0.2 nil
                             (lambda ()
                               (setq my/jupyter--redisplay-timer nil)
                               (funcall orig-fn)))))
                  (funcall orig-fn))))

  ;; Block refresh during scroll debounce AND prevent re-entrancy
  (advice-add 'kitty-gfx--refresh :around
              (lambda (orig-fn &rest args)
                (unless (or my/jupyter--scroll-guard
                            my/jupyter--refresh-guard)
                  (let ((my/jupyter--refresh-guard t))
                    (apply orig-fn args)))))

  (defun my/jupyter--on-scroll (win _start)
    "Delete kitty image placements on scroll, force re-render of visible ones."
    (when (and my/jupyter--override-kitty-inhibit
               (not my/jupyter--scroll-guard))
      (let ((buf (window-buffer win)))
        (when (buffer-local-value 'kitty-gfx--overlays buf)
          (setq my/jupyter--scroll-guard t)
          ;; Nuclear: tell terminal directly to delete ALL image placements
          (send-string-to-terminal "\e_Ga=d,d=a\e\\")
          ;; Reset kitty-gfx tracking so it re-places from scratch
          (with-current-buffer buf
            (dolist (ov kitty-gfx--overlays)
              (overlay-put ov 'kitty-gfx-last-row nil)
              (overlay-put ov 'kitty-gfx-last-col nil)))
          ;; Debounced re-place
          (when my/jupyter--scroll-timer
            (cancel-timer my/jupyter--scroll-timer))
          (setq my/jupyter--scroll-timer
                (run-with-idle-timer
                 0.15 nil
                 (lambda ()
                   (setq my/jupyter--scroll-timer nil
                         my/jupyter--scroll-guard nil
                         kitty-gfx--force-redisplay t)
                   (message nil)
                   (kitty-gfx--refresh))))))))
  (add-hook 'window-scroll-functions #'my/jupyter--on-scroll)

  ;; Kick cursor out of image overlays to prevent trapping/hang
  (defun my/jupyter--avoid-image-overlay ()
    "Move cursor away from kitty-gfx image overlays."
    (when (and my/jupyter--override-kitty-inhibit
               (not my/jupyter--avoiding-overlay))
      (let ((my/jupyter--avoiding-overlay t))
        (dolist (ov (overlays-at (point)))
          (when (overlay-get ov 'kitty-gfx-image-id)
            (if (memq last-command '(evil-next-line evil-next-visual-line
                                     next-line evil-forward-char))
                (goto-char (overlay-end ov))
              (goto-char (1- (overlay-start ov)))))))))
  (add-hook 'post-command-hook #'my/jupyter--avoid-image-overlay)

  ;; Clean shutdown: strip all advice/hooks/timers so kill-emacs doesn't hang
  (add-hook 'kill-emacs-hook
            (lambda ()
              ;; Remove hooks first
              (remove-hook 'window-scroll-functions #'my/jupyter--on-scroll)
              (remove-hook 'post-command-hook #'my/jupyter--avoid-image-overlay)
              (remove-hook 'post-command-hook #'kitty-gfx--on-redisplay)
              (remove-hook 'window-scroll-functions #'kitty-gfx--on-window-scroll)
              ;; Cancel timers
              (when my/jupyter--scroll-timer
                (cancel-timer my/jupyter--scroll-timer)
                (setq my/jupyter--scroll-timer nil))
              (when my/jupyter--redisplay-timer
                (cancel-timer my/jupyter--redisplay-timer)
                (setq my/jupyter--redisplay-timer nil))
              ;; Reset flags
              (setq my/jupyter--override-kitty-inhibit nil
                    my/jupyter--scroll-guard nil
                    my/jupyter--refresh-guard nil))))

(defun my/jupyter-place-images (cell-end source-buf)
  "Place captured images for CELL-END as overlay in SOURCE-BUF.
Each cell keeps its own image overlay.  kitty-gfx handles
visibility — only images that fit on screen are rendered."
  (let ((raw-images (gethash cell-end my/jupyter-cell-images)))
    (when (and raw-images (buffer-live-p source-buf))
      (with-current-buffer source-buf
        (my/jupyter-clear-cell-overlay cell-end)
        (save-excursion
          (goto-char cell-end)
          ;; Position at end of cell's last code line (cell-end may be
          ;; at the next cell's # %% delimiter or at point-max)
          (when (and (> cell-end (point-min)) (bolp))
            (forward-char -1))
          (end-of-line)
          (if (bound-and-true-p kitty-graphics-mode)
              ;; CUI: kitty-graphics protocol
              (progn
                (setq my/jupyter--override-kitty-inhibit t)
                ;; Take over kitty-gfx lifecycle: remove its native handlers
                (remove-hook 'window-scroll-functions #'kitty-gfx--on-window-scroll)
                (remove-hook 'post-command-hook #'kitty-gfx--on-redisplay)
                (message nil)
                (dolist (pair (nreverse (copy-sequence raw-images)))
                  (let* ((data (car pair))
                         (type (cdr pair))
                         (ext (pcase type ('png ".png") ('jpeg ".jpg") (_ ".png")))
                         (tmp (make-temp-file "jupyter-img-" nil ext)))
                    (with-temp-buffer
                      (set-buffer-multibyte nil)
                      (insert data)
                      (write-region (point-min) (point-max) tmp nil 'silent))
                    (push tmp my/jupyter-temp-image-files)
                    ;; Non-zero-width overlay: cover the first char of the
                    ;; next line so posn-at-point returns the TOP of the
                    ;; blank display (not the bottom, as with zero-width).
                    ;; This places the image below the code, not on top of it.
                    (let* ((next-bol (line-beginning-position 2))
                           (img-beg next-bol)
                           (img-end (min (1+ next-bol) (point-max)))
                           (max-c (min (- (window-width) 2) 60))
                           (max-r 12))
                      (when (> img-end img-beg)
                        (when-let ((ov (kitty-gfx-display-image tmp img-beg img-end max-c max-r)))
                          (push (cons cell-end ov) my/jupyter-cell-overlays)))))))
            ;; GUI: use create-image overlays
            (let* ((ov-pos (line-end-position))
                   (ov (make-overlay ov-pos ov-pos)))
              (overlay-put ov 'after-string
                           (concat "\n"
                                   (mapconcat
                                    (lambda (pair)
                                      (my/jupyter--make-image-string
                                       (car pair) (cdr pair)))
                                    (nreverse (copy-sequence raw-images))
                                    "\n")
                                   "\n"))
              (push (cons cell-end ov) my/jupyter-cell-overlays)))))
      ;; Also hide any display window that snuck through
      (dolist (buf (buffer-list))
        (when (string-match-p "\\*jupyter-display" (buffer-name buf))
          (when-let ((win (get-buffer-window buf t)))
            (delete-window win)))))))

;; --- Resize: re-render overlays when window size changes ---
(defvar my/jupyter-refresh-timer nil
  "Debounce timer for overlay refresh on window resize.")

(defun my/jupyter--do-refresh-overlays ()
  "Re-render all jupyter cell overlays at current window size."
  (dolist (buf (buffer-list))
    (with-current-buffer buf
      (when my/jupyter-cell-overlays
        (let ((cell-ends (mapcar #'car (copy-sequence my/jupyter-cell-overlays))))
          (dolist (cell-end cell-ends)
            (when (gethash cell-end my/jupyter-cell-images)
              (my/jupyter-place-images cell-end buf))))))))

(defun my/jupyter-refresh-overlays (&optional _frame)
  "Debounced re-render of jupyter cell overlays on window resize.
kitty-graphics handles its own refresh, so skip in CUI."
  (unless (bound-and-true-p kitty-graphics-mode)
    (when my/jupyter-refresh-timer
      (cancel-timer my/jupyter-refresh-timer))
    (setq my/jupyter-refresh-timer
          (run-with-idle-timer 0.3 nil #'my/jupyter--do-refresh-overlays))))

(add-hook 'window-size-change-functions #'my/jupyter-refresh-overlays)

;; --- Start kernel silently ---
(defun my/jupyter-start-kernel ()
  "Start jupyter kernel in background and associate with current buffer."
  (interactive)
  (require 'jupyter)
  (let ((spec (jupyter-completing-read-kernelspec)))
    (jupyter-run-repl (jupyter-kernelspec-name spec) nil t nil nil))
  ;; Hide REPL window if it appeared
  (dolist (buf (buffer-list))
    (when (string-match-p "\\*jupyter-repl" (buffer-name buf))
      (when-let ((win (get-buffer-window buf t)))
        (delete-window win))))
  (message "Jupyter kernel started."))

;; --- Cell evaluation commands ---
(defun my/jupyter-eval-cell ()
  "Evaluate current cell and display results inline."
  (interactive)
  (unless (bound-and-true-p jupyter-current-client)
    (user-error "No Jupyter kernel connected. Run SPC m i first"))
  (when (bound-and-true-p jupyter-current-client)
    (pcase-let ((`(,start ,end) (code-cells--bounds 1 nil t)))
      (let ((cell-end end)
            (buf (current-buffer)))
        ;; Clear images for this cell and set current cell-end
        (remhash cell-end my/jupyter-cell-images)
        (setq my/jupyter-current-cell-end cell-end)
        ;; Evaluate
        (jupyter-eval-region nil start end)
        ;; Poll for captured images
        (run-with-timer 1.0 nil #'my/jupyter-place-images cell-end buf)
        (run-with-timer 3.0 nil #'my/jupyter-place-images cell-end buf)
        (run-with-timer 6.0 nil #'my/jupyter-place-images cell-end buf)))))

(defun my/jupyter-eval-cell-and-step ()
  "Evaluate current cell inline and move to next."
  (interactive)
  (my/jupyter-eval-cell)
  (code-cells-forward-cell))

(defun my/jupyter-diag ()
  "Diagnose jupyter + code-cells + kitty-gfx state for the current buffer."
  (interactive)
  (message (concat
            (format "kitty: %s | " (bound-and-true-p kitty-graphics-mode))
            (format "backend: %s | " (and (boundp 'kitty-gfx--active-backend) kitty-gfx--active-backend))
            (format "override: %s | " my/jupyter--override-kitty-inhibit)
            (format "gfx-ovs: %s | " (and (boundp 'kitty-gfx--overlays) (length kitty-gfx--overlays)))
            (format "my-ovs: %s | " (length my/jupyter-cell-overlays))
            (format "client: %s | " (if (bound-and-true-p jupyter-current-client) "Y" "N"))
            (format "cells: %s" (bound-and-true-p code-cells-mode)))))

(defun my/jupyter-test-kitty ()
  "Test kitty-graphics by displaying a generated test image at point."
  (interactive)
  (unless (bound-and-true-p kitty-graphics-mode)
    (user-error "kitty-graphics-mode is not active"))
  (let ((tmp (make-temp-file "kitty-test-" nil ".png")))
    ;; Generate a small red square PNG using ImageMagick
    (if (executable-find "magick")
        (call-process "magick" nil nil nil
                      "-size" "100x100" "xc:red" tmp)
      (if (executable-find "convert")
          (call-process "convert" nil nil nil
                        "-size" "100x100" "xc:red" tmp)
        (user-error "ImageMagick not found")))
    (message nil)
    (let ((ov (kitty-gfx-display-image tmp)))
      (if ov
          (progn
            (setq my/jupyter--override-kitty-inhibit t)
            (run-with-idle-timer 0.3 nil (lambda () (message nil)))
            (message "OK: overlay at %d-%d, backend=%s"
                     (overlay-start ov) (overlay-end ov)
                     (and (boundp 'kitty-gfx--active-backend) kitty-gfx--active-backend)))
        (message "FAIL: kitty-gfx-display-image returned nil")))))

(defun my/jupyter-eval-buffer ()
  "Evaluate all cells in buffer sequentially."
  (interactive)
  (unless (bound-and-true-p jupyter-current-client)
    (user-error "No Jupyter kernel connected. Run SPC m i first"))
  (unless (bound-and-true-p code-cells-mode)
    (user-error "code-cells-mode is not active in this buffer"))
  (my/jupyter-clear-all-overlays)
  (let ((cells '()))
    (save-excursion
      (goto-char (point-min))
      ;; Collect all cells: try bounds at each cell boundary
      (while (not (eobp))
        (ignore-errors
          (pcase-let ((`(,start ,end) (code-cells--bounds 1 nil t)))
            (when (and start end (< start end))
              (push (list start end) cells))))
        (let ((pos (point)))
          (code-cells-forward-cell)
          (when (= (point) pos)
            (goto-char (point-max))))))
    (if cells
        (progn
          (message "Evaluating %d cells..." (length cells))
          (my/jupyter--eval-next-cell (nreverse cells) (current-buffer)))
      (user-error "No cells found (collected 0). Check # %%%% markers"))))

(defun my/jupyter--eval-next-cell (cells buf)
  "Evaluate first cell in CELLS, place images, then proceed to next."
  (when (and cells (buffer-live-p buf))
    (with-current-buffer buf
      (let* ((bounds (car cells))
             (start (car bounds))
             (end (cadr bounds))
             (remaining (cdr cells)))
        ;; Set current cell-end so advice tags images to this cell
        (remhash end my/jupyter-cell-images)
        (setq my/jupyter-current-cell-end end)
        ;; Evaluate
        (jupyter-eval-region nil start end)
        ;; Place images for each cell
        (run-with-timer 1.0 nil #'my/jupyter-place-images end buf)
        (run-with-timer 3.0 nil #'my/jupyter-place-images end buf)
        ;; Evaluate next cell at 4s
        (when remaining
          (run-with-timer 4.0 nil #'my/jupyter--eval-next-cell remaining buf))))))

;; Code-cells
(use-package code-cells
  :commands (code-cells-mode code-cells-convert-ipynb)
  :init
  (defun my/open-ipynb ()
    "Open .ipynb files via code-cells jupytext conversion."
    (require 'code-cells)
    (code-cells-convert-ipynb))
  (add-to-list 'auto-mode-alist '("\\.ipynb\\'" . my/open-ipynb))
  :hook ((python-ts-mode . code-cells-mode)
         (julia-mode . code-cells-mode))
  :config
  (setq code-cells-convert-ipynb-style
        '(("jupytext" "--to" "ipynb" "--output" "-")
          ("jupytext" "--to" "auto:percent" "--output" "-")
          (lambda () #'python-ts-mode)))
  (let ((map code-cells-mode-map))
    (define-key map (kbd "M-p") 'code-cells-backward-cell)
    (define-key map (kbd "M-n") 'code-cells-forward-cell)))

;; ]c / [c cell navigation (like Neovim)
(with-eval-after-load 'evil
  (evil-define-key 'normal code-cells-mode-map
    "]c" 'code-cells-forward-cell
    "[c" 'code-cells-backward-cell))

;; Leader bindings: defined in init-keybindings.el under "m" prefix

(provide 'init-notebook)
