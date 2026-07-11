(import :gerbil/expander)

(begin-syntax
  (def *composition-parser-loaded?* #f)

  (def (load-composition-parser!)
    (unless *composition-parser-loaded?*
      (load "profile-composition-syntax-plan.ss")
      (set! *composition-parser-loaded?* #t))))

(defsyntax (use-composition stx)
  (load-composition-parser!)
  (eval (syntax->datum stx)))
