;;; -*- Gerbil -*-
;;; Repeated inline alist probing hides event shape and repeats scans.
(package: sample/events)
(export event-name
        event-owner
        event-route
        event-priority)

;; event-name
;;   : (-> Alist Value)
;;   | warning repeated inline alist lookup hides the event schema
;;   | doc m%
;;       `event-name` reads one field from a simple event row.
;;     %
(def (event-name event)
  (cdr (assq 'name event)))

;; event-owner
;;   : (-> Alist Value)
(def (event-owner event)
  (cdr (assq 'owner event)))

;; event-route
;;   : (-> Alist Value)
(def (event-route event)
  (cdr (assq 'route event)))

;; event-priority
;;   : (-> Alist Value)
(def (event-priority event)
  (cdr (assq 'priority event)))
