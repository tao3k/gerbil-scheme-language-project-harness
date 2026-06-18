;;; -*- Gerbil -*-
;;; Boundary:
;;; - POO typeclass owners keep algebra declarations visible to parser facts.
(package: sample/orders)
(import :clan/poo/object)
(export order-id)

;;; Boundary:
;;; - order-id is the identity helper used by the local functor adapter.
;; order-id
;;   : (-> Number Number)
;;   | doc m%
;;       `order-id value` returns `value` unchanged.
;;
;;       # Examples
;;
;;       ```scheme
;;       (order-id 12)
;;       ;; => 12
;;       ```
;;     %
(def (order-id value) value)

(define-type (OrderFunctor. @ Functor.)
  .map: map
  .tap: tap
  .ap: ap)
