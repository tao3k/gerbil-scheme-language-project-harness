;;; -*- Gerbil -*-
;;; Agent command adapter.

(import :commands/guide
        :constants
        :protocol/json
        :protocol/registry
        :support/args)

(export agent-main)
;; agent-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `agent-main args` dispatches harness agent subcommands and returns a
;;       process-style status code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (agent-main '("doctor" "--workspace" "."))
;;       ;; => 0
;;       ```
;;     %
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
