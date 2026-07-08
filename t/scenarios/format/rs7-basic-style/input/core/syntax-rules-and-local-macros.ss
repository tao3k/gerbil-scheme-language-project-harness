;;; -*- Gerbil -*-    
;;; Boundary: syntax-rules, let-syntax, and letrec-syntax style.    

(import :gerbil/gambit)    

(export macro-driven-result)    

(define-syntax when-present
  (syntax-rules ()
    ((_ value body ...)
     (let ((tmp value))
       (if tmp
         (begin body ...)
         #!void)))))    

(def (macro-driven-result value)
  (let-syntax ((emit (syntax-rules ()
                       ((_ item)
                        (list 'emitted item)))))
    (letrec-syntax ((wrap (syntax-rules ()
                            ((_ expr)
                             (emit expr)))))
      (when-present value
        (wrap value)))))    

