;;; -*- Gerbil -*-
(import :clan/poo/object)

(def +report-profile+
  '((score . 1)
    (rows . 8)
    (columns . 5)
    (sections . 3)
    (charts . 2)
    (filters . 4)
    (exports . 2)
    (alerts . 6)
    (retries . 3)
    (priority . 7)))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (score-report profile limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (sum 0)
        (.for-each! profile
          (lambda (_ value)
            (set! sum (+ sum value))))
        (loop (+ i 1) (+ total sum))))))
