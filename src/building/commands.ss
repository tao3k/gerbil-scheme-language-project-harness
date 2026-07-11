;;; Declarative command surface for downstream package build scripts.
;;; A project supplies its package loader and domain operations; the Building
;;; Framework supplies the standard command control flow.
(export define-build-commands)

;; define-build-commands
;;   : syntax
;;   | doc m%
;;       Define standard spec, compile, and clean command procedures from a
;;       package loader and three domain-operation thunks.
;;     %
(defrules define-build-commands ()
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
