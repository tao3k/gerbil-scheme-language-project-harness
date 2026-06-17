
(import :gerbil/gambit
        :std/misc/ports
        :std/misc/process)

(export main)

(def +native-artifact-suffixes+
  ["" "__exe.scm" "__exe.c" "__exe_.c" "__exe.o" "__exe_.o"
   "__exe__.c" "__exe__.o"])

(def (status->exit-code status)
  (if (zero? status)
    0
    (let (code (quotient status 256))
      (if (zero? code) 1 code))))

(def (native-timeout-seconds)
  (string->number (getenv "ASP_NATIVE_TIMEOUT_SECONDS" "120")))

(def (native-debug?)
  (getenv "ASP_NATIVE_DEBUG" #f))

(def (native-keep-artifacts?)
  (getenv "ASP_NATIVE_KEEP_ARTIFACTS" #f))

(def (native-artifacts tmp)
  (map (cut string-append tmp <>) +native-artifact-suffixes+))

(def (remove-files! paths)
  (when (pair? paths)
    (run-process (cons "rm" (cons "-f" paths))
                 stdin-redirection: #f
                 stdout-redirection: #f
                 stderr-redirection: #f
                 check-status: #f)))

(def (send-signal! signal pid)
  (run-process ["kill" signal pid]
               stdin-redirection: #f
               stdout-redirection: #t
               stderr-redirection: #t
               coprocess: process-status
               check-status: #f))

(def (write-log! log output)
  (when output
    (call-with-output-file log
      (cut write-string output <>))))

(def (log-has-content? output)
  (and output (< 0 (string-length output))))

(def (show-debug-output output)
  (when (and (native-debug?) (log-has-content? output))
    (display output (current-error-port))))

;;; Process boundary: native compile is still an external gxc command, but the
;;; timeout, status, and cleanup policy are now expressed in Gerbil over
;;; open-process/process-status instead of a shell script.
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

(def (native-compile-command tmp)
  (if (native-debug?)
    ["gxc" "-V" "-exe" "-o" tmp "src/cli.ss"]
    ["gxc" "-exe" "-o" tmp "src/cli.ss"]))

(def (native-diagnose-command tmp)
  ["gxc" "-S" "-V" "-exe" "-o" tmp "src/cli.ss"])

(def (cleanup-native-link-success! tmp log)
  (remove-files! (native-artifacts tmp))
  (remove-files! [log]))

(def (cleanup-native-link-failure! tmp log output)
  (if (native-keep-artifacts?)
    (begin
      (display "native compile artifacts prefix: " (current-error-port))
      (display tmp (current-error-port))
      (newline (current-error-port)))
    (remove-files! (native-artifacts tmp)))
  (if (log-has-content? output)
    (begin
      (write-log! log output)
      (display "native compile log: " (current-error-port))
      (display log (current-error-port))
      (newline (current-error-port)))
    (remove-files! [log])))

(def (native-link-main tmp final)
  (let* ((log (string-append tmp ".log"))
         (result (run-native-command (native-compile-command tmp)))
         (status (list-ref result 0))
         (output (list-ref result 1))
         (reason (list-ref result 2)))
    (cond
     ((equal? reason 'timeout)
      (display "native compile timed out after " (current-error-port))
      (display (native-timeout-seconds) (current-error-port))
      (display "s; leaving existing provider executable untouched"
               (current-error-port))
      (newline (current-error-port))
      (show-debug-output output)
      (cleanup-native-link-failure! tmp log output)
      (exit 124))
     ((not (zero? status))
      (show-debug-output output)
      (cleanup-native-link-failure! tmp log output)
      (exit (status->exit-code status)))
     ((not (file-exists? tmp))
      (display "native compile did not produce executable: "
               (current-error-port))
      (display tmp (current-error-port))
      (newline (current-error-port))
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

(def (native-diagnose-main tmp)
  (let* ((log (string-append tmp ".log"))
         (result (run-native-command (native-diagnose-command tmp)))
         (status (list-ref result 0))
         (output (list-ref result 1))
         (reason (list-ref result 2)))
    (write-log! log output)
    (display "native diagnose log: " (current-error-port))
    (display log (current-error-port))
    (newline (current-error-port))
    (display "native diagnose artifacts prefix: " (current-error-port))
    (display tmp (current-error-port))
    (newline (current-error-port))
    (cond
     ((equal? reason 'timeout)
      (display "native diagnose timed out after " (current-error-port))
      (display (native-timeout-seconds) (current-error-port))
      (display "s before Gambit link" (current-error-port))
      (newline (current-error-port))
      (show-debug-output output)
      (exit 124))
     ((not (zero? status))
      (show-debug-output output)
      (exit (status->exit-code status)))
     (else
      (display "native diagnose gerbil-front-end=ok gambit-link=skipped"
               (current-error-port))
      (newline (current-error-port))
      (exit 0)))))

(def (main . args)
  (cond
   ((= (length args) 2)
    (native-link-main (car args) (cadr args)))
   ((= (length args) 1)
    (native-diagnose-main (car args)))
   (else
    (display "usage: gerbil-native-link <tmp> <final>\n       gerbil-native-diagnose <tmp>\n"
             (current-error-port))
    (exit 64))))

(apply main (cdr (command-line)))
