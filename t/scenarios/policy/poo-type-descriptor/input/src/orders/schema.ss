;;; -*- Gerbil -*-
(package: sample/orders)
(export make-order valid-order?)

;; valid-order?
;;   : (-> Hash Boolean)
;;   | doc m%
;;       `valid-order? order` checks the raw order fields before construction.
;;     %
(def (valid-order? order)
  (and (hash-key? order 'id)
       (hash-key? order 'total)
       (number? (hash-get order 'total))
       (hash-key? order 'currency)
       (string? (hash-get order 'currency))))

;; make-order
;;   : (-> Number Number String Hash)
;;   | doc m%
;;       `make-order id total currency` builds the raw order map.
;;     %
(def (make-order id total currency)
  (hash (id id) (total total) (currency currency)))
