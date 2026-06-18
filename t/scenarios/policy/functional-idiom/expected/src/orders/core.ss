;;; -*- Gerbil -*-
(package: sample/orders)
(export total)

;; : (-> (List Number) Number )
(def (total xs)
  (for/fold ((acc 0)) ((x xs))
    (+ acc x)))
