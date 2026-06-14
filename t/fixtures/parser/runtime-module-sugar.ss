;;; -*- Gerbil -*-
;;; Runtime module sugar parser fixture.
prelude: :<root>
package: sample/runtime-module-sugar

(import "runtime")
(export #t)

;; ImportExpander <- Syntax
(defsyntax-for-import (only-in stx)
  (syntax-case stx ()
    ((_ hd id ...)
     (identifier-list? #'(id ...))
     #'(begin))))

;; ExportExpander <- Syntax
(defsyntax-for-export (except-out stx)
  (syntax-case stx ()
    ((_ hd id ...)
     (identifier-list? #'(id ...))
     #'(begin))))

;; ImportExportExpander <- Syntax
(defsyntax-for-import-export (for-syntax stx)
  (syntax-case stx ()
    ((_ body ...)
     #'(phi: +1 body ...))))
