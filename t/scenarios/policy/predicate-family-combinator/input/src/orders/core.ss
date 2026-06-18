;;; -*- Gerbil -*-
(package: sample/orders)
;;; Predicate boundary:
;;; - Keep duplicated role extraction visible for predicate-family policy tests.
;; : (-> CreatedEventFact Boolean )
(def (created-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (equal? (field-string fields 'role) "created"))))
;;; Predicate boundary:
;;; - Keep the accepted role set inline so repeated field access remains detectable.
;; : (-> PaymentEventFact Boolean )
(def (paid-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (member (field-string fields 'role) '("paid" "settled")))))
;;; Predicate boundary:
;;; - Keep cancellation as a single-purpose predicate for family grouping evidence.
;; : (-> CancelledEventFact Boolean )
(def (cancelled-event? fact)
  (let (fields (hash-get fact 'fields))
    (and fields (equal? (field-string fields 'role) "cancelled"))))

