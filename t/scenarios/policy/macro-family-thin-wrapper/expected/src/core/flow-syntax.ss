;;; -*- Gerbil -*-
;;; Boundary:
;;; - A macro family keeps the syntax surface small.
;;; - Runtime flow semantics remain in ordinary helpers.
(package: sample/flow)

(export defpoo-flow)

;; defpoo-flow
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `defpoo-flow` expands one named flow declaration from a bounded family.
;;
;;       # Examples
;;
;;       ```scheme
;;       (defpoo-flow arr parse flow-parse)
;;       ;; => (def parse (flow-arr flow-parse))
;;       ```
;;     %
(defrules defpoo-flow ()
  ((_ arr id proc)
   (def id (flow-arr proc)))
  ((_ identity id)
   (def id (flow-identity)))
  ((_ compose id left right)
   (def id (flow-compose left right)))
  ((_ map id proc upstream)
   (def id (flow-map proc upstream)))
  ((_ bind id upstream proc)
   (def id (flow-bind upstream proc))))
