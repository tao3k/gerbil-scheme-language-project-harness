;;; -*- Gerbil -*-
(import :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def +report-profile+
  '((id . "orders")
    (status . "hot")
    (score . 0)
    (rows . 8)
    (columns . 5)
    (sections . 3)
    (charts . 2)
    (filters . 4)
    (exports . 2)
    (alerts . 6)
    (retries . 3)
    (priority . "high")))

(def +score-lens+ (slot-lens 'score))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (score-report profile limit)
  (let (score
        (let loop ((i 0) (score (.ref profile 'score)))
          (if (= i limit)
            score
            (loop (+ i 1) (1+ score)))))
    (.cc profile 'score score)))
