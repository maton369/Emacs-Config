;; -*- lexical-binding: t; -*-
;; early-init.el -- Loaded before init.el and package.el

;; Increase GC threshold during startup for faster load
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; Restore GC after startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 64 1024 1024)  ; 64MB
                  gc-cons-percentage 0.1)))

;; Suppress UI elements before they render
(setq inhibit-startup-message t
      inhibit-startup-echo-area-message user-login-name
      initial-scratch-message nil)

(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)

;; Disable package.el (we use straight.el)
(setq package-enable-at-startup nil)

;; Prevent unwanted resizing
(setq frame-inhibit-implied-resize t)

;; Faster filename handling during startup
(unless (or (daemonp) noninteractive)
  (let ((old-file-name-handler-alist file-name-handler-alist))
    (setq file-name-handler-alist nil)
    (add-hook 'emacs-startup-hook
              (lambda ()
                (setq file-name-handler-alist
                      (delete-dups
                       (append file-name-handler-alist
                               old-file-name-handler-alist)))))))

;; Native compilation settings
(when (featurep 'native-compile)
  (setq native-comp-async-report-warnings-errors nil
        native-comp-jit-compilation t))

;; Prevent font cache compaction during GC (fixes lag with inline images)
(setq inhibit-compacting-font-caches t)
