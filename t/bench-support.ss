;;; -*- Gerbil -*-
;;; Shared bench test helpers.

(import :std/test
        (only-in :commands/bench bench-main)
        :commands/bench-light
        :std/misc/ports
        (only-in :std/sugar cut find ormap)
        (rename-in :gslph/src/cli-launcher (main cli-main)))
(export json-get
        json-key?
        find-performance-finding
        bench-output
        bench-output/status
        cli-bench-output
        contains?)

;; : (-> JsonObject JsonKey JsonValue )
(def (json-get table key)
  ((cut hash-get table <>) key))

;; : (-> JsonObject JsonKey Boolean)
(def (json-key? table key)
  (ormap (lambda (candidate)
           (hash-key? table candidate))
         [key]))

;; : (-> (List JsonObject) String (Maybe JsonObject))
(def (find-performance-finding findings kind)
  (find (lambda (finding)
          (equal? (json-get finding "kind") kind))
        findings))

;; : (-> (List String) String)
(def (bench-output args)
  (bench-output/status args 0))

;; : (-> (List String) Integer String)
(def (bench-output/status args expected-status)
  (bench-output/status*
   (if (bench-full-mode? args) bench-main bench-light-main)
   args
   expected-status))

;; : (-> (List String) Boolean)
(def (bench-full-mode? args)
  (cond
   ((null? args) #f)
   ((and (equal? (car args) "--mode")
         (pair? (cdr args)))
    (equal? (cadr args) "full"))
   (else
    (bench-full-mode? (cdr args)))))

;; : (-> (List String) String)
(def (cli-bench-output args)
  (bench-output/status*
   (lambda (runner-args)
     (apply cli-main (cons "bench" runner-args)))
   args
   0))

;; : (-> (-> (List String) Integer) (List String) Integer String)
(def (bench-output/status* runner args expected-status)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (runner args)))))))
    (check status => expected-status)
    output))

;; : (-> String String Boolean)
(def (contains? output fragment)
  (ormap (lambda (needle)
           (and (string-contains output needle) #t))
         [fragment]))
