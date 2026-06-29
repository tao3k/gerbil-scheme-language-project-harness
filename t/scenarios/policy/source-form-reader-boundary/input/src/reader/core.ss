;;; -*- Gerbil -*-
;;; Source reader facade with mixed reader/projection loop.
(package: sample/source-reader)
(export source-forms local-def-symbols)

;; : (-> Form (Maybe Symbol))
(def (def-symbol form)
  (and (pair? form)
       (eq? (car form) 'def)
       (pair? (cdr form))
       (let (head (cadr form))
         (cond
          ((symbol? head) head)
          ((and (pair? head) (symbol? (car head))) (car head))
          (else #f)))))

;; : (-> Path (List Form))
(def (source-forms file)
  (call-with-input-file file
    (lambda (port)
      (let loop ((forms []))
        (let (form (read port))
          (if (eof-object? form)
            (reverse forms)
            (loop (cons form forms))))))))

;; : (-> Path (List Symbol))
(def (local-def-symbols file)
  (call-with-input-file file
    (lambda (port)
      (let loop ((symbols []))
        (let (form (read port))
          (if (eof-object? form)
            symbols
            (let (symbol (def-symbol form))
              (loop (if symbol (cons symbol symbols) symbols)))))))))
