;;; -*- Gerbil -*-
;;; Boundary:
;;; - The macro owns syntax expansion only.
;;; - Runtime field access stays in ordinary helpers.
(package: scenario/phase-aware-macro-boundary/expected)
(export define-phase-reader read-total field-value make-field-reader)

;; field-value
;;   : (-> Symbol Row Value)
;;   | doc m%
;;       `field-value` owns runtime field lookup for generated readers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (field-value 'total row)
;;       ;; => total
;;       ```
;;     %
(def (field-value key row)
  (cdr (assq key row)))

;; make-field-reader
;;   : (-> Symbol (-> Row Value))
;;   | doc m%
;;       `make-field-reader` creates the ordinary runtime helper used by the
;;       syntax wrapper.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((make-field-reader 'total) row)
;;       ;; => total
;;       ```
;;     %
(def (make-field-reader key)
  (lambda (row)
    (field-value key row)))

;; define-phase-reader
;;   : (-> Macro Transformer)
;;   | doc m%
;;       `define-phase-reader` is a thin hygienic syntax wrapper over the
;;       runtime reader helper.
;;
;;       # Examples
;;
;;       ```scheme
;;       (define-phase-reader read-total total)
;;       ;; => reader definition
;;       ```
;;     %
(defrules define-phase-reader ()
  ((_ id key)
   (def (id row)
     ((make-field-reader 'key) row))))

(define-phase-reader read-total total)
