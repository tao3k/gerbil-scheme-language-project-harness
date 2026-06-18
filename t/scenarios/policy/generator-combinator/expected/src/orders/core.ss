;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders generator helpers use gerbil-utils/generator combinators.
(package: sample/orders)
(import (only-in :gerbil-utils/generator generating-fold))
(export generated-total)

;;; Boundary:
;;; - generated-total keeps producer traversal in the generator fold algebra.
;; generated-total
;;   : (-> (Generating Number) Number)
;;   | doc m%
;;       `generated-total source` folds a numeric generator into a total.
;;
;;       # Examples
;;
;;       ```scheme
;;       (generated-total source)
;;       ;; => 12
;;       ```
;;     %
(def (generated-total source)
  (generating-fold source 0 (lambda (value acc) (+ acc value))))
