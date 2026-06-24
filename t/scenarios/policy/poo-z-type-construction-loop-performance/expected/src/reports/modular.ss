;;; -*- Gerbil -*-
(import :clan/poo/number
        :clan/poo/object)

(def +modular-ring-type+ (Z/ 257))

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (loop (+ i 1) (+ total (if (.@ +modular-ring-type+ .most-positive) 1 0))))))
