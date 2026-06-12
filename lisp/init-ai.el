;; -*- lexical-binding: t; -*-
;; init-ai.el -- gptel

;; Gptel: LLM chat (like CopilotChat/avante, Claude excluded per user request)
(use-package gptel
  :commands (gptel gptel-send gptel-menu)
  :config
  (setq gptel-default-mode 'org-mode)
  ;; Reusable system prompts. Switch at runtime via gptel-menu (-s).
  (setq gptel-directives
        '((default . "You are a large language model living in Emacs and a helpful assistant. Respond concisely.")
          (writing . "You are a large language model and a writing assistant. Respond concisely.")
          (programming . "You are a large language model and a careful programmer. Provide code and only code as output without any additional text."))))

;; ob-gptel: run LLM prompts as Org Babel `gptel' source blocks, so the
;; prompt and its output live together in one reproducible Org file
;; (article: "プロンプトと出力結果を一つのテキストで保存できると便利").
(use-package ob-gptel
  :straight (:host github :repo "jwiegley/ob-gptel")
  :after org
  :demand t
  :config
  (add-to-list 'org-babel-load-languages '(gptel . t)))

(provide 'init-ai)
