;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/mop)
(export Order. make-order valid-order?)

;; valid-order?
;;   : (-> Order Boolean)
;;   | doc m%
;;       `valid-order? order` keeps validation attached to the POO descriptor.
;;     %
(def (valid-order? order)
  (.@ order 'id))

;; make-order
;;   : (-> Number Number String Order)
;;   | doc m%
;;       `make-order id total currency` builds an order through descriptor slots.
;;     %
(def (make-order id total currency)
  (.new Order. id total currency))

(define-type (Order. @ Class.)
  .slot.id: (Slot 'id check: number? default: 0)
  .slot.total: (Slot 'total check: number? default: 0)
  .slot.currency: (Slot 'currency check: string? default: "USD")
  .validate: valid-order?
  .new: make-order)
