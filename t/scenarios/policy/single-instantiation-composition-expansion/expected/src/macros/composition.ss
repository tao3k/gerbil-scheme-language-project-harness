(import (for-syntax
         :poo-flow/module-system/profile-composition-syntax-plan))

(export use-composition)

;; : (-> Syntax Syntax)
;; | doc m%
;;   Reuse one compiled phase helper through the Gerbil module registry.
;;   # Examples
;;   (use-composition production (use-module policy as selected))
;;   | result: one lowered composition expression with no source loading
;;   %
(defsyntax (use-composition stx)
  (let (plan (parse-composition-syntax-plan stx))
    (lower-composition-syntax-plan plan)))
