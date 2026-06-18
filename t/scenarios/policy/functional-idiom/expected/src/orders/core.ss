;;; -*- Gerbil -*-
(package: sample/orders)
(import (only-in :clan/base !> compose curry fun lambda-match))
(export total total+fee classify-order)

;; total
;;   : (-> (List Number) Number)
;;   | doc m%
;;       `total xs` sums order totals with a pure fold.
;;     %
(def (total xs)
  (foldl + 0 xs))

;; total+fee
;;   : (-> Number (List Number) Number)
;;   | doc m%
;;       `total+fee fee xs` composes the base total with a fee transform.
;;     %
(def (total+fee fee xs)
  (!> xs total (curry + fee)))

;; classify-order
;;   : (-> Order Symbol)
;;   | type Order = HashTable
;;   | doc m%
;;       `classify-order order` keeps local destructuring in a named lambda.
;;     %
(def classify-order
  (fun (classify order)
    ((lambda-match
       ((hash ('state "paid")) 'paid)
       (_ 'open))
     order)))
