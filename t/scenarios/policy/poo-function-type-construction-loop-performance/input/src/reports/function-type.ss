;;; -*- Gerbil -*-
(import :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (type (Function [Integer] [Integer]))
        (loop (+ i 1) (+ total (if (.@ type sexp) 1 0)))))))
