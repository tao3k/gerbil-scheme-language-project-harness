;;; -*- Gerbil -*-
(package: sample/orders)
(import :clan/poo/brace)
(export base-order order order-view order-id)

(def base-order
  {id: 0
   total: 0
   meta: {currency: 'USD}})

(def order
  {(:: @ base-order)
   id: ? 1
   total: => 1+
   meta: =>.+ {source: 'agent}
   status: ? 'draft})

(def order-view
  (.mix order))

(def (order-id source)
  (.ref source 'id))
