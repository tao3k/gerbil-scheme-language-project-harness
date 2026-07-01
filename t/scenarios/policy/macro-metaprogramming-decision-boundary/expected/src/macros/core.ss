;;; -*- Gerbil -*-
;;; Boundary:
;;; - Fixed declaration shapes stay in declarative defrules clauses.
;;; - Syntax-object validation and source-aware errors stay in syntax-case.
(package: sample/meta)

(export define-flow
        with-flow-field)

;; define-flow
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `define-flow` expands one bounded flow declaration family.
;;
;;       # Examples
;;
;;       ```scheme
;;       (define-flow arr parse flow-parse)
;;       ;; => (def parse (flow-arr flow-parse))
;;       ```
;;     %
(defrules define-flow ()
  ((_ arr id proc)
   (def id (flow-arr proc)))
  ((_ map id proc upstream)
   (def id (flow-map proc upstream)))
  ((_ bind id upstream proc)
   (def id (flow-bind upstream proc)))
  ((_ compose id left right)
   (def id (flow-compose left right))))

;; with-flow-field
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `with-flow-field` validates an identifier syntax object and expands a
;;       scoped flow-field binding.
;;
;;       # Examples
;;
;;       ```scheme
;;       (with-flow-field field body)
;;       ;; => (let ((current-flow field)) body)
;;       ```
;;     %
(defsyntax (with-flow-field stx)
  (def (emit field body)
    (with-syntax ((current #'field))
      #'(let ((current-flow current)) body)))
  (syntax-case stx ()
    ((_ field body)
     (identifier? #'field)
     (emit #'field #'body))
    (_
     (raise-syntax-error
      #f
      "Bad syntax; expected (with-flow-field field body)"
      stx))))
