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
;; jupyter filters out image MIME types in terminal Emacs (jupyter-nongraphic-mime-types).
;; When kitty-graphics is active, temporarily pretend display is graphical so that
;; image/png etc. are processed and jupyter-insert-image fires (our :after advice
;; captures the raw data).
(with-eval-after-load 'jupyter-mime
  (advice-add 'jupyter-insert :around
              (lambda (orig-fn &rest args)
                (if (bound-and-true-p kitty-graphics-mode)
                    (cl-letf (((symbol-function 'display-graphic-p)
                               (lambda (&rest _) t)))
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
  (when (fboundp 'jupyter-eval-remove-overlays)
    (jupyter-eval-remove-overlays)))

(defun my/jupyter-place-images (cell-end source-buf)
  "Place captured images for CELL-END as overlay in SOURCE-BUF."
  (let ((raw-images (gethash cell-end my/jupyter-cell-images)))
    (when (and raw-images (buffer-live-p source-buf))
      (with-current-buffer source-buf
        (my/jupyter-clear-cell-overlay cell-end)
        (save-excursion
          (goto-char cell-end)
          (if (bound-and-true-p kitty-graphics-mode)
              ;; CUI: save to temp files, use kitty-graphics protocol
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
                  (let ((pos (line-end-position)))
                    (when-let ((ov (kitty-gfx-display-image tmp pos pos)))
                      (push (cons cell-end ov) my/jupyter-cell-overlays)))))
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
  "Diagnose jupyter + code-cells state for the current buffer."
  (interactive)
  (message (concat
            (format "display-graphic: %s | " (display-graphic-p))
            (format "kitty-gfx: %s | " (bound-and-true-p kitty-graphics-mode))
            (format "major-mode: %s | " major-mode)
            (format "code-cells: %s | " (bound-and-true-p code-cells-mode))
            (format "client: %s | " (if (bound-and-true-p jupyter-current-client) "connected" "nil"))
            (format "images: %s | " (hash-table-count my/jupyter-cell-images))
            (format "overlays: %s | " (length my/jupyter-cell-overlays))
            (format "buffer: %s"  (buffer-name)))))

(defun my/jupyter-eval-buffer ()
  "Evaluate all cells in buffer sequentially."
  (interactive)
  (unless (bound-and-true-p jupyter-current-client)
    (user-error "No Jupyter kernel connected. Run SPC m i first"))
  (unless (bound-and-true-p code-cells-mode)
    (user-error "code-cells-mode is not active in this buffer"))
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
        ;; Place images at 1s and 3s
        (run-with-timer 1.0 nil #'my/jupyter-place-images end buf)
        (run-with-timer 3.0 nil #'my/jupyter-place-images end buf)
        ;; Evaluate next cell at 4s (kernel is sequential, images arrive in order)
        (when remaining
          (run-with-timer 4.0 nil #'my/jupyter--eval-next-cell remaining buf))))))

;; Code-cells
(use-package code-cells
  :commands code-cells-mode
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
