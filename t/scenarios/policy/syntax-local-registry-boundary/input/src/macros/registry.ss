;;; -*- Gerbil -*-
(package: sample/syntax-local-registry/input)

(export def-flow-type flow-kind)

(begin-syntax
  (def +flow-type-table+ (make-hash-table)))

(defsyntax (def-flow-type stx)
  (syntax-case stx ()
    ((_ id kind)
     (identifier? #'id)
     (begin
       (hash-put! +flow-type-table+ (syntax->datum #'id) (syntax->datum #'kind))
       #'(def id 'kind)))))

(defsyntax (flow-kind stx)
  (syntax-case stx ()
    ((_ id)
     (let (kind (hash-get +flow-type-table+ (syntax->datum #'id) #f))
       (if kind
         (with-syntax ((kind (datum->syntax #'id kind)))
           #'(quote kind))
         (error "unknown flow type"))))))
