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
        +modularity-source-leaf-rule+
        +modularity-owner-collision-rule+
        +agent-intent-rule+
        +agent-generic-owner-rule+
        +agent-export-conflict-rule+
        run-policy-checks
        run-modularity-policy
        +max-source-line-count+
        +min-source-definition-count+
        facade-source-file?
        facade-implementation-finding
        sibling-file-dir-owner-collision-finding
        source-leaf-bloat-finding
        run-agent-policy
        facade-intent-finding
        generic-owner-segment
        generic-owner-finding
        facade-export-conflict-findings)
