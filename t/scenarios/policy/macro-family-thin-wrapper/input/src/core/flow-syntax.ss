;;; -*- Gerbil -*-
(package: sample/flow)

(export defpoo-flow-arr
        defpoo-flow-identity
        defpoo-flow-compose
        defpoo-flow-map
        defpoo-flow-bind)

(defrules defpoo-flow-arr ()
  ((_ id proc)
   (def id (flow-arr proc))))

(defrules defpoo-flow-identity ()
  ((_ id)
   (def id (flow-identity))))

(defrules defpoo-flow-compose ()
  ((_ id left right)
   (def id (flow-compose left right))))

(defrules defpoo-flow-map ()
  ((_ id proc upstream)
   (def id (flow-map proc upstream))))

(defrules defpoo-flow-bind ()
  ((_ id upstream proc)
   (def id (flow-bind upstream proc))))
