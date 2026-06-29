;;; -*- Gerbil -*-
(import :clan/poo/debug
        :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def +dashboard-profile+
  (.o id: "orders"
      score: 0
      last: 0
      rows: 12
      alerts: 3
      priority: 2))

(def +event-slots+ '(quantity risk))
(def +dashboard-slots+ '(score last rows alerts priority))
(def +event-type+ (MonomorphicObject Integer))

(def (build-dashboard-profile)
  +dashboard-profile+)

(def (dashboard-default-overrides defaults)
  (let loop ((defaults defaults) (overrides []))
    (if (null? defaults)
      (reverse overrides)
      (let (entry (car defaults))
        (loop (cdr defaults)
              (cons (cdr entry) (cons (car entry) overrides)))))))

(def (dashboard-profile/defaults defaults)
  (if (null? defaults)
    +dashboard-profile+
    (apply .cc +dashboard-profile+ (dashboard-default-overrides defaults))))

(def (event-delta event)
  (let* ((payload (object<-alist event))
         (validated (validate +event-type+ payload))
         (values ((.refs/slots +event-slots+) validated)))
    (+ (car values) (cadr values))))

(def (dashboard-event-deltas events)
  (map event-delta events))

(def (dashboard-score/deltas deltas)
  (let loop ((deltas deltas) (total 0) (last 0))
    (if (null? deltas)
      (list total last)
      (let (delta (car deltas))
        (loop (cdr deltas) (+ total delta) delta)))))

(def (dashboard-result profile score-state)
  (let* ((score (car score-state))
         (last (cadr score-state))
         (updated
          (.cc profile 'score score 'last last))
         (traced (trace-poo updated 'dashboard))
         (ready? ((o?/slots +dashboard-slots+) traced)))
    (if ready?
      (.alist/sort traced)
      (.alist/sort updated))))

(def (score-dashboard profile events)
  (let (deltas (dashboard-event-deltas events))
    (dashboard-result profile (dashboard-score/deltas deltas))))
