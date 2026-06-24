;;; -*- Gerbil -*-
(package: sample/orders)
(export classify-order paid-order?)

;; : (-> Order Symbol)
(def (classify-order order)
  (let ((paid
         (match order
           ((hash ('state "paid")) 'paid)
           (else #f)))
        (failed
         (match order
           ((hash ('state "failed")) 'failed)
           (else #f))))
    (or paid failed 'open)))

;; : (-> Order Boolean)
(def (paid-order? order)
  (eq? (classify-order order) 'paid))
