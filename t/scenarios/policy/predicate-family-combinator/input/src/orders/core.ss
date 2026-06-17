;;; -*- Gerbil -*-
(package: sample/orders)
;;; Predicate boundary:
;;; - Keep duplicated role extraction visible for predicate-family policy tests.
;; Boolean <- CreatedEventFact
(def (created-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (equal? (field-string fields 'role) "created"))))
;;; Predicate boundary:
;;; - Keep the accepted role set inline so repeated field access remains detectable.
;; Boolean <- PaymentEventFact
(def (paid-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (member (field-string fields 'role) '("paid" "settled")))))
;;; Predicate boundary:
;;; - Keep cancellation as a single-purpose predicate for family grouping evidence.
;; Boolean <- CancelledEventFact
(def (cancelled-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (equal? (field-string fields 'role) "cancelled"))))

