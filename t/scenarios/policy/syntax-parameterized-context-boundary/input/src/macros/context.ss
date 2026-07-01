;;; -*- Gerbil -*-
(package: sample/syntax-parameter-context/input)

(export with-flow-context @flow)

(begin-syntax
  (def +current-flow-context+ #f)
  (def (current-flow-context stx)
    (or +current-flow-context+
        (error "missing flow context"))))

(defsyntax (with-flow-context stx)
  (syntax-case stx ()
    ((_ flow-id body ...)
     (begin
       (set! +current-flow-context+ #'flow-id)
       #'(begin body ...)))))

(defsyntax (@flow stx)
  (syntax-case stx ()
    ((_) (current-flow-context stx))))
