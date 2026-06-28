;;; -*- Gerbil -*-
(package: sample/match)
(export define-shape-match)

(def *shape-pattern-table* (make-hash-table-eq))

;; define-shape-match
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `define-shape-match` is a generated match macro that mixes Match
;;       Pattern parsing, Macro Syntax expansion, syntax-local lookup,
;;       Struct and Class field Accessor extraction, Applicative Apply
;;       destructuring, Parser state, and Source Error reporting in one owner.
;;     %
(defsyntax (define-shape-match stx)
  (let ((form (syntax->datum stx)))
    (if (and (pair? form) (pair? (cdr form)))
      (let ((name (cadr form)))
        (hash-put! *shape-pattern-table* name form)
        #`(lambda (value)
            (cond
             ((and (pair? value) (eq? (car value) '#,name))
              (cdr value))
             ((vector? value)
              (vector->list value))
             (else
              (error "bad generated shape match" value)))))
      (error "bad define-shape-match syntax"))))
