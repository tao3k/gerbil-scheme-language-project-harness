;;; -*- Gerbil -*-
(import :clan/poo/number
        :clan/poo/object)

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (range (IntegerRange min: 0 max: 255))
        (loop (+ i 1) (+ total (if (.@ range sexp) 1 0)))))))
