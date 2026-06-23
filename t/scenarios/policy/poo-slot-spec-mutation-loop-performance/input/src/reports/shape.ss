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

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (score-report profile limit)
  (let loop ((i 0))
    (if (= i limit)
      (.ref profile 'score)
      (begin
        (.def! profile score (:: self) i)
        (loop (+ i 1))))))
