;;; -*- Gerbil -*-
;;; Input: optimizer metadata is hidden behind a dynamic primitive table.
(package: scenario/ssxi-optimizer-metadata-boundary/input)
(export apply-primitive)

(def primitive-table
  (list (cons 'adjust (lambda (value) (+ value 1)))))

;; : (-> SSXI Inline Rule Optimizer Metadata Primitive Dynamic Apply Result)
(def (apply-primitive name value)
  (let (entry (assq name primitive-table))
    (if entry
      (apply (cdr entry) (list value))
      value)))
