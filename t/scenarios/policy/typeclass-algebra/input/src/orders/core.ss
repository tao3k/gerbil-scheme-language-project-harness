;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/object)
(export order-id)

(def (order-id value) value)

(define-type (OrderFunctor. @ Functor.)
  .map: map
  .tap: tap
  .ap: ap)
