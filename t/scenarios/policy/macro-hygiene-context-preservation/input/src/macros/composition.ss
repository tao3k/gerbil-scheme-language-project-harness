(import :gerbil/expander)

(begin-syntax
  (def *composition-context* #f)

  (def (composition-grammar-name identifier)
    (symbol->string (syntax->datum identifier))))

(defsyntax (use-composition stx)
  (set! *composition-context* stx)
  (syntax-case stx ()
    ((_ grammar body ...)
     (if (string=? (composition-grammar-name #'grammar) "profile")
       #'(list body ...)
       (error "invalid composition grammar" grammar)))))
