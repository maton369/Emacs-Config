;; -*- lexical-binding: t; -*-
;; init-org.el -- Org-mode + LaTeX writing environment

;; --- org-fragtog: auto-toggle LaTeX fragment preview ---
(use-package org-fragtog
  :hook (org-mode . org-fragtog-mode))

;; --- Org LaTeX preview ---
(use-package org
  :defer t
  :custom
  (org-startup-with-latex-preview t)
  (org-preview-latex-default-process 'dvipng)
  :config
  (plist-put org-format-latex-options :scale 1.5)
  ;; プレビュー用ヘッダーから fontspec を除外（dvipng は DVI ベースのため lualatex 不可）
  ;; エクスポート時は lualatex + fontspec が使われる
  (setq org-format-latex-header
        "\\documentclass{article}
\\usepackage[usenames]{color}
\\usepackage{amsmath}
\\usepackage{amssymb}
\\pagestyle{empty}
\\setlength{\\textwidth}{\\paperwidth}
\\addtolength{\\textwidth}{-3cm}
\\setlength{\\oddsidemargin}{1.5cm}
\\addtolength{\\oddsidemargin}{-2.54cm}
\\setlength{\\evensidemargin}{\\oddsidemargin}
\\setlength{\\textheight}{\\paperheight}
\\addtolength{\\textheight}{-\\headheight}
\\addtolength{\\textheight}{-\\headsep}
\\addtolength{\\textheight}{-\\footskip}
\\addtolength{\\textheight}{-3cm}
\\setlength{\\topmargin}{1.5cm}
\\addtolength{\\topmargin}{-2.54cm}")

  ;; Fix: Org 9.7 adds fontspec to preview preamble when lualatex is detected.
  ;; fontspec requires lualatex but dvipng uses plain latex → DVI.
  ;; Force org-latex-compiler to nil during preview so fontspec is not added.
  (advice-add 'org-create-formula-image :around
              (lambda (orig-fn string tofile options buffer &rest args)
                (let ((org-latex-compiler nil))
                  (apply orig-fn string tofile options buffer args)))))

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

;; --- PDF viewer (GUI only) ---
(when (display-graphic-p)
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
                (pdf-view-fit-page-to-window)))))

(provide 'init-org)
