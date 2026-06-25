;;; -*- Gerbil -*-
(package: sample/dashboard)
(import :clan/poo/object)
(export build-profile score-events dispatch-dashboard update-profile dashboard-threshold
        event-priority)

(def +profile+
  '((id . "orders")
    (status . "hot")
    (score . 0)
    (rows . 8)
    (columns . 5)
    (alerts . 6)
    (priority . "high")))

(def (build-profile)
  (object<-alist +profile+))

(def (score-events events)
  (let loop ((rest events) (total 0) (matched '()))
    (if (null? rest)
      (list total matched)
      (let (event (car rest))
        (if (and (pair? event) (equal? (car event) 'order))
          (loop (cdr rest) (+ total (cdr event)) (cons event matched))
          (if (and (pair? event) (equal? (car event) 'alert))
            (loop (cdr rest) (+ total (event-priority 'critical)) matched)
            (loop (cdr rest) total matched)))))))

(def (event-priority level)
  (if (equal? level 'critical)
    3
    (if (equal? level 'warning)
      2
      (if (equal? level 'notice)
        1
        0))))

(def (dispatch-dashboard command args)
  (let (fast-result
        (and (equal? command "score")
             (score-events args)))
    (if fast-result
      fast-result
      (if (equal? command "profile")
        (build-profile)
        (if (equal? command "threshold")
          (dashboard-threshold (car args))
          (if (equal? command "update")
            (update-profile (build-profile) (cdr args))
            (error "unknown dashboard command" command)))))))

(def (update-profile profile limit)
  (let loop ((index 0) (current profile))
    (if (= index limit)
      current
      (loop (+ index 1) (.cc current 'score index)))))

(def (dashboard-threshold mode)
  (if (equal? mode 'fast)
    10
    (if (equal? mode 'safe)
      2
      5)))
