(import :std/sugar)

(export main parse-args render-usage run-command)

(def (render-usage)
  (string-append
   "usage: tool <command> [--workspace PATH] [--json]\n"
   "commands:\n"
   "  check      run policy checks\n"
   "  format     format Scheme files\n"))

(def (print-error message)
  (display "error: ")
  (display message)
  (newline)
  (display (render-usage))
  (newline)
  2)

(def (parse-args args)
  (let loop ((rest args) (command #f) (workspace ".") (json? #f))
    (cond
     ((null? rest)
      (if command
        (list command workspace json?)
        (print-error "missing command")))
     ((string=? (car rest) "--json")
      (loop (cdr rest) command workspace #t))
     ((string=? (car rest) "--workspace")
      (if (and (pair? (cdr rest)) (string? (cadr rest)))
        (loop (cddr rest) command (cadr rest) json?)
        (print-error "missing workspace path")))
     ((or (string=? (car rest) "check")
          (string=? (car rest) "format"))
      (if command
        (print-error "command already selected")
        (loop (cdr rest) (car rest) workspace json?)))
     (else
      (print-error (string-append "unknown argument: " (car rest)))))))

(def (run-command parsed)
  (cond
   ((not (pair? parsed)) parsed)
   ((string=? (car parsed) "check") 0)
   ((string=? (car parsed) "format") 0)
   (else (print-error "unknown command"))))

(def (main . args)
  (run-command (parse-args args)))
