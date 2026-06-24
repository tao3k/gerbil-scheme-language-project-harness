;;; -*- Gerbil -*-
;;; Events facade.
(package: sample/events)
(export render-event)

;; String <- Event Alist Entry Pair
(def (render-event event)
  (let* ((kind (cdr (assq 'kind event)))
         (payload (cdr (assq 'payload event))))
    (if (equal? kind "error")
      (string-append "error:" payload)
      (string-append kind ":" payload))))
