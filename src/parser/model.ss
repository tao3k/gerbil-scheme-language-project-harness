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
        make-module-export-fact
        module-export-fact-name
        module-export-fact-modifier
        module-export-fact-alias
        module-export-fact-module
        module-export-fact-symbols
        module-export-fact-path
        module-export-fact-start
        module-export-fact-end
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
        macro-fact-quality-facets
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
        poo-form-fact-specializers
        poo-form-fact-specializer-types
        make-higher-order-fact
        higher-order-fact-name
        higher-order-fact-kind
        higher-order-fact-path
        higher-order-fact-start
        higher-order-fact-end
        higher-order-fact-role
        higher-order-fact-operand-count
        higher-order-fact-arities
        higher-order-fact-formals
        higher-order-fact-caller
        make-control-flow-fact
        control-flow-fact-name
        control-flow-fact-kind
        control-flow-fact-path
        control-flow-fact-start
        control-flow-fact-end
        control-flow-fact-role
        control-flow-fact-caller
        control-flow-fact-binding-count
        control-flow-fact-body-form-count
        make-typed-contract-fact
        typed-contract-fact-definition-name
        typed-contract-fact-definition-kind
        typed-contract-fact-definition-formals
        typed-contract-fact-definition-arity
        typed-contract-fact-path
        typed-contract-fact-definition-start
        typed-contract-fact-definition-end
        typed-contract-fact-comment-start
        typed-contract-fact-comment-end
        typed-contract-fact-contract
        typed-contract-fact-contract-output
        typed-contract-fact-contract-inputs
        typed-contract-fact-contract-input-count
        typed-contract-fact-arity-alignment
        typed-contract-fact-tokens
        typed-contract-fact-arrow-count
        typed-contract-fact-group-count
        typed-contract-fact-quality
        typed-contract-fact-reasons
        typed-contract-fact-quality-facets
        typed-contract-fact-repair-evidence
        make-comment-quality-fact
        comment-quality-fact-target-kind
        comment-quality-fact-target-name
        comment-quality-fact-path
        comment-quality-fact-target-start
        comment-quality-fact-target-end
        comment-quality-fact-comment-start
        comment-quality-fact-comment-end
        comment-quality-fact-comment-lines
        comment-quality-fact-comment-kind
        comment-quality-fact-quality
        comment-quality-fact-reasons
        comment-quality-fact-required
        comment-quality-fact-context
        comment-quality-fact-evidence
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
        source-file-module-exports
        source-file-macros
        source-file-bindings
        source-file-poo-forms
        source-file-higher-order-forms
        source-file-control-flow-forms
        source-file-typed-contract-facts
        source-file-comment-quality-facts
        source-file-parse-error
        make-project-index
        project-index-root
        project-index-files
        project-index-package)
;; DefinitionStruct
(defstruct definition (name kind path start end formals arity))
;; CallFactStruct
(defstruct call-fact (callee arity path start end arguments argument-types caller))
;; ModuleImportFactStruct
(defstruct module-import-fact (module phase modifier alias symbols path start end))
;; ModuleExportFactStruct
(defstruct module-export-fact (name modifier alias module symbols path start end))
;; MacroFactStruct
(defstruct macro-fact (name kind path start end transformer phase pattern-count hygienic quality-facets))
;; BindingFactStruct
(defstruct binding-fact (name kind path start end scope value-type))
;; PooFormFactStruct
(defstruct poo-form-fact (name kind path start end role generic receiver receiver-type supers slots options specializers specializer-types))
;; HigherOrderFactStruct
(defstruct higher-order-fact (name kind path start end role operand-count arities formals caller))
;; ControlFlowFactStruct
(defstruct control-flow-fact (name kind path start end role caller binding-count body-form-count))
;; TypedContractFactStruct
(defstruct typed-contract-fact (definition-name definition-kind definition-formals definition-arity path definition-start definition-end comment-start comment-end contract contract-output contract-inputs contract-input-count arity-alignment tokens arrow-count group-count quality reasons quality-facets repair-evidence))
;; CommentQualityFactStruct
(defstruct comment-quality-fact (target-kind target-name path target-start target-end comment-start comment-end comment-lines comment-kind quality reasons required context evidence))
;; TopFormStruct
(defstruct top-form (kind head path start end))
;; SourceFileStruct
(defstruct source-file (path line-count package prelude namespace imports exports includes definitions calls forms module-imports module-exports macros bindings poo-forms higher-order-forms control-flow-forms typed-contract-facts comment-quality-facts parse-error))
;; ProjectIndexStruct
(defstruct project-index (root files package))
