;;; -*- Gerbil -*-
(package: sample/orders)
(export decode-order)

;; : (-> Symbol Event MaybeOrderId )
(def (event-id-for tag event)
  (match event
    ([kind id]
     (and (eq? kind tag) id))
    (else #f)))

;; : (-> Event MaybeOrderId )
(def (decode-order event)
  (or (event-id-for 'created event)
      (event-id-for 'cancelled event)))
