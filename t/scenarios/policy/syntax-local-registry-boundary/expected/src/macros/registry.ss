;;; -*- Gerbil -*-
;;; Boundary:
;;; - Compile-time metadata is attached to the identifier with defsyntax.
;;; - Lookup uses syntax-local-value and validates the metadata class.
(package: sample/syntax-local-registry/expected)

(export def-flow-type flow-kind)

(begin-syntax
  (defclass flow-type-info (kind))
  (def (syntax-local-flow-type id)
    (let (info (syntax-local-value id false))
      (if (flow-type-info? info)
        info
        (raise-syntax-error #f "Bad syntax; not defined as a flow type" id)))))

;; def-flow-type
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `def-flow-type` binds runtime value and compile-time metadata together.
;;
;;       # Examples
;;
;;       ```scheme
;;       (def-flow-type parser stream)
;;       ;; => parser is also metadata-addressable by flow-kind
;;       ```
;;     %
(defsyntax (def-flow-type stx)
  (syntax-case stx ()
    ((_ id kind)
     (and (identifier? #'id) (identifier? #'kind))
     #'(begin
         (def id 'kind)
         (defsyntax id
           (make-flow-type-info kind: (quote-syntax kind)))))
    (_
     (raise-syntax-error
      #f
      "Bad syntax; expected (def-flow-type id kind)"
      stx))))

;; flow-kind
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `flow-kind` expands from identifier-owned compile-time metadata.
;;
;;       # Examples
;;
;;       ```scheme
;;       (flow-kind parser)
;;       ;; => 'stream
;;       ```
;;     %
(defsyntax (flow-kind stx)
  (syntax-case stx ()
    ((_ id)
     (let (info (syntax-local-flow-type #'id))
       (with-syntax ((kind (flow-type-info-kind info)))
         #'(quote kind))))
    (_
     (raise-syntax-error
      #f
      "Bad syntax; expected (flow-kind id)"
      stx))))
