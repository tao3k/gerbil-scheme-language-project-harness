
(import :gerbil/gambit
        :std/misc/process)

(def (status->exit-code status)
  (if (zero? status)
    0
    (let (code (quotient status 256))
      (if (zero? code) 1 code))))

(def (run-command! command)
  (let (status (run-process command
                             stdin-redirection: #f
                             stdout-redirection: #f
                             stderr-redirection: #f
                             coprocess: process-status
                             check-status: #f))
    (exit (status->exit-code status))))

(def (gsc-wrapper-main real-gsc gambit-runtime-arg args)
  (run-command! (append (list real-gsc gambit-runtime-arg) args)))
