;;; -*- Gerbil -*-
;;; Stable types facade for the Gerbil Scheme project harness.

(import :types/core
        :types/env
        :types/findings
        :types/model
        :types/signatures)

(export make-type-unknown
        make-type-any
        make-type-base
        make-type-function
        type-kind
        type-name
        type-params
        type-result
        type=?
        type->string
        parse-type-sexpr
        load-type-signatures
        parse-type-signature
        signature-type-for
        make-type-binding
        type-binding-name
        type-binding-kind
        type-binding-type
        type-binding-formals
        type-binding-arity
        type-binding-path
        type-binding-selector
        build-type-env
        build-type-env/signatures
        duplicate-type-bindings
        type-finding-rule-id
        type-finding-severity
        type-finding-path
        type-finding-message
        type-finding-selector
        type-finding-details
        type-status
        run-type-checks
        run-type-checks/signatures
        run-type-checks/whitelist
        source-file-type-findings)
