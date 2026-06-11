;;; -*- Gerbil -*-
;;; Stable types facade for the Gerbil Scheme project harness.

(import :types/core
        :types/env
        :types/findings)

(export make-type-binding
        type-binding-name
        type-binding-kind
        type-binding-type
        type-binding-path
        type-binding-selector
        build-type-env
        duplicate-type-bindings
        type-finding-rule-id
        type-finding-severity
        type-finding-path
        type-finding-message
        type-finding-selector
        type-finding-details
        type-status
        run-type-checks
        source-file-type-findings)
