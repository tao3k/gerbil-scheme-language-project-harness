;;; -*- Gerbil -*-
(package: sample/poo-method-dispatch)
(import :clan/poo/mop)

;; Generic
(.defgeneric (distance left right))

;; Generic
(.defgeneric (:intersect line circle ctx))

;; Protocol
(defprotocol Point)

;; Protocol
(defprotocol <Line>)

;; Protocol
(defprotocol <Circle>)

;; Protocol
(defprotocol <Ctx>)

;; Number <- Point Point
(defmethod (@method distance Point Point)
  (lambda (left right)
    (point-distance left right)))

;; RenderedIntersection <- Line Circle Context
(defmethod (:intersect (line <Line>) (circle <Circle>) (ctx <Ctx>))
  (render-intersection line circle ctx))
