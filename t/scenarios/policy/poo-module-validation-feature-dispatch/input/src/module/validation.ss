;;; -*- Gerbil -*-
;;; Input: validation dispatch is encoded as a string branch and full scan.
(package: scenario/poo-module-validation-feature-dispatch/input)
(export validation-feature-enabled?)

(def (validation-feature-enabled? feature enabled)
  (cond
   ((equal? feature "object-validation")
    (member 'object-validation enabled))
   ((equal? feature "field-origin")
    (member 'field-origin enabled))
   ((equal? feature "inheritance-chain")
    (member 'inheritance-chain enabled))
   (else #f)))
