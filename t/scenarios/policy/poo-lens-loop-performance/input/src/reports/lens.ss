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
  (let loop ((i 0) (current profile))
    (if (= i limit)
      current
      (loop (+ i 1) (.call Lens .modify +score-lens+ 1+ current)))))
