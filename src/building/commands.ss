;;; Declarative command surface for downstream package build scripts.
;;; A project supplies its package loader and domain operations; the Building
;;; Framework supplies the standard command control flow.
(export define-build-commands
        define-build-options)

;; define-build-options
;;   : syntax
;;   | doc m%
;;       Define a project options constructor whose package facade is loaded
;;       before the Framework resolves and invokes the domain constructor.
;;     %
;; define-build-options
;;   : Macro
;;   | doc m%
;;       Defines an options entry point with an optional one-time loader for a
;;       declarative build owner.
;; # Examples
;; ```scheme
;; (define-build-options options! make: make-options)
;; => options! delegates its arguments to a fresh options value
;; ```
;;     %
(defrules define-build-options ()
  ((_ options!
      make: make)
   (def (options! . arguments)
     (apply (make) arguments)))
  ((_ options!
      load!: load!
      make: make)
   (def (options! . arguments)
     (load!)
     (apply (make) arguments))))

;; define-build-commands
;;   : syntax
;;   | doc m%
;;       Define standard spec, compile, and clean command procedures from a
;;       package loader and three domain-operation thunks.
;;     %
;; define-build-commands
;;   : Macro
;;   | doc m%
;;       Defines spec, compile, and clean commands while keeping optional
;;       build-root loading at the command boundary.
;; # Examples
;; ```scheme
;; (define-build-commands (spec! compile! clean!) ...)
;; => each command calls its declared build operation exactly once
;; ```
;;     %
(defrules define-build-commands ()
  ((_ (spec! compile! clean!)
      spec: spec
      compile: compile
      clean: clean)
   (begin
     (def (spec! options)
       ((spec) options))
     (def (compile! options)
       ((compile) options))
     (def (clean!)
       ((clean)))))
  ((_ (spec! compile! clean!)
      load!: load!
      spec: spec
      compile: compile
      clean: clean)
   (begin
     (def (spec! options)
       (load!)
       ((spec) options))
     (def (compile! options)
       (load!)
       ((compile) options))
     (def (clean!)
       (load!)
       ((clean))))))
