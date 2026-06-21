;;; -*- Gerbil -*-
(package: sample/orders)
(export order->json order->string order->bytes)

;; order->json
;;   : (-> Order Json)
;;   | doc m%
;;       `order->json order` builds a raw json table for an order.
;;     %
(def (order->json order)
  (hash (id (.ref order 'id))
        (total (.ref order 'total))))

;; order->string
;;   : (-> Order String)
;;   | doc m%
;;       `order->string order` renders the raw json table.
;;     %
(def (order->string order)
  (json-object->string (order->json order)))

;; order->bytes
;;   : (-> Order Bytes)
;;   | doc m%
;;       `order->bytes order` encodes the raw string representation.
;;     %
(def (order->bytes order)
  (string->utf8 (order->string order)))
