;;; -*- Gerbil -*-
(import :clan/poo/number
        :clan/poo/object)

(def +byte-range-type+ (IntegerRange min: 0 max: 255))

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (loop (+ i 1) (+ total (if (.@ +byte-range-type+ sexp) 1 0))))))
