;;; -*- Gerbil -*-
;;; Stable policy facade for Gerbil project rules.

(import :policy/agent
        :policy/core
        :policy/model
        :policy/modularity)

(export make-policy-rule
        policy-rule-id
        policy-rule-severity
        +modularity-facade-rule+
        +agent-intent-rule+
        run-policy-checks
        run-modularity-policy
        facade-source-file?
        facade-implementation-finding
        run-agent-policy
        facade-intent-finding)
