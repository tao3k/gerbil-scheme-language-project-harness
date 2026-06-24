;;; -*- Gerbil -*-
(import :clan/poo/fq
        :clan/poo/object)

(def (score-report limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (field (F_q 2 8 27))
        (loop (+ i 1) (+ total (if (.@ field .q) 1 0)))))))
