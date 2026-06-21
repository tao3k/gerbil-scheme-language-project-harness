;;; -*- Gerbil -*-
(package: sample/math)
(export poly-add poly-scale)

;; poly-add
;;   : (-> (List Number) (List Number) (List Number))
;;   | doc m%
;;       `poly-add left right` adds coefficients pointwise.
;;     %
(def (poly-add left right)
  (map + left right))

;; poly-scale
;;   : (-> Number (List Number) (List Number))
;;   | doc m%
;;       `poly-scale factor coefficients` scales every coefficient.
;;     %
(def (poly-scale factor coefficients)
  (map (lambda (value) (* factor value)) coefficients))
