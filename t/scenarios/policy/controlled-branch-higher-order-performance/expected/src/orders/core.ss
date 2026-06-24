;;; -*- Gerbil -*-
(package: sample/orders)
(import (only-in :clan/base compose curry fun lambda-match))
(export classify-order paid-order?)

;; classify-order
;;   : (-> Order Symbol)
;;   | doc m%
;;       `classify-order order` keeps pattern dispatch in lambda-match instead
;;       of repeated branch-local match scaffolding.
;;     %
(def classify-order
  (fun (classify order)
    ((lambda-match
       ((hash ('state "paid")) 'paid)
       ((hash ('state "failed")) 'failed)
       (_ 'open))
     order)))

;; paid-order?
;;   : (-> Order Boolean)
;;   | doc m%
;;       `paid-order? order` reuses the classifier through composed
;;       specialization instead of reopening the order shape.
;;     %
(def paid-order?
  (compose (curry eq? 'paid) classify-order))
