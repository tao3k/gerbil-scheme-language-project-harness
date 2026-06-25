;;; -*- Gerbil -*-
(package: sample/macros)

(def *macro-phase* 0)
(def *macro-context* #f)

(def (remember-macro-context! stx phase)
  (set! *macro-context* stx)
  (set! *macro-phase* phase)
  stx)

(defsyntax (with-order-field stx)
  (let ((form (syntax->datum stx)))
    (if (and (pair? form) (pair? (cdr form)) (pair? (cddr form)))
      (begin
        (remember-macro-context! stx 0)
        #`(let ((current-order #,(cadr form)))
            #,(caddr form)))
      (error "bad with-order-field syntax"))))
