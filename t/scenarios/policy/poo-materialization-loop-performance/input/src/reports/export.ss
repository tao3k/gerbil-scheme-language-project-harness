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
  (let loop ((i 0) (total 0))
    (if (= i limit)
      total
      (let ((alist-snapshot (.alist/sort profile))
            (slot-list (.all-slots profile))
            (sorted-slot-list (.all-slots/sort profile))
            (hash-snapshot (hash<-object profile))
            (forced-profile (force-object profile)))
        (loop (+ i 1)
              (+ total
                 (length alist-snapshot)
                 (length slot-list)
                 (length sorted-slot-list)
                 (hash-ref hash-snapshot 'score)
                 (.ref forced-profile 'score)))))))
