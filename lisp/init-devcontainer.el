;; -*- lexical-binding: t; -*-
;; init-devcontainer.el -- VS Code-compatible devcontainer support

(use-package devcontainer
  :straight (:host github :repo "lina-bh/devcontainer.el")
  :commands (devcontainer-up devcontainer-down)
  :config
  (setq devcontainer-engine 'docker))

(provide 'init-devcontainer)
