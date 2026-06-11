;;; -*- Gerbil -*-
;;; Policy dispatch for Gerbil project rules.

(import :policy/agent
        :policy/modularity)

(export run-policy-checks)

(def (run-policy-checks index)
  (append (run-modularity-policy index)
          (run-agent-policy index)))
