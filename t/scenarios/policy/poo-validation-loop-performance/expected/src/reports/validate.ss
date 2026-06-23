;;; -*- Gerbil -*-
(import :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def +report-profile+
  '((s0 . 0)
    (s1 . 1)
    (s2 . 2)
    (s3 . 3)
    (s4 . 4)
    (s5 . 5)
    (s6 . 6)
    (s7 . 7)
    (s8 . 8)
    (s9 . 9)
    (s10 . 10)
    (s11 . 11)))

(def +report-type+ (MonomorphicObject Integer))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (score-report profile limit)
  (let (validated (validate +report-type+ profile))
    (let loop ((i 0) (total 0))
      (if (= i limit)
        total
        (loop (+ i 1) (+ total (.ref validated 's0)))))))
