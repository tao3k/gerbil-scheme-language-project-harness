;;; -*- Gerbil -*-
;;; Data model for parser-owned Gerbil source facts.

(export make-definition
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        make-call-fact
        call-fact-callee
        call-fact-arity
        call-fact-path
        call-fact-start
        call-fact-end
        call-fact-arguments
        call-fact-argument-types
        call-fact-caller
        make-module-import-fact
        module-import-fact-module
        module-import-fact-phase
        module-import-fact-modifier
        module-import-fact-alias
        module-import-fact-symbols
        module-import-fact-path
        module-import-fact-start
        module-import-fact-end
        make-macro-fact
        macro-fact-name
        macro-fact-kind
        macro-fact-path
        macro-fact-start
        macro-fact-end
        macro-fact-transformer
        macro-fact-phase
        macro-fact-pattern-count
        macro-fact-hygienic
        make-binding-fact
        binding-fact-name
        binding-fact-kind
        binding-fact-path
        binding-fact-start
        binding-fact-end
        binding-fact-scope
        binding-fact-value-type
        make-poo-form-fact
        poo-form-fact-name
        poo-form-fact-kind
        poo-form-fact-path
        poo-form-fact-start
        poo-form-fact-end
        poo-form-fact-role
        poo-form-fact-generic
        poo-form-fact-receiver
        poo-form-fact-receiver-type
        poo-form-fact-supers
        poo-form-fact-slots
        poo-form-fact-options
        make-top-form
        top-form-kind
        top-form-head
        top-form-path
        top-form-start
        top-form-end
        make-source-file
        source-file-path
        source-file-line-count
        source-file-package
        source-file-prelude
        source-file-namespace
        source-file-imports
        source-file-exports
        source-file-includes
        source-file-definitions
        source-file-calls
        source-file-forms
        source-file-module-imports
        source-file-macros
        source-file-bindings
        source-file-poo-forms
        source-file-parse-error
        make-project-index
        project-index-root
        project-index-files
        project-index-package)

(defstruct definition (name kind path start end formals arity))
(defstruct call-fact (callee arity path start end arguments argument-types caller))
(defstruct module-import-fact (module phase modifier alias symbols path start end))
(defstruct macro-fact (name kind path start end transformer phase pattern-count hygienic))
(defstruct binding-fact (name kind path start end scope value-type))
(defstruct poo-form-fact (name kind path start end role generic receiver receiver-type supers slots options))
(defstruct top-form (kind head path start end))
(defstruct source-file (path line-count package prelude namespace imports exports includes definitions calls forms module-imports macros bindings poo-forms parse-error))
(defstruct project-index (root files package))
