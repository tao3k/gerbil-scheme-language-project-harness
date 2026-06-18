;;; -*- Gerbil -*-
;;; Runtime adapter for generated native provider link wrappers.
;;; Boundary:
;;; - build.ss chooses the launcher shape, this file owns link/diagnose runtime.
;;; - Existing provider binaries must survive timeout and compiler failure paths.

(import :gerbil/gambit
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process
                 open-process
                 process-pid
                 process-status
                 run-process))

(export main)

(def +native-artifact-suffixes+
  ["" "__exe.scm" "__exe.c" "__exe_.c" "__exe.o" "__exe_.o"
   "__exe__.c" "__exe__.o"])

;;; Boundary:
;;; - Gambit process status encodes exit code in the high byte.
;;; - Preserve non-zero signals as generic failure when no code is available.
;; : (-> ProcessStatus ExitCode)
(def (status->exit-code status)
  (if (zero? status)
    0
    (let (code (quotient status 256))
      (if (zero? code) 1 code))))

;; : (-> Seconds)
(def (native-timeout-seconds)
  (string->number (getenv "ASP_NATIVE_TIMEOUT_SECONDS" "120")))

;; : (-> Boolean)
(def (native-debug?)
  (getenv "ASP_NATIVE_DEBUG" #f))

;; : (-> Boolean)
(def (native-keep-artifacts?)
  (getenv "ASP_NATIVE_KEEP_ARTIFACTS" #f))

;;; Boundary:
;;; - Gambit emits a family of native intermediates around one temp prefix.
;;; - Keep suffix expansion data-driven so cleanup and diagnostics stay aligned.
;; : (-> NativeTempPrefix (List Path))
(def (native-artifacts tmp)
  (map (cut string-append tmp <>) +native-artifact-suffixes+))

;;; Boundary:
;;; - Cleanup deliberately shells out to rm -f for idempotent artifact removal.
;;; - Failure to remove stale generated files must not hide compiler diagnostics.
;; : (-> (List Path) Unit)
(def (remove-files! paths)
  (when (pair? paths)
    (run-process (cons "rm" (cons "-f" paths))
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #f
                 check-status: #f)))

;;; Boundary:
;;; - Timeout handling owns the process signal policy.
;;; - stdout/stderr stay captured by open-process for later log materialization.
;; : (-> Signal ProcessPid ProcessStatus)
(def (send-signal! signal pid)
  (run-process ["kill" signal pid]
               stdin-redirection: #f
               stdout-redirection: #t
               stderr-redirection: #t
               coprocess: process-status
               check-status: #f))

;;; Boundary:
;;; - Log materialization is lazy.
;;; - Empty output should not create stale files.
;;; - The caller chooses whether the log path becomes a repair receipt.
;; : (-> LogPath OutputText Unit)
(def (write-log! log output)
  (when output
    (call-with-output-file log
      (cut write-string output <>))))

;; : (-> OutputText Boolean)
(def (log-has-content? output)
  (and output (< 0 (string-length output))))

;; : (-> OutputText Unit)
(def (show-debug-output output)
  (when (and (native-debug?) (log-has-content? output))
    (display output (current-error-port))))

;;; Boundary:
;;; - Wrapper messages are assembled as displayable parts at the call site.
;;; - This keeps stderr formatting consistent without hiding branch-specific text.
;; : (-> (List Displayable) Unit)
(def (emit-error-line! parts)
  (for-each (lambda (part) (display part (current-error-port))) parts)
  (newline (current-error-port)))

;;; Process boundary: native compile is still an external gxc command, but the
;;; timeout, status, and cleanup policy are now expressed in Gerbil over
;;; open-process/process-status instead of a shell script.
;; : (-> Command (Vector ProcessStatus OutputText NativeCommandReason))
(def (run-native-command command)
  (let* ((process (open-process [path: (car command)
                                 arguments: (cdr command)
                                 stdin-redirection: #f
                                 stdout-redirection: #t
                                 stderr-redirection: #t
                                 show-console: #f]))
         (pid (number->string (process-pid process)))
         (timeout (native-timeout-seconds))
         (done? #f)
         (status #f)
         (output #f))
    (spawn/name
     ['native-command command]
     (lambda ()
       (try
        (set! output (read-all-as-string process))
        (set! status (process-status process))
        (finally
         (close-port process)
         (set! done? #t)))))
    (let wait ((elapsed 0))
      (cond
       (done? [status output 'done])
       ((>= elapsed timeout)
        (send-signal! "-TERM" pid)
        (thread-sleep! 1)
        (unless done?
          (send-signal! "-KILL" pid))
        (let wait-killed ((remaining 5))
          (cond
           (done? [status output 'timeout])
           ((zero? remaining) [124 output 'timeout])
           (else
            (thread-sleep! 1)
            (wait-killed (- remaining 1))))))
       (else
        (thread-sleep! 1)
        (wait (+ elapsed 1)))))))

;; : (-> NativeTempPrefix Command)
(def (native-compile-command tmp)
  (if (native-debug?)
    ["gxc" "-V" "-exe" "-o" tmp "src/cli.ss"]
    ["gxc" "-exe" "-o" tmp "src/cli.ss"]))

;; : (-> NativeTempPrefix Command)
(def (native-diagnose-command tmp)
  ["gxc" "-S" "-V" "-exe" "-o" tmp "src/cli.ss"])

;;; Boundary:
;;; - A successful native link leaves only the final provider executable.
;;; - Temporary C/object/scm products are build implementation details.
;; : (-> NativeTempPrefix LogPath Unit)
(def (cleanup-native-link-success! tmp log)
  (remove-files! (native-artifacts tmp))
  (remove-files! [log]))

;;; Boundary:
;;; - Failure keeps explicit diagnostics but avoids dirtying the checkout.
;;; - ASP_NATIVE_KEEP_ARTIFACTS upgrades cleanup into a debugging handoff.
;; : (-> NativeTempPrefix LogPath OutputText Unit)
(def (cleanup-native-link-failure! tmp log output)
  (if (native-keep-artifacts?)
    (emit-error-line! ["native compile artifacts prefix: " tmp])
    (remove-files! (native-artifacts tmp)))
  (if (log-has-content? output)
    (begin
      (write-log! log output)
      (emit-error-line! ["native compile log: " log]))
    (remove-files! [log])))

;;; Boundary:
;;; - Link mode owns atomic replacement of the provider executable.
;;; - Existing binaries remain untouched on timeout or compiler failure.
;; : (-> NativeTempPrefix FinalExecutable NeverReturns)
(def (native-link-main tmp final)
  (let* ((log (string-append tmp ".log"))
         (result (run-native-command (native-compile-command tmp)))
         (status (list-ref result 0))
         (output (list-ref result 1))
         (reason (list-ref result 2)))
    (cond
     ((equal? reason 'timeout)
      (emit-error-line! ["native compile timed out after "
                         (native-timeout-seconds)
                         "s; leaving existing provider executable untouched"])
      (show-debug-output output)
      (cleanup-native-link-failure! tmp log output)
      (exit 124))
     ((not (zero? status))
      (show-debug-output output)
      (cleanup-native-link-failure! tmp log output)
      (exit (status->exit-code status)))
     ((not (file-exists? tmp))
      (emit-error-line! ["native compile did not produce executable: " tmp])
      (show-debug-output output)
      (cleanup-native-link-failure! tmp log output)
      (exit 1))
     (else
      (run-process ["mv" tmp final]
                   stdin-redirection: #f
                   stdout-redirection: #f
                   stderr-redirection: #f)
      (cleanup-native-link-success! tmp log)
      (exit 0)))))

;;; Boundary:
;;; - Diagnose mode records compiler output without replacing executables.
;;; - The log/artifact prefix is the contract returned to CI and local repair.
;; : (-> NativeTempPrefix NeverReturns)
(def (native-diagnose-main tmp)
  (let* ((log (string-append tmp ".log"))
         (result (run-native-command (native-diagnose-command tmp)))
         (status (list-ref result 0))
         (output (list-ref result 1))
         (reason (list-ref result 2)))
    (write-log! log output)
    (emit-error-line! ["native diagnose log: " log])
    (emit-error-line! ["native diagnose artifacts prefix: " tmp])
    (cond
     ((equal? reason 'timeout)
      (emit-error-line! ["native diagnose timed out after "
                         (native-timeout-seconds)
                         "s before Gambit link"])
      (show-debug-output output)
      (exit 124))
     ((not (zero? status))
      (show-debug-output output)
      (exit (status->exit-code status)))
     (else
      (emit-error-line! ["native diagnose gerbil-front-end=ok gambit-link=skipped"])
      (exit 0)))))

;;; Boundary:
;;; - build.ss chooses link vs diagnose by generated launcher arity.
;;; - This runtime keeps the mode split explicit and exits with sysexits-style 64.
;; main
;;   : (-> (List String) NeverReturns)
;;   | doc m%
;;       `main args ...` dispatches the native build runtime: two arguments link
;;       a final provider executable, one argument writes diagnose artifacts.
;;
;;       # Examples
;;       ```scheme
;;       (main ".run/provider-tmp" ".bin/gerbil-scheme-harness")
;;       ;; => exits with native link status
;;       ```
;;     %
(def (main . args)
  (cond
   ((= (length args) 2)
    (native-link-main (car args) (cadr args)))
   ((= (length args) 1)
    (native-diagnose-main (car args)))
   (else
    (emit-error-line! ["usage: gerbil-native-link <tmp> <final>"])
    (emit-error-line! ["       gerbil-native-diagnose <tmp>"])
    (exit 64))))

(apply main (cdr (command-line)))
