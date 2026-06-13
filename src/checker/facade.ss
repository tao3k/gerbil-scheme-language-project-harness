;;; -*- Gerbil -*-
;;; Stable checker facade for native Gerbil project checks.

(import :checker/arity
        :checker/core
        :checker/forms
        :checker/model
        :checker/types
        :checker/whitelist)

(export make-checker-rule
        checker-rule-id
        checker-rule-severity
        make-checker-evidence
        checker-evidence-callee
        checker-evidence-expected
        checker-evidence-actual
        checker-evidence-selector
        checker-evidence-signature
        +arity-rule+
        +type-mismatch-rule+
        +whitelist-rule+
        +macro-governance-rule+
        +forbidden-form-rule+
        run-checker-checks
        run-checker-checks/whitelist
        run-arity-checks
        call-arity-finding
        run-type-mismatch-checks
        call-type-mismatch-findings
        +macro-governance-form-heads+
        +forbidden-form-heads+
        +macro-governance-policy-explanation-min-length+
        +macro-governance-policy-witness-min-length+
        run-macro-governance-checks
        macro-governance-finding
        run-forbidden-form-checks
        forbidden-form-finding
        load-call-whitelist
        run-whitelist-checks
        call-whitelist-finding)
