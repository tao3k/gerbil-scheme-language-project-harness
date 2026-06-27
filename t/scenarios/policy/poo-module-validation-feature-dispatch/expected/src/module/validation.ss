;;; -*- Gerbil -*-
;;; Expected: use symbol dispatch and provider-owned feature predicates.
(package: scenario/poo-module-validation-feature-dispatch/expected)
(export validation-feature-enabled?)

(def (validation-feature-enabled? feature enabled)
  (case feature
    ((object-validation field-origin inheritance-chain)
     (memq feature enabled))
    (else #f)))
