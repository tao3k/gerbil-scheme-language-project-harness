;;; -*- Gerbil -*-
(import :clan/poo/debug
        :clan/poo/mop
        :clan/poo/number
        :clan/poo/object)

(def +dashboard-profile+
  '((id . "orders")
    (score . 0)
    (last . 0)
    (rows . 12)
    (alerts . 3)
    (priority . 2)))

(def +event-slots+ '(quantity risk))
(def +dashboard-slots+ '(score last rows alerts priority))
(def +event-type+ (MonomorphicObject Integer))

(def (build-dashboard-profile)
  (object<-alist +dashboard-profile+))

(def (dashboard-profile-alist/defaults defaults)
  (let loop ((defaults defaults) (rows +dashboard-profile+))
    (if (null? defaults)
      rows
      (loop (cdr defaults) (cons (car defaults) rows)))))

(def (dashboard-profile/defaults defaults)
  (object<-alist (dashboard-profile-alist/defaults defaults)))

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
          (.mix
           (.cc profile 'score score)
           (object<-alist (list (cons 'last last)))))
         (traced (trace-poo updated 'dashboard))
         (ready? ((o?/slots +dashboard-slots+) traced)))
    (if ready?
      (.alist/sort traced)
      (.alist/sort updated))))

(def (score-dashboard profile events)
  (let (deltas (dashboard-event-deltas events))
    (dashboard-result profile (dashboard-score/deltas deltas))))
