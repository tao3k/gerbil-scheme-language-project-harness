;;; -*- Gerbil -*-
;;; Agent command adapter.

(import :commands/guide
        :constants
        :protocol/json
        :protocol/registry
        :support/args)

(export agent-main)
;;; Invariant:
;;; - agent-main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; AgentMain <- (List XX)
(def (agent-main args)
  (match args
    (["doctor" . rest]
     (let ((root (project-root rest))
           (json? (flag? "--json" rest)))
       (if json?
         (write-json-line (language-registry root))
         (displayln "[gerbil-agent-doctor] status=ok language=" +language-id+
                    " provider=" +provider-id+))
       0))
    (["guide" . _]
     (print-guide)
     0)
    (else (error "agent requires doctor or guide"))))
