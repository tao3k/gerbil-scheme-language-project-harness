
(import :gerbil/gambit
        :std/misc/process)

(export main)

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

(def (main . args)
  (let ((real-gsc (getenv "GERBIL_WRAPPER_REAL_GSC" #f))
        (gambit-runtime-arg
         (getenv "GERBIL_WRAPPER_RUNTIME_ARG" #f)))
    (unless real-gsc
      (display "GERBIL_WRAPPER_REAL_GSC is required\n"
               (current-error-port))
      (exit 64))
    (unless gambit-runtime-arg
      (display "GERBIL_WRAPPER_RUNTIME_ARG is required\n"
               (current-error-port))
      (exit 64))
    (gsc-wrapper-main real-gsc gambit-runtime-arg args)))

(apply main (cdr (command-line)))
