(import :poo-flow/runtime/profile-builders
        (for-syntax :poo-flow/module-system/profile-composition-syntax-plan))

(export use-composition)

;; : (-> Syntax Syntax)
;; | doc m%
;;   Parse once through the phase-owned helper and lower ordinary runtime code.
;;   # Examples
;;   (use-composition production (use-module policy as selected))
;;   | result: a POO-native composition expression
;;   %
(defsyntax (use-composition stx)
  (let (plan (parse-composition-syntax-plan stx))
    (lower-composition-syntax-plan plan)))
