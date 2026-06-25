;;; -*- Gerbil -*-
;;; Boundary:
;;; - Event routing keeps record destructuring behind one match boundary.
;;; - Command/status routing uses core `match`, mirroring gerbil:// match
;;;   dispatch style.
(package: sample/events)
(export summarize-agent-event route-agent-event event-archive-key)

;; event-values
;;   : (-> EventRecord (Values Id Command Status Priority Owner PayloadSize))
;;   | type EventRecord = (List Entry)
;;   | type Entry = (Pair Symbol Value)
;;   | doc m%
;;       `event-values event` is the single event-record destructuring
;;       boundary for downstream routing helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (call-with-values (lambda () (event-values event)) list)
;;       ;; => ("T-1" "archive" "done" "normal" "codex" 12)
;;       ```
;;     %
(def (event-values event)
  (with (((('id . id)
           ('command . command)
           ('status . status)
           ('priority . priority)
           ('owner . owner)
           ('payload-size . payload-size)
           . _)
          event))
    (values id command status priority owner payload-size)))

;; event-route-kind
;;   : (-> RouteKey Symbol)
;;   | type RouteKey = (List Value)
;;   | doc m%
;;       `event-route-kind` names the command/status shape dispatch as a
;;       local match boundary instead of repeating conditional probes.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-route-kind ["archive" "done" "normal" "codex"])
;;       ;; => archive
;;       ```
;;     %
(def (event-route-kind route)
  (match route
    (("archive" "done" _ _) 'archive)
    ((_ _ "high" _) 'review)
    ((_ _ _ "codex") 'session)
    (_ 'queue)))

;; summarize-agent-event
;;   : (-> EventRecord Summary)
;;   | type EventRecord = (List Entry)
;;   | type Entry = (Pair Symbol Value)
;;   | doc m%
;;       `summarize-agent-event event` projects one destructured event into the
;;       durable task summary shape.
;;
;;       # Examples
;;
;;       ```scheme
;;       (summarize-agent-event event)
;;       ;; => (archive "T-1" "codex" 12)
;;       ```
;;     %
(def (summarize-agent-event event)
  (call-with-values
    (lambda () (event-values event))
    (lambda (id command status priority owner payload-size)
      (match (event-route-kind [command status priority owner])
        ('archive (list 'archive id owner payload-size))
        ('review (list 'attention id owner status))
        ('session (list 'session id command status))
        (_ (list 'observe id command status))))))

;; route-agent-event
;;   : (-> EventRecord Symbol)
;;   | type EventRecord = (List Entry)
;;   | type Entry = (Pair Symbol Value)
;;   | doc m%
;;       `route-agent-event event` reuses the destructuring boundary and keeps
;;       route selection expression-level.
;;
;;       # Examples
;;
;;       ```scheme
;;       (route-agent-event event)
;;       ;; => archive
;;       ```
;;     %
(def (route-agent-event event)
  (call-with-values
    (lambda () (event-values event))
    (lambda (_ command status priority owner _)
      (event-route-kind [command status priority owner]))))

;; event-archive-key
;;   : (-> EventRecord String)
;;   | type EventRecord = (List Entry)
;;   | type Entry = (Pair Symbol Value)
;;   | doc m%
;;       `event-archive-key event` composes the stable archive path from the
;;       shared event-record projection.
;;
;;       # Examples
;;
;;       ```scheme
;;       (event-archive-key event)
;;       ;; => "codex/T-1/done"
;;       ```
;;     %
(def (event-archive-key event)
  (call-with-values
    (lambda () (event-values event))
    (lambda (id _ status _ owner _)
      (string-append owner "/" id "/" status))))
