;;; -*- Gerbil -*-
(package: sample/math)
(import :clan/poo/polynomial)
(export OrderPolynomial. poly-add poly-scale)

;; poly-add
;;   : (-> (List Number) (List Number) (List Number))
;;   | doc m%
;;       `poly-add left right` delegates addition to the polynomial descriptor.
;;     %
(def (poly-add left right)
  (.@ OrderPolynomial. '.+ left right))

;; poly-scale
;;   : (-> Number (List Number) (List Number))
;;   | doc m%
;;       `poly-scale factor coefficients` delegates scaling to the descriptor.
;;     %
(def (poly-scale factor coefficients)
  (.@ OrderPolynomial. 'scale factor coefficients))

(define-type (OrderPolynomial. @ Polynomial.)
  .Ring: Number
  .zero: []
  .add: poly-add
  .scale: poly-scale)
