;;; -*- Gerbil -*-
;;; Input: one macro owner mixes phase/context and runtime helper behavior.
(package: scenario/phase-aware-macro-boundary/input)
(export define-phase-reader read-total)

(def phase-context (make-hash-table-eq))

;; : (-> Phase Macro Context Transformer Expansion Runtime Helper)
(def (phase-macro-runtime-transformer! name selector)
  (hash-put! phase-context name selector)
  (lambda (row)
    ((hash-get phase-context name) row)))

(defrules define-phase-reader ()
  ((_ id key)
   (def (id row)
     ((phase-macro-runtime-transformer!
       'key
       (lambda (item) (cdr (assq 'key item))))
      row))))

(define-phase-reader read-total total)
