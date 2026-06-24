;;; -*- Gerbil -*-
;;; Boundary:
;;; - Orders generator helpers use a named local generator reducer boundary.
(package: sample/orders)
(export generated-total)

;; fold-generated
;;   : (-> (Generating Number) Number (-> Number Number Number) Number)
;;   | doc m%
;;       `fold-generated source seed combine` consumes one numeric generator
;;       through a reusable reducer protocol.
;;
;;       # Examples
;;
;;       ```scheme
;;       (fold-generated source 0 +)
;;       ;; => 12
;;       ```
;;     %
(def (fold-generated source seed combine)
  (let loop ((acc seed))
    (let (value (source))
      (if (eof-object? value)
        acc
        (loop (combine value acc))))))

;;; Boundary:
;;; - generated-total keeps producer traversal in one reducer boundary.
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
  (fold-generated source 0 +))
