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
        +modularity-repeated-owner-entry-rule+
        +modularity-bin-entrypoint-rule+
        +modularity-test-directory-rule+
        +agent-intent-rule+
        +agent-generic-owner-rule+
        +agent-export-conflict-rule+
        +agent-vague-definition-rule+
        +agent-top-level-executable-rule+
        run-policy-checks
        run-modularity-policy
        +max-source-line-count+
        +min-source-definition-count+
        facade-source-file?
        facade-implementation-finding
        sibling-file-dir-owner-collision-finding
        repeated-owner-entry-finding
        bin-entrypoint-implementation-finding
        source-leaf-bloat-finding
        run-agent-policy
        facade-intent-finding
        generic-owner-segment
        generic-owner-finding
        vague-definition-finding
        top-level-executable-finding
        facade-export-conflict-findings)
