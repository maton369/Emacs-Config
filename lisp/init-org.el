;; -*- lexical-binding: t; -*-
;; init-org.el -- Org-mode + LaTeX writing environment

;; --- org-fragtog: auto-toggle LaTeX fragment preview ---
(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; --- Org LaTeX preview ---
(use-package org
  :defer t
  :config
  (setq org-startup-with-latex-preview t)
  (plist-put org-format-latex-options :scale 1.5))

;; --- citar: bibliography management ---
(use-package citar
  :after org
  :config
  (setq org-cite-global-bibliography '("~/org/references.bib")
        org-cite-insert-processor 'citar
        org-cite-activate-processor 'citar
        org-cite-follow-processor 'citar))

;; --- LaTeX export settings ---
(with-eval-after-load 'ox-latex
  (setq org-latex-compiler "lualatex"
        org-latex-pdf-process
        '("latexmk -f -pdf -%latex -interaction=nonstopmode -output-directory=%o %f")
        org-latex-packages-alist '(("" "amsmath" t)
                                   ("" "amssymb" t))))

;; --- AUCTeX ---
(use-package tex
  :straight auctex
  :defer t
  :config
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-engine 'luatex))

(use-package cdlatex
  :hook ((org-mode . turn-on-org-cdlatex)
         (LaTeX-mode . turn-on-cdlatex)))

;; --- Auto-compile on save and clean intermediate files ---
(defun my/latex-compile-and-clean ()
  "Compile current .tex with latexmk, then remove intermediate files."
  (interactive)
  (when-let ((file (buffer-file-name)))
    (when (string-match-p "\\.tex\\'" file)
      (let ((default-directory (file-name-directory file))
            (name (file-name-nondirectory file)))
        (compile
         (format "latexmk -pdf -lualatex -interaction=nonstopmode %s && latexmk -c %s"
                 (shell-quote-argument name)
                 (shell-quote-argument name)))))))

(add-hook 'LaTeX-mode-hook
          (lambda ()
            (add-hook 'after-save-hook #'my/latex-compile-and-clean nil t)))

;; --- PDF viewer ---
(use-package pdf-tools
  :mode ("\\.pdf\\'" . pdf-view-mode)
  :config
  (pdf-tools-install :no-query)
  (setq pdf-view-display-size 'fit-page
        pdf-view-use-scaling t)
  (add-hook 'pdf-view-mode-hook
            (lambda ()
              (display-line-numbers-mode -1)
              (pdf-view-midnight-minor-mode -1)
              (pdf-view-fit-page-to-window))))

(provide 'init-org)
