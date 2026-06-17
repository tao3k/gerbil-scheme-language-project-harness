;;; -*- Gerbil -*-
(package: sample/orders)
(export total)

;; Number <- (List Number)
(def (total xs)
  (for/fold ((acc 0)) ((x xs))
    (+ acc x)))
