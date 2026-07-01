;;; -*- Gerbil -*-

(defstruct loop-capability-receipt
  (backend valid? diagnostics)
  transparent: #t)

(def (build-loop-capability-receipt backend diagnostics)
  (make-loop-capability-receipt backend
                                (null? diagnostics)
                                diagnostics))

(def (loop-capability-receipt->alist receipt)
  (list
   (cons 'kind 'capability-receipt)
   (cons 'backend (loop-capability-receipt-backend receipt))
   (cons 'valid? (loop-capability-receipt-valid? receipt))
   (cons 'diagnostics (loop-capability-receipt-diagnostics receipt))
   (cons 'runtime-owner "marlin-agent-core")
   (cons 'runtime-executed #f)))
