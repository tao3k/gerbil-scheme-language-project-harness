;;; -*- Gerbil -*-
(import :clan/poo/object)

(def (build-loop-capability-receipt backend diagnostics)
  (object<-alist
   (list
    (cons 'kind 'capability-receipt)
    (cons 'backend backend)
    (cons 'valid? (null? diagnostics))
    (cons 'diagnostics diagnostics)
    (cons 'runtime-owner "marlin-agent-core")
    (cons 'runtime-executed #f))))
