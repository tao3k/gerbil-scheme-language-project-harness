;;; -*- Gerbil -*-
(package: sample/orders)
(export decode-order)

(def (decode-order event)
  (let ((created
         (match event
           (['created id] id)
           (else #f)))
        (cancelled
         (match event
           (['cancelled id] id)
           (else #f))))
    (or created cancelled)))
