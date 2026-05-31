;; -*- lexical-binding: t; -*-
;; init-debug.el -- Dape (DAP for Python/Go)

;; Dape: Debug Adapter Protocol (like nvim-dap + dap-ui)
(use-package dape
  :commands dape
  :config
  ;; Save buffers on startup
  (add-hook 'dape-on-start-hooks (lambda () (save-some-buffers t t)))

  ;; Python debugpy configuration (like nvim-dap-python)
  (add-to-list 'dape-configs
               `(debugpy
                 modes (python-ts-mode python-mode)
                 command "python3"
                 command-args ("-m" "debugpy.adapter")
                 :type "executable"
                 :request "launch"
                 :cwd dape-cwd-fn
                 :program dape-buffer-default
                 :console "integratedTerminal"))

  ;; Go delve configuration (like nvim-dap go/delve)
  (add-to-list 'dape-configs
               `(delve
                 modes (go-ts-mode go-mode)
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-cwd-fn
                 :type "debug"
                 :request "launch"
                 :cwd dape-cwd-fn
                 :program "."))

  ;; Go test debugging
  (add-to-list 'dape-configs
               `(delve-test
                 modes (go-ts-mode go-mode)
                 command "dlv"
                 command-args ("dap" "--listen" "127.0.0.1::autoport")
                 command-cwd dape-cwd-fn
                 :type "debug"
                 :request "launch"
                 :mode "test"
                 :cwd dape-cwd-fn
                 :program "."))

  ;; Inline variable display (like nvim-dap-virtual-text)
  (setq dape-inline-variables t)

  ;; Auto-open UI on debug start
  (add-hook 'dape-on-start-hooks #'dape-info)
  (add-hook 'dape-on-start-hooks #'dape-repl))

(provide 'init-debug)
