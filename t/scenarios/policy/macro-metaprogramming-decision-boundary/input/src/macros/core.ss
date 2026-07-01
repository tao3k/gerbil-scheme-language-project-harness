;;; -*- Gerbil -*-
(package: sample/meta)

(export define-flow-arr
        define-flow-map
        define-flow-bind
        define-flow-compose
        with-flow-field)

(defrules define-flow-arr ()
  ((_ id proc)
   (def id (flow-arr proc))))

(defrules define-flow-map ()
  ((_ id proc upstream)
   (def id (flow-map proc upstream))))

(defrules define-flow-bind ()
  ((_ id upstream proc)
   (def id (flow-bind upstream proc))))

(defrules define-flow-compose ()
  ((_ id left right)
   (def id (flow-compose left right))))

(defsyntax (with-flow-field stx)
  (syntax-case stx ()
    ((_ field body)
     (if (identifier? #'field)
       (with-syntax ((current #'field))
         #'(let ((current-flow current)) body))
       (error "bad with-flow-field syntax")))))
