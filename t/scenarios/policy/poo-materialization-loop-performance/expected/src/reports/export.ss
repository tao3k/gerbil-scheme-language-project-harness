;;; -*- Gerbil -*-
(import :clan/poo/object)

(def +report-profile+
  '((id . "orders")
    (status . "hot")
    (score . 10)
    (rows . 8)
    (columns . 5)
    (sections . 3)
    (charts . 2)
    (filters . 4)
    (exports . 2)
    (alerts . 6)
    (retries . 3)
    (priority . "high")))

(def (build-report-profile)
  (object<-alist +report-profile+))

(def (export-score profile limit)
  (let (snapshot (.alist/sort profile))
    (let loop ((i 0) (total 0))
      (if (= i limit)
        total
        (loop (+ i 1) (+ total (length snapshot)))))))
