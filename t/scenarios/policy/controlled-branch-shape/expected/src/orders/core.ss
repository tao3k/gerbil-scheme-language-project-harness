;;; -*- Gerbil -*-
(package: sample/orders)
(export decode-order)

;; MaybeOrderId <- Symbol Event
(def (event-id-for tag event)
  (match event
    ([kind id]
     (and (eq? kind tag) id))
    (else #f)))

;; MaybeOrderId <- Event
(def (decode-order event)
  (or (event-id-for 'created event)
      (event-id-for 'cancelled event)))
