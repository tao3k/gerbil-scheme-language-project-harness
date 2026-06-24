;;; -*- Gerbil -*-
(import :clan/poo/number
        :clan/poo/object)

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (ring (Z/ 257))
        (loop (+ i 1) (+ total (if (.@ ring .most-positive) 1 0)))))))
