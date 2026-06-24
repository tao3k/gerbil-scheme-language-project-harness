;;; -*- Gerbil -*-
;;; Boundary:
;;; - Event rendering keeps alist destructuring behind one selector boundary
;;;   instead of repeating temporary access scaffolding.
(package: sample/events)
(export render-event)

;; event-field
;;   : (-> Field Event Value)
;;   | doc m%
;;       `event-field` owns event alist access for render helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-field 'kind event)
;;       ;; => "error"
;;       ```
;;     %
(def (event-field key event)
  (cdr (assq key event)))

;; render-event
;;   : (-> Event String)
;;   | doc m%
;;       `render-event` names the event rendering boundary and delegates field
;;       access to `event-field`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (render-event event)
;;       ;; => "error:missing"
;;       ```
;;     %
(def (render-event event)
  (let ((kind (event-field 'kind event))
        (payload (event-field 'payload event)))
    (if (equal? kind "error")
      (string-append "error:" payload)
      (string-append kind ":" payload))))
