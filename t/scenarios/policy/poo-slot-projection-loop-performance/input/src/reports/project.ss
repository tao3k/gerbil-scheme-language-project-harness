;;; -*- Gerbil -*-
(import :clan/poo/object)

(def +report-profile+
  '((id . "orders")
    (status . "hot")
    (score . 1)
    (rows . 8)
    (columns . 5)
    (sections . 3)
    (charts . 2)
    (filters . 4)
    (exports . 2)
    (alerts . 6)
    (retries . 3)
    (priority . "high")))

(def +report-slots+
  '(score rows columns sections charts filters exports alerts retries))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (sum-values values)
  (let loop ((values values) (total 0))
    (if (null? values)
      total
      (loop (cdr values) (+ total (car values))))))

(def (score-report profile limit)
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let (values ((.refs/slots +report-slots+) profile))
        (loop (+ i 1) (+ total (sum-values values)))))))
