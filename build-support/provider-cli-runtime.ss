
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

(def (read-provider-config path)
  (call-with-input-file path read))

(def (config-ref config key)
  (let (entry (assoc key config))
    (and entry (cdr entry))))

(def (required-config config key)
  (or (config-ref config key)
      (error "missing provider wrapper config" key)))

(def (argument-ref args offset default)
  (cond
   ((null? args) default)
   ((zero? offset) (car args))
   (else (argument-ref (cdr args) (- offset 1) default))))

(def (drop-arguments args count)
  (if (or (zero? count) (null? args))
    args
    (drop-arguments (cdr args) (- count 1))))

(def (argument-present? needle args)
  (and (not (null? args))
       (or (equal? needle (car args))
           (argument-present? needle (cdr args)))))

(def (gerbil-bin)
  (getenv "GERBIL" "gxi"))

(def (configure-provider-env! config)
  (let (harness-root (required-config config 'harness-root))
    (unless (getenv "GERBIL_PATH" #f)
      (setenv "GERBIL_PATH"
              (string-append harness-root "/.gerbil")))
    (unless (getenv "GERBIL_LOADPATH" #f)
      (setenv "GERBIL_LOADPATH"
              (string-append harness-root "/src")))))

(def (run-gerbil-script! script args)
  (run-command! (append (list (gerbil-bin) script) args)))

(def (poo-extension-request? args)
  (and (not (argument-present? "--json" args))
       (equal? (argument-ref args 0 #f) "search")
       (equal? (argument-ref args 1 #f) "extension")
       (let (topic (argument-ref args 2 #f))
         (or (equal? topic "poo")
             (equal? topic "gerbil-poo")))))

(def (route-provider-cli! config args)
  (configure-provider-env! config)
  (cond
   ((poo-extension-request? args)
    (let ((extension-args (drop-arguments args 2))
          (fast-extension (required-config config 'fast-extension))
          (extension-script (required-config config 'extension-script)))
      (if (file-exists? fast-extension)
        (run-command! (append (list fast-extension) extension-args))
        (run-gerbil-script! extension-script extension-args))))
   ((equal? (argument-ref args 0 #f) "search")
    (run-gerbil-script! (required-config config 'search-script)
                        (cdr args)))
   (else
    (run-gerbil-script! (required-config config 'harness-script)
                        args))))

(def (provider-cli-main config-path args)
  (route-provider-cli! (read-provider-config config-path) args))
