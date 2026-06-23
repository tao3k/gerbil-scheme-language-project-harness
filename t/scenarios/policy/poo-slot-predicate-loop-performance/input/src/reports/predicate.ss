;;; -*- Gerbil -*-
(import :clan/poo/object)

(def +report-profile+
  '((score . 0)
    (rows . 8)
    (columns . 5)
    (sections . 3)
    (charts . 2)
    (filters . 4)
    (exports . 2)
    (alerts . 6)
    (retries . 3)
    (priority . 1)))

(def +required-report-slots+
  '(score rows columns sections charts filters exports alerts retries priority))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (score-report profile limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (ready? ((o?/slots +required-report-slots+) profile))
        (loop (+ i 1) (+ total (if ready? 1 0)))))))
