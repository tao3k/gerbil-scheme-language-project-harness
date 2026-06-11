;;; -*- Gerbil -*-
;;; Stable parser facade for the Gerbil Scheme project harness.

(import :parser/core)

(export +source-extensions+
        +config-files+
        +ignored-dirs+
        collect-project
        collect-source-files
        gerbil-source-path?
        parse-source-file
        project-definitions
        project-calls
        find-owner
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        definition-selector
        call-fact-callee
        call-fact-arity
        call-fact-path
        call-fact-start
        call-fact-end
        call-fact-selector
        top-form-kind
        top-form-head
        top-form-path
        top-form-start
        top-form-end
        top-form-selector
        source-file-path
        source-file-package
        source-file-prelude
        source-file-namespace
        source-file-imports
        source-file-exports
        source-file-includes
        source-file-definitions
        source-file-calls
        source-file-forms
        source-file-parse-error
        project-index-root
        project-index-files)
