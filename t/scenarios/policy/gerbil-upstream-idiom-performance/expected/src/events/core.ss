;;; -*- Gerbil -*-
;;; Boundary:
;;; - Event routing owns the Gerbil upstream idiom performance scenario.
;;; - Keep match/with shape dispatch, eq hash index setup, and cut plumbing
;;;   visible to parser evidence.
(package: sample/events)
(import (only-in :std/sugar cut filter-map))
(export event-kind route-index route-event route-events event-labels)

;; event-kind
;;   : (-> EventRecord Symbol)
;;   | type EventRecord = (List Entry)
;;   | type Entry = (Pair Symbol Value)
;;   | doc m%
;;       `event-kind event` keeps the event kind projection local.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-kind '((kind . archive)))
;;       ;; => archive
;;       ```
;;     %
(def (event-kind event)
  (with (((('kind . kind) . _) event))
    kind))

;; event-route-key
;;   : (-> EventRecord RouteKey)
;;   | type RouteKey = (List Symbol)
;;   | doc m%
;;       `event-route-key event` names the match input shape.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-route-key '((kind . archive) (status . done)))
;;       ;; => (archive done)
;;       ```
;;     %
(def (event-route-key event)
  (with (((('kind . kind) ('status . status) . _) event))
    [kind status]))

;; index-route!
;;   : (-> RouteIndex Route Void)
;;   | type RouteIndex = HashTable
;;   | type Route = (Pair Symbol Symbol)
;;   | doc m%
;;       `index-route! index route` isolates the mutable eq-hash update.
;;
;;       # Examples
;;
;;       ```scheme
;;       (index-route! index '(alert . review))
;;       ;; => #!void
;;       ```
;;     %
(def (index-route! index route)
  (hash-put! index (car route) (cdr route)))

;; route-index
;;   : (-> (List Route) RouteIndex)
;;   | type RouteIndex = HashTable
;;   | doc m%
;;       `route-index routes` precomputes repeated symbolic route lookup.
;;
;;       # Examples
;;
;;       ```scheme
;;       (hash-get (route-index '((alert . review))) 'alert)
;;       ;; => review
;;       ```
;;     %
(def (route-index routes)
  (let (index (make-hash-table-eq))
    (for-each (cut index-route! index <>) routes)
    index))

;; route-event
;;   : (-> RouteIndex EventRecord Symbol)
;;   | type RouteIndex = HashTable
;;   | type EventRecord = (List Entry)
;;   | doc m%
;;       `route-event route-index event` routes one event through match-shaped
;;       data dispatch and the precomputed symbolic index.
;;
;;       # Examples
;;
;;       ```scheme
;;       (route-event index event)
;;       ;; => archive
;;       ```
;;     %
(def (route-event route-index event)
  (match (event-route-key event)
    ((archive done)
     (if (eq? archive 'archive)
       'archive
       (hash-get route-index archive 'queue)))
    ((alert _)
     (hash-get route-index alert 'queue))
    ((_ blocked)
     (if (eq? blocked 'blocked)
       'review
       (hash-get route-index (event-kind event) 'queue)))
    (_ (hash-get route-index (event-kind event) 'queue))))

;; route-events
;;   : (-> (List EventRecord) (List Route) (List Symbol))
;;   | doc m%
;;       `route-events events routes` builds the route index once and maps the
;;       specialized router with `cut`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (route-events events routes)
;;       ;; => (archive review)
;;       ```
;;     %
(def (route-events events routes)
  (let (index (route-index routes))
    (map (cut route-event index <>) events)))

;; event-label
;;   : (-> EventRecord (Maybe String))
;;   | doc m%
;;       `event-label event` selects labelable events and projects one line.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-label '((id . "A-1") (kind . archive)))
;;       ;; => "A-1:archive"
;;       ```
;;     %
(def (event-label event)
  (with (((('id . id) ('kind . kind) . _) event))
    (string-append id ":" (symbol->string kind))))

;; event-labels
;;   : (-> (List EventRecord) (List String))
;;   | doc m%
;;       `event-labels events` keeps selection and projection in filter-map.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-labels events)
;;       ;; => ("A-1:archive")
;;       ```
;;     %
(def (event-labels events)
  (filter-map event-label events))
