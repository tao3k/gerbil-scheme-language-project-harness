(import :gerbil/expander)

(begin-syntax
  ;; : (-> Syntax Syntax Boolean)
  (def (composition-grammar-literal? identifier literal)
    (and (identifier? identifier)
         (free-identifier=? identifier literal))))

;; : (-> Syntax Syntax)
;; | doc m%
;;   Expand a composition form while preserving lexical and source context.
;;   # Examples
;;   (use-composition profile value)
;;   | result: a source-located list expression
;;   %
(defsyntax (use-composition stx)
  (syntax-case stx (profile)
    ((_ profile body ...)
     (syntax/loc stx (list body ...)))
    (_
     (raise-syntax-error
      #f
      "composition-invalid-grammar: expected profile"
      stx))))
