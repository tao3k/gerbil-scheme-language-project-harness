;;; -*- Gerbil -*-
;;; Boundary:
;;; - Scoped compile-time context is a syntax parameter, not mutable globals.
;;; - Unbound contextual macros fail at the syntax boundary with source context.
(package: sample/syntax-parameter-context/expected)

(import :std/stxparam)
(export with-flow-context @flow)

;; @flow
;;   : SyntaxParameter
;;   | doc m%
;;       `@flow` expands to the flow identifier bound by `with-flow-context`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (with-flow-context current (@flow))
;;       ;; => current
;;       ```
;;     %
(defsyntax-parameter* @flow @@flow "Bad syntax; not in with-flow-context")

;; with-flow-context
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       `with-flow-context` binds the contextual flow identifier for nested
;;       compile-time macros with `syntax-parameterize`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (with-flow-context current body ...)
;;       ;; => body ... with @flow bound to current
;;       ```
;;     %
(defsyntax (with-flow-context stx)
  (syntax-case stx ()
    ((_ flow-id body ...)
     (identifier? #'flow-id)
     #'(syntax-parameterize ((@@flow (quote-syntax flow-id)))
         body ...))
    (_
     (raise-syntax-error
      #f
      "Bad syntax; expected (with-flow-context flow-id body ...)"
      stx))))
