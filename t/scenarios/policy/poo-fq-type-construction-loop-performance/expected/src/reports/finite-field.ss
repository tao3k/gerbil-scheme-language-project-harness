;;; -*- Gerbil -*-
(import :clan/poo/fq
        :clan/poo/object)

(def +aes-field-type+ (F_q 2 8 27))

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (loop (+ i 1) (+ total (if (.@ +aes-field-type+ .q) 1 0))))))
