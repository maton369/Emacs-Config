;; -*- lexical-binding: t; -*-
;; init-ai.el -- gptel

;; Gptel: LLM chat (like CopilotChat/avante, Claude excluded per user request)
(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :config
  (setq gptel-default-mode 'org-mode))

(provide 'init-ai)
