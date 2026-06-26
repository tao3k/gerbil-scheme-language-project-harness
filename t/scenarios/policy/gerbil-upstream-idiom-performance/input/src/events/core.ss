;;; -*- Gerbil -*-
;;; Agent-authored event router with repeated scan and branch scaffolding.
(package: sample/events)
(export event-kind route-event route-events event-labels)

(def (event-kind event)
  (let (entry (assq 'kind event))
    (if entry (cdr entry) 'unknown)))

;; Route <- EventRecord RouteTable Alist Entry Pair
(def (route-event event routes)
  (let* ((kind-entry (assq 'kind event))
         (status-entry (assq 'status event))
         (kind (if kind-entry (cdr kind-entry) 'unknown))
         (status (if status-entry (cdr status-entry) 'new))
         (route-entry (assq kind routes))
         (route (if route-entry (cdr route-entry) 'queue)))
    (cond
     ((and (eq? kind 'archive) (eq? status 'done))
      'archive)
     ((and (eq? kind 'alert) route-entry)
      route)
     ((eq? status 'blocked)
      'review)
     (else route))))

;; (List Route) <- (List EventRecord) RouteTable Map Filter Fold HotPath Index
(def (route-events events routes)
  (let loop ((rest events) (out '()))
    (if (null? rest)
      (reverse out)
      (loop (cdr rest)
            (cons (route-event (car rest) routes) out)))))

;; (List String) <- (List EventRecord) Map Filter Fold
(def (event-labels events)
  (let loop ((rest events) (out '()))
    (if (null? rest)
      (reverse out)
      (let* ((event (car rest))
             (id-entry (assq 'id event))
             (kind-entry (assq 'kind event)))
        (if id-entry
          (loop (cdr rest)
                (cons (string-append (cdr id-entry)
                                     ":"
                                     (symbol->string
                                      (if kind-entry
                                        (cdr kind-entry)
                                        'unknown)))
                      out))
          (loop (cdr rest) out))))))
