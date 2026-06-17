;;; -*- Gerbil -*-
(package: sample/orders)
;;; Predicate boundary:
;;; - Extract role lookup before preserving the public predicate family.
;; String <- EventFact
(def (event-role fact)
  (let (fields (hash-get fact 'fields))
    (and fields (field-string fields 'role))))
;; Boolean <- (List String) EventFact
(def (event-role-member? accepted fact)
  (member (event-role fact) accepted))
;; Boolean <- CreatedEventFact
(def (created-event? fact)
  (event-role-member? '("created") fact))
;; Boolean <- PaymentEventFact
(def (paid-event? fact)
  (event-role-member? '("paid" "settled") fact))
;; Boolean <- CancelledEventFact
(def (cancelled-event? fact)
  (event-role-member? '("cancelled") fact))

