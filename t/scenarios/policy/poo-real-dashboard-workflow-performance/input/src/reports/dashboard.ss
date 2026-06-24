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

(def (dashboard-profile/defaults defaults)
  (let loop ((defaults defaults) (current (build-dashboard-profile)))
    (if (null? defaults)
      current
      (let* ((override (car defaults))
             (next (object<-alist (cons override +dashboard-profile+))))
        (loop (cdr defaults) next)))))

(def (score-dashboard profile events)
  (let loop ((events events) (current profile) (total 0))
    (if (null? events)
      (.alist/sort (trace-poo current 'dashboard))
      (let* ((event (car events))
             (payload (object<-alist event))
             (validated (validate +event-type+ payload))
             (values ((.refs/slots +event-slots+) validated))
             (ready? ((o?/slots +event-slots+) validated))
             (delta (if ready? (+ (car values) (cadr values)) 0))
             (next
              (.mix
               (.cc current 'score (+ total delta))
               (object<-alist (list (cons 'last delta))))))
        (loop (cdr events) next (+ total delta))))))
