;;; -*- Gerbil -*-
;;; Runtime adapter for generated gsc wrapper launchers.
;;; Boundary:
;;; - build.ss owns wrapper generation, this file owns runtime process behavior.
;;; - Keep compiler stdio transparent while normalizing wrapper exit status.

(import :gerbil/gambit
        (only-in :std/misc/process process-status run-process))

(export main)

;;; Boundary:
;;; - Gambit process status encodes exit code in the high byte.
;;; - Preserve non-zero signals as generic failure when no code is available.
;; : (-> ProcessStatus ExitCode)
(def (status->exit-code status)
  (if (zero? status)
    0
    (let (code (quotient status 256))
      (if (zero? code) 1 code))))

;; : (-> ErrorMessage Unit)
(def (emit-error-line! text)
  (display text (current-error-port))
  (newline (current-error-port)))

;;; Boundary:
;;; - This wrapper must preserve gsc stdio so callers see native compiler output.
;;; - Only the final status is normalized back into a process exit code.
;; : (-> Command NeverReturns)
(def (run-command! command)
  (let (status (run-process command
                             stdin-redirection: #f
                             stdout-redirection: #f
                             stderr-redirection: #f
                             coprocess: process-status
                             check-status: #f))
    (exit (status->exit-code status))))

;; : (-> RealGsc GambitRuntimeArg (List String) NeverReturns)
(def (gsc-wrapper-main real-gsc gambit-runtime-arg args)
  (run-command! (append (list real-gsc gambit-runtime-arg) args)))

;;; Boundary:
;;; - build.ss writes this runtime wrapper; runtime validation belongs here.
;;; - Environment variables are the script contract with the generated launcher.
;; main
;;   : (-> (List String) NeverReturns)
;;   | doc m%
;;       `main args ...` validates wrapper environment variables and execs the
;;       real `gsc` with the configured Gambit runtime argument.
;;
;;       # Examples
;;       ```scheme
;;       (main "-c" "src/cli.ss")
;;       ;; => exits with the real gsc status
;;       ```
;;     %
(def (main . args)
  (let ((real-gsc (getenv "GERBIL_WRAPPER_REAL_GSC" #f))
        (gambit-runtime-arg
         (getenv "GERBIL_WRAPPER_RUNTIME_ARG" #f)))
    (unless real-gsc
      (emit-error-line! "GERBIL_WRAPPER_REAL_GSC is required")
      (exit 64))
    (unless gambit-runtime-arg
      (emit-error-line! "GERBIL_WRAPPER_RUNTIME_ARG is required")
      (exit 64))
    (gsc-wrapper-main real-gsc gambit-runtime-arg args)))

(apply main (cdr (command-line)))
