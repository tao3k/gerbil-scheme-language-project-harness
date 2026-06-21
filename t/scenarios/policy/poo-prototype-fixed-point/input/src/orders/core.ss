;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/brace)
(export make-order order-id)

(def (make-order source)
  (let ((id (.ref source 'id))
        (total (.ref source 'total))
        (currency (.ref source 'currency)))
    (hash (id id) (total total) (currency currency))))

(def (order-id source)
  (.ref source 'id))
