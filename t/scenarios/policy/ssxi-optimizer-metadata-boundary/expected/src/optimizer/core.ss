;;; -*- Gerbil -*-
;;; Boundary:
;;; - The optimizer-visible primitive call stays lexical and direct.
(package: scenario/ssxi-optimizer-metadata-boundary/expected)
(export adjust-total apply-primitive)

;; adjust-total
;;   : (-> Fixnum Fixnum)
;;   | doc m%
;;       `adjust-total` owns the primitive arithmetic boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (adjust-total 1)
;;       ;; => 2
;;       ```
;;     %
(def (adjust-total value)
  (+ value 1))

;; apply-primitive
;;   : (-> Symbol Fixnum Fixnum)
;;   | doc m%
;;       `apply-primitive` keeps the known primitive target lexical so SSXI and
;;       inline-rule metadata can see the call shape.
;;
;;       # Examples
;;
;;       ```scheme
;;       (apply-primitive 'adjust 1)
;;       ;; => 2
;;       ```
;;     %
(def (apply-primitive name value)
  (case name
    ((adjust) (adjust-total value))
    (else value)))
