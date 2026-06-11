;;; -*- Gerbil -*-
;;; Stable checker facade for native Gerbil project checks.

(import :checker/arity
        :checker/core
        :checker/forms
        :checker/model
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
        +whitelist-rule+
        +forbidden-form-rule+
        run-checker-checks
        run-checker-checks/whitelist
        run-arity-checks
        call-arity-finding
        +forbidden-form-heads+
        run-forbidden-form-checks
        forbidden-form-finding
        load-call-whitelist
        run-whitelist-checks
        call-whitelist-finding)
