;;; -*- Gerbil -*-
(import :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def +integer-function-type+ (Function [Integer] [Integer]))

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (loop (+ i 1) (+ total (if (.@ +integer-function-type+ sexp) 1 0))))))
