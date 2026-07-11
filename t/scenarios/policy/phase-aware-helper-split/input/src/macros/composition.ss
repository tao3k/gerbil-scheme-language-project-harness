(import :poo-flow/runtime/profile-builders)

(export use-composition
        (import: :poo-flow/runtime/profile-builders))

(begin-syntax
  (def *composition-plan* '())

  (def (parse-composition stx)
    (set! *composition-plan* (syntax->datum stx))
    *composition-plan*))

(defsyntax (use-composition stx)
  (parse-composition stx)
  #'(poo-flow-runtime-profile-builder))
