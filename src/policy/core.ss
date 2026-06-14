;;; -*- Gerbil -*-
;;; Policy dispatch for Gerbil project rules.

(import :parser/core
        :parser/package
        :policy/agent
        :policy/modularity
        :types/findings)

(export run-policy-checks)
;; (List TypeFinding) <- ProjectIndex
(def (run-policy-checks index)
  (filter-enabled-policy-findings
   index
   (append (run-modularity-policy index)
           (run-agent-policy index))))
;;; Boundary:
;;; - filter-enabled-policy-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex (List TypeFinding)
(def (filter-enabled-policy-findings index findings)
  (let* ((package (project-index-package index))
         (policy (and package (project-package-agent-policy package))))
    (if policy
      (filter (cut policy-finding-enabled? policy <>)
              findings)
      findings)))
;; Boolean <- Policy TypeFinding
(def (policy-finding-enabled? policy finding)
  (let ((rule-id (type-finding-rule-id finding))
        (enabled (agent-policy-enabled-rules policy))
        (disabled (agent-policy-disabled-rules policy)))
    (and (or (null? enabled) (member rule-id enabled))
         (not (member rule-id disabled)))))
