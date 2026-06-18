;;; -*- Gerbil -*-
(package: sample/orders)
;;; Predicate boundary:
;;; - Extract role lookup before preserving the public predicate family.
;; : (-> EventFact String )
(def (event-role fact)
  (let (fields (hash-get fact 'fields))
    (and fields (field-string fields 'role))))
;; : (-> (List String) EventFact Boolean )
(def (event-role-member? accepted fact)
  (member (event-role fact) accepted))
;; : (-> CreatedEventFact Boolean )
(def (created-event? fact)
  (event-role-member? '("created") fact))
;; : (-> PaymentEventFact Boolean )
(def (paid-event? fact)
  (event-role-member? '("paid" "settled") fact))
;; : (-> CancelledEventFact Boolean )
(def (cancelled-event? fact)
  (event-role-member? '("cancelled") fact))

