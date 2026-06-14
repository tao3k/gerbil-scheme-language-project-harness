;;; -*- Gerbil -*-
;;; Stable snapshot projections for native parser facts.

(import :parser/facade
        :snapshot/support)

(export parser-source-file-snapshot)

;;; Boundary:
;;; - parser-source-file-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- SourceFile
(def (parser-source-file-snapshot file)
  (list 'parserSourceFile
        (list 'path (source-file-path file))
        (list 'definitions
              (map parser-definition-snapshot
                   (source-file-definitions file)))
        (list 'moduleImports
              (map parser-module-import-snapshot
                   (source-file-module-imports file)))
        (list 'moduleExports
              (map parser-module-export-snapshot
                   (source-file-module-exports file)))
        (list 'macros
              (map parser-macro-snapshot
                   (source-file-macros file)))
        (list 'bindings
              (map parser-binding-snapshot
                   (source-file-bindings file)))
        (list 'pooForms
              (map parser-poo-form-snapshot
                   (source-file-poo-forms file)))
        (list 'higherOrderForms
              (map parser-higher-order-form-snapshot
                   (source-file-higher-order-forms file)))
        (list 'controlFlowForms
              (map parser-control-flow-form-snapshot
                   (source-file-control-flow-forms file)))
        (list 'typedContractFacts
              (map parser-typed-contract-fact-snapshot
                   (source-file-typed-contract-facts file)))
        (list 'commentQualityFacts
              (map parser-comment-quality-fact-snapshot
                   (source-file-comment-quality-facts file)))
        (list 'calls
              (map parser-call-snapshot
                   (source-file-calls file)))))

;; Snapshot <- Definition
(def (parser-definition-snapshot defn)
  (list 'definition
        (list 'name (definition-name defn))
        (list 'kind (definition-kind defn))
        (list 'formals (snapshot-list (definition-formals defn)))
        (list 'arity (definition-arity defn))
        (list 'selector (definition-selector defn))))

;; Snapshot <- Fact
(def (parser-module-import-snapshot fact)
  (list 'moduleImport
        (list 'module (module-import-fact-module fact))
        (list 'phase (module-import-fact-phase fact))
        (list 'modifier (module-import-fact-modifier fact))
        (list 'symbols (snapshot-list (module-import-fact-symbols fact)))
        (list 'selector (module-import-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-module-export-snapshot fact)
  (list 'moduleExport
        (list 'name (module-export-fact-name fact))
        (list 'modifier (module-export-fact-modifier fact))
        (list 'alias (or (module-export-fact-alias fact) ""))
        (list 'module (or (module-export-fact-module fact) ""))
        (list 'symbols (snapshot-list (module-export-fact-symbols fact)))
        (list 'selector (module-export-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-macro-snapshot fact)
  (list 'macro
        (list 'name (macro-fact-name fact))
        (list 'kind (macro-fact-kind fact))
        (list 'transformer (macro-fact-transformer fact))
        (list 'phase (macro-fact-phase fact))
        (list 'patternCount (macro-fact-pattern-count fact))
        (list 'hygienicSyntax (macro-fact-hygienic fact))
        (list 'qualityFacets (snapshot-list (macro-fact-quality-facets fact)))
        (list 'selector (macro-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-binding-snapshot fact)
  (list 'binding
        (list 'name (binding-fact-name fact))
        (list 'kind (binding-fact-kind fact))
        (list 'scope (binding-fact-scope fact))
        (list 'valueType (or (binding-fact-value-type fact) "unknown"))
        (list 'selector (binding-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-poo-form-snapshot fact)
  (list 'pooForm
        (list 'name (poo-form-fact-name fact))
        (list 'kind (poo-form-fact-kind fact))
        (list 'role (poo-form-fact-role fact))
        (list 'generic (or (poo-form-fact-generic fact) ""))
        (list 'receiver (or (poo-form-fact-receiver fact) ""))
        (list 'receiverType (or (poo-form-fact-receiver-type fact) ""))
        (list 'supers (snapshot-list (poo-form-fact-supers fact)))
        (list 'slots (snapshot-list (poo-form-fact-slots fact)))
        (list 'options (snapshot-list (poo-form-fact-options fact)))
        (list 'specializers (snapshot-list (poo-form-fact-specializers fact)))
        (list 'specializerTypes (snapshot-list (poo-form-fact-specializer-types fact)))
        (list 'selector (poo-form-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-higher-order-form-snapshot fact)
  (list 'higherOrderForm
        (list 'name (higher-order-fact-name fact))
        (list 'kind (higher-order-fact-kind fact))
        (list 'role (higher-order-fact-role fact))
        (list 'operandCount (higher-order-fact-operand-count fact))
        (list 'arities (snapshot-list (higher-order-fact-arities fact)))
        (list 'formals (snapshot-list (higher-order-fact-formals fact)))
        (list 'caller (or (higher-order-fact-caller fact) ""))
        (list 'qualityFacets (snapshot-list (higher-order-quality-facets fact)))
        (list 'selector (higher-order-fact-selector fact))))

;; Snapshot <- Fact
(def (parser-control-flow-form-snapshot fact)
  (list 'controlFlowForm
        (list 'name (control-flow-fact-name fact))
        (list 'kind (control-flow-fact-kind fact))
        (list 'role (control-flow-fact-role fact))
        (list 'caller (or (control-flow-fact-caller fact) ""))
        (list 'bindingCount (control-flow-fact-binding-count fact))
        (list 'bodyFormCount (control-flow-fact-body-form-count fact))
        (list 'qualityFacets (snapshot-list (control-flow-quality-facets fact)))
        (list 'selector (control-flow-fact-selector fact))))

;; Snapshot <- TypedContractFact
(def (parser-typed-contract-fact-snapshot fact)
  (list 'typedContractFact
        (list 'definition (typed-contract-fact-definition-name fact))
        (list 'definitionKind (typed-contract-fact-definition-kind fact))
        (list 'definitionFormals (snapshot-list (typed-contract-fact-definition-formals fact)))
        (list 'definitionArity (typed-contract-fact-definition-arity fact))
        (list 'contract (typed-contract-fact-contract fact))
        (list 'contractOutput (typed-contract-fact-contract-output fact))
        (list 'contractInputs (snapshot-list (typed-contract-fact-contract-inputs fact)))
        (list 'contractInputCount (typed-contract-fact-contract-input-count fact))
        (list 'arityAlignment (typed-contract-fact-arity-alignment fact))
        (list 'tokens (snapshot-list (typed-contract-fact-tokens fact)))
        (list 'quality (typed-contract-fact-quality fact))
        (list 'reasons (snapshot-list (typed-contract-fact-reasons fact)))
        (list 'qualityFacets (snapshot-list (typed-contract-fact-quality-facets fact)))
        (list 'repairEvidence
              (parser-typed-contract-repair-evidence-snapshot
               (typed-contract-fact-repair-evidence fact)))
        (list 'arrowCount (typed-contract-fact-arrow-count fact))
        (list 'groupCount (typed-contract-fact-group-count fact))
        (list 'selector (typed-contract-fact-selector fact))))

;;; Repair evidence snapshots turn parser-owned hash packets into reader-safe data.
;;; Keep advice fields visible without leaking opaque table tokens into fixtures.
;; Snapshot <- Json
(def (parser-typed-contract-repair-evidence-snapshot evidence)
  (list 'repairEvidence
        (list 'factSource (hash-get evidence 'factSource))
        (list 'trigger (hash-get evidence 'trigger))
        (list 'definition (hash-get evidence 'definition))
        (list 'definitionKind (hash-get evidence 'definitionKind))
        (list 'definitionFormals
              (snapshot-list (hash-get evidence 'definitionFormals)))
        (list 'definitionArity (hash-get evidence 'definitionArity))
        (list 'path (hash-get evidence 'path))
        (list 'lineSpan (snapshot-list (hash-get evidence 'lineSpan)))
        (list 'selector (hash-get evidence 'selector))
        (list 'contract (hash-get evidence 'contract))
        (list 'quality (hash-get evidence 'quality))
        (list 'qualityFacets
              (snapshot-list (hash-get evidence 'qualityFacets)))
        (list 'matchedCalls
              (map parser-repair-call-snapshot
                   (hash-get evidence 'matchedCalls)))
        (list 'matchedHigherOrder
              (map parser-repair-higher-order-snapshot
                   (hash-get evidence 'matchedHigherOrder)))
        (list 'matchedControlFlow
              (map parser-repair-control-flow-snapshot
                   (hash-get evidence 'matchedControlFlow)))
        (list 'allowedMoves
              (snapshot-list (hash-get evidence 'allowedMoves)))
        (list 'forbiddenMoves
              (snapshot-list (hash-get evidence 'forbiddenMoves)))
        (list 'witnessNeeded
              (snapshot-list (hash-get evidence 'witnessNeeded)))
        (list 'agentRepairMode (hash-get evidence 'agentRepairMode))))

;; Snapshot <- Json
(def (parser-repair-call-snapshot evidence)
  (list 'repairCall
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'arity (hash-get evidence 'arity))
        (list 'selector (hash-get evidence 'selector))))

;; Snapshot <- Json
(def (parser-repair-higher-order-snapshot evidence)
  (list 'repairHigherOrder
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'role (hash-get evidence 'role))
        (list 'operandCount (hash-get evidence 'operandCount))
        (list 'selector (hash-get evidence 'selector))))

;; Snapshot <- Json
(def (parser-repair-control-flow-snapshot evidence)
  (list 'repairControlFlow
        (list 'kind (hash-get evidence 'kind))
        (list 'name (hash-get evidence 'name))
        (list 'role (hash-get evidence 'role))
        (list 'bindingCount (hash-get evidence 'bindingCount))
        (list 'bodyFormCount (hash-get evidence 'bodyFormCount))
        (list 'selector (hash-get evidence 'selector))))

;; Snapshot <- CommentQualityFact
(def (parser-comment-quality-fact-snapshot fact)
  (list 'commentQualityFact
        (list 'targetKind (comment-quality-fact-target-kind fact))
        (list 'targetName (comment-quality-fact-target-name fact))
        (list 'context (comment-quality-fact-context fact))
        (list 'commentKind (comment-quality-fact-comment-kind fact))
        (list 'quality (comment-quality-fact-quality fact))
        (list 'required (comment-quality-fact-required fact))
        (list 'reasons (snapshot-list (comment-quality-fact-reasons fact)))
        (list 'commentLines (snapshot-list (comment-quality-fact-comment-lines fact)))
        (list 'targetStart (comment-quality-fact-target-start fact))
        (list 'targetEnd (comment-quality-fact-target-end fact))
        (list 'parserEvidence
              (parser-comment-quality-evidence-snapshot
               (comment-quality-fact-evidence fact)))
        (list 'selector (comment-quality-fact-selector fact))))

;;; Snapshot boundary: serialize comment evidence in fixed field order so parser fact changes are reviewable across runs.
;; Snapshot <- Json
(def (parser-comment-quality-evidence-snapshot evidence)
  (let (target-kind (hash-get evidence 'targetKind))
    (if (equal? target-kind "module")
      (list 'commentEvidence
            (list 'factSource (hash-get evidence 'factSource))
            (list 'targetKind target-kind)
            (list 'path (hash-get evidence 'path))
            (list 'lineCount (hash-get evidence 'lineCount))
            (list 'existingCommentLineCount
                  (hash-get evidence 'existingCommentLineCount))
            (list 'commentFocus (hash-get evidence 'commentFocus))
            (list 'commentQuestions
                  (snapshot-list (hash-get evidence 'commentQuestions)))
            (list 'agentRepairMode (hash-get evidence 'agentRepairMode)))
      (list 'commentEvidence
            (list 'factSource (hash-get evidence 'factSource))
            (list 'targetKind target-kind)
            (list 'definition (hash-get evidence 'definition))
            (list 'definitionKind (hash-get evidence 'definitionKind))
            (list 'definitionFormals
                  (snapshot-list (hash-get evidence 'definitionFormals)))
            (list 'definitionArity (hash-get evidence 'definitionArity))
            (list 'lineSpan (hash-get evidence 'lineSpan))
            (list 'context (hash-get evidence 'context))
            (list 'existingCommentLineCount
                  (hash-get evidence 'existingCommentLineCount))
            (list 'matchedFactCount (hash-get evidence 'matchedFactCount))
            (list 'matchedFacts
                  (map parser-comment-quality-matched-fact-snapshot
                       (hash-get evidence 'matchedFacts)))
            (list 'commentFocus (hash-get evidence 'commentFocus))
            (list 'commentQuestions
                  (snapshot-list (hash-get evidence 'commentQuestions)))
            (list 'agentRepairMode (hash-get evidence 'agentRepairMode))
            (list 'selector (hash-get evidence 'selector))))))

;;; Matched fact snapshots mirror evidence variants while preserving type-specific witness fields and deterministic output order.
;; Snapshot <- Json
(def (parser-comment-quality-matched-fact-snapshot fact)
  (let (fact-kind (hash-get fact 'factKind))
    (cond
     ((equal? fact-kind "macro")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'transformer (hash-get fact 'transformer))
            (list 'phase (hash-get fact 'phase))
            (list 'patternCount (hash-get fact 'patternCount))
            (list 'hygienicSyntax (hash-get fact 'hygienicSyntax))
            (list 'qualityFacets
                  (snapshot-list (hash-get fact 'qualityFacets)))
            (list 'selector (hash-get fact 'selector))))
     ((equal? fact-kind "poo")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'generic (hash-get fact 'generic))
            (list 'receiver (hash-get fact 'receiver))
            (list 'receiverType (hash-get fact 'receiverType))
            (list 'supers (snapshot-list (hash-get fact 'supers)))
            (list 'slots (snapshot-list (hash-get fact 'slots)))
            (list 'specializers (snapshot-list (hash-get fact 'specializers)))
            (list 'specializerTypes
                  (snapshot-list (hash-get fact 'specializerTypes)))
            (list 'selector (hash-get fact 'selector))))
     ((equal? fact-kind "higher-order")
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'operandCount (hash-get fact 'operandCount))
            (list 'arities (snapshot-list (hash-get fact 'arities)))
            (list 'formals (snapshot-list (hash-get fact 'formals)))
            (list 'caller (hash-get fact 'caller))
            (list 'selector (hash-get fact 'selector))))
     (else
      (list 'matchedFact
            (list 'factKind fact-kind)
            (list 'name (hash-get fact 'name))
            (list 'formKind (hash-get fact 'formKind))
            (list 'role (hash-get fact 'role))
            (list 'caller (hash-get fact 'caller))
            (list 'bindingCount (hash-get fact 'bindingCount))
            (list 'bodyFormCount (hash-get fact 'bodyFormCount))
            (list 'selector (hash-get fact 'selector)))))))
;;; Boundary:
;;; - parser-call-snapshot composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- Fact
(def (parser-call-snapshot fact)
  (list 'call
        (list 'callee (call-fact-callee fact))
        (list 'arity (call-fact-arity fact))
        (list 'caller (or (call-fact-caller fact) ""))
        (list 'arguments (snapshot-list (call-fact-arguments fact)))
        (list 'argumentTypes
              (snapshot-list
               (map (lambda (type) (or type "unknown"))
                    (call-fact-argument-types fact))))
        (list 'selector (call-fact-selector fact))))
