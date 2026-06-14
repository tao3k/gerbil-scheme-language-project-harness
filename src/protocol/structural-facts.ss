;;; -*- Gerbil -*-
;;; Native syntax fact rows for the structural index packet.

(import :parser/facade
        :std/sort
        :std/sugar
        :support/list)

(export structural-syntax-fact-json)
;;; Boundary:
;;; - structural-syntax-fact-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Json <- SourceFile
(def (structural-syntax-fact-json file)
  (stable-structural-facts
   (append
    (map module-import-structural-fact-json (source-file-module-imports file))
    (map module-export-structural-fact-json (source-file-module-exports file))
    (map macro-structural-fact-json (source-file-macros file))
    (map binding-structural-fact-json (source-file-bindings file))
    (map poo-form-structural-fact-json (source-file-poo-forms file))
    (map higher-order-structural-fact-json
         (source-file-higher-order-forms file))
    (map control-flow-structural-fact-json
         (source-file-control-flow-forms file))
    (map typed-contract-structural-fact-json
         (source-file-typed-contract-facts file))
    (map comment-quality-structural-fact-json
         (source-file-comment-quality-facts file))
    (map call-structural-fact-json (source-file-calls file)))))
;;; Boundary:
;;; - stable-structural-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List StructuralFactJson) <- (List StructuralFactJson)
(def (stable-structural-facts facts)
  (sort facts
        (lambda (a b)
          (string<? (hash-get a 'id) (hash-get b 'id)))))
;; Json <- Fact
(def (module-import-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "import" (module-import-fact-path fact)
                                   (module-import-fact-module fact)
                                   (module-import-fact-start fact)))
        (kind "import")
        (source "native-parser")
        (languageKind "module-import")
        (name (module-import-fact-module fact))
        (ownerPath (module-import-fact-path fact))
        (location (fact-location-json (module-import-fact-path fact)
                                      (module-import-fact-start fact)
                                      (module-import-fact-end fact)))
        (queryKeys (dedupe [(module-import-fact-module fact)
                            (module-import-fact-modifier fact)
                            (module-import-fact-phase fact)
                            (module-import-fact-path fact)]))
        (fields (hash (phase (module-import-fact-phase fact))
                      (modifier (module-import-fact-modifier fact))
                      (symbols (module-import-fact-symbols fact))
                      (alias (or (module-import-fact-alias fact) ""))))))
;; Json <- Fact
(def (module-export-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "export" (module-export-fact-path fact)
                                   (module-export-fact-name fact)
                                   (module-export-fact-start fact)))
        (kind "export")
        (source "native-parser")
        (languageKind "module-export")
        (name (module-export-fact-name fact))
        (ownerPath (module-export-fact-path fact))
        (location (fact-location-json (module-export-fact-path fact)
                                      (module-export-fact-start fact)
                                      (module-export-fact-end fact)))
        (queryKeys (module-export-query-keys fact))
        (fields (hash (modifier (module-export-fact-modifier fact))
                      (symbols (module-export-fact-symbols fact))
                      (alias (or (module-export-fact-alias fact) ""))
                      (module (or (module-export-fact-module fact) ""))))))
;;; Boundary:
;;; - Export query keys expose direct symbols, wrapper modifiers, aliases, and module re-export refs.
;;; - This lets search distinguish public API declarations from generic top-level symbol mentions.
;; (List QueryKey) <- Fact
(def (module-export-query-keys fact)
  (dedupe
   (filter identity
           (append [(module-export-fact-name fact)
                    (module-export-fact-modifier fact)
                    (module-export-fact-alias fact)
                    (module-export-fact-module fact)
                    (module-export-fact-path fact)
                    "export"
                    "module-export"]
                   (module-export-fact-symbols fact)))))
;; Json <- Fact
(def (macro-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "macro" (macro-fact-path fact)
                                   (macro-fact-name fact)
                                   (macro-fact-start fact)))
        (kind "macro")
        (source "native-parser")
        (languageKind (macro-fact-kind fact))
        (name (macro-fact-name fact))
        (ownerPath (macro-fact-path fact))
        (location (fact-location-json (macro-fact-path fact)
                                      (macro-fact-start fact)
                                      (macro-fact-end fact)))
        (queryKeys (dedupe (append [(macro-fact-name fact)
                                    (macro-fact-kind fact)
                                    (macro-fact-transformer fact)
                                    (macro-fact-path fact)]
                                   (macro-fact-quality-facets fact))))
        (fields (hash (transformer (macro-fact-transformer fact))
                      (phase (macro-fact-phase fact))
                      (patternCount (macro-fact-pattern-count fact))
                      (hygienicSyntax (macro-fact-hygienic fact))
                      (qualityFacets (macro-fact-quality-facets fact))))))
;; Json <- Fact
(def (binding-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "binding" (binding-fact-path fact)
                                   (binding-fact-name fact)
                                   (binding-fact-start fact)))
        (kind "binding")
        (source "native-parser")
        (languageKind (binding-fact-kind fact))
        (name (binding-fact-name fact))
        (ownerPath (binding-fact-path fact))
        (location (fact-location-json (binding-fact-path fact)
                                      (binding-fact-start fact)
                                      (binding-fact-end fact)))
        (queryKeys (dedupe [(binding-fact-name fact)
                            (binding-fact-kind fact)
                            (binding-fact-scope fact)
                            (binding-fact-path fact)]))
        (fields (hash (scope (binding-fact-scope fact))
                      (valueType (or (binding-fact-value-type fact) ""))))))
;; Json <- Fact
(def (poo-form-structural-fact-json fact)
  (hash (id (native-syntax-fact-id (poo-form-fact-role fact)
                                   (poo-form-fact-path fact)
                                   (poo-form-fact-name fact)
                                   (poo-form-fact-start fact)))
        (kind (poo-form-structural-kind fact))
        (source "native-parser")
        (languageKind (poo-form-fact-kind fact))
        (name (poo-form-fact-name fact))
        (ownerPath (poo-form-fact-path fact))
        (location (fact-location-json (poo-form-fact-path fact)
                                      (poo-form-fact-start fact)
                                      (poo-form-fact-end fact)))
        (queryKeys (poo-form-query-keys fact))
        (fields (poo-form-fields-json fact))))
;; StructuralKind <- PooFormFact
(def (poo-form-structural-kind fact)
  (cond
   ((equal? (poo-form-fact-role fact) "class") "class")
   ((equal? (poo-form-fact-role fact) "generic") "function")
   ((equal? (poo-form-fact-role fact) "method") "method")
   ((equal? (poo-form-fact-role fact) "protocol") "interface")
   (else "custom")))
;;; Boundary:
;;; - poo-form-query-keys composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PooFormQueryKeys <- Fact
(def (poo-form-query-keys fact)
  (dedupe
   (filter identity
           (append [(poo-form-fact-name fact)
                    (poo-form-fact-kind fact)
                    (poo-form-fact-role fact)
                    (poo-form-fact-path fact)
                    (poo-form-fact-generic fact)
                    (poo-form-fact-receiver fact)
                   (poo-form-fact-receiver-type fact)]
                   (poo-form-fact-supers fact)
                   (poo-form-fact-slots fact)
                   (poo-form-fact-options fact)
                   (poo-form-fact-specializers fact)
                   (poo-form-fact-specializer-types fact)))))
;; Json <- Fact
(def (poo-form-fields-json fact)
  (hash (role (poo-form-fact-role fact))
        (generic (or (poo-form-fact-generic fact) ""))
        (receiver (or (poo-form-fact-receiver fact) ""))
        (receiverType (or (poo-form-fact-receiver-type fact) ""))
        (supers (poo-form-fact-supers fact))
        (slots (poo-form-fact-slots fact))
        (options (poo-form-fact-options fact))
        (specializers (poo-form-fact-specializers fact))
        (specializerTypes (poo-form-fact-specializer-types fact))
        (dispatchArity (length (poo-form-fact-specializer-types fact)))))
;; Json <- Fact
(def (higher-order-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "higher-order"
                                   (higher-order-fact-path fact)
                                   (higher-order-fact-name fact)
                                   (higher-order-fact-start fact)))
        (kind (higher-order-structural-kind fact))
        (source "native-parser")
        (languageKind (higher-order-fact-kind fact))
        (name (higher-order-fact-name fact))
        (ownerPath (higher-order-fact-path fact))
        (location (fact-location-json (higher-order-fact-path fact)
                                      (higher-order-fact-start fact)
                                      (higher-order-fact-end fact)))
        (queryKeys (higher-order-query-keys fact))
        (fields (higher-order-fields-json fact))))
;; StructuralKind <- HigherOrderFact
(def (higher-order-structural-kind fact)
  (if (member (higher-order-fact-role fact)
              '("anonymous-function" "multi-arity-function"))
    "function"
    "call"))
;;; Boundary:
;;; - higher-order-query-keys composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List HigherOrderFact) <- Fact
(def (higher-order-query-keys fact)
  (dedupe
   (filter identity
           (append [(higher-order-fact-name fact)
                    (higher-order-fact-kind fact)
                    (higher-order-fact-role fact)
                    (higher-order-fact-caller fact)
                    (higher-order-fact-path fact)]
                   (higher-order-quality-facets fact)
                   (higher-order-fact-formals fact)))))
;; Json <- Fact
(def (higher-order-fields-json fact)
  (hash (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (arities (higher-order-fact-arities fact))
        (formals (higher-order-fact-formals fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (qualityFacets (higher-order-quality-facets fact))))

;; Json <- ControlFlowFact
(def (control-flow-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "control-flow"
                                   (control-flow-fact-path fact)
                                   (control-flow-fact-name fact)
                                   (control-flow-fact-start fact)))
        (kind "custom")
        (source "native-parser")
        (languageKind (control-flow-fact-kind fact))
        (name (control-flow-fact-name fact))
        (ownerPath (control-flow-fact-path fact))
        (location (fact-location-json (control-flow-fact-path fact)
                                      (control-flow-fact-start fact)
                                      (control-flow-fact-end fact)))
        (queryKeys (control-flow-query-keys fact))
        (fields (control-flow-fields-json fact))))
;;; Boundary:
;;; - control-flow-query-keys composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List ControlFlowFact) <- ControlFlowFact
(def (control-flow-query-keys fact)
  (dedupe
   (filter identity
           (append [(control-flow-fact-name fact)
                    (control-flow-fact-kind fact)
                    (control-flow-fact-role fact)
                    (control-flow-fact-caller fact)
                    (control-flow-fact-path fact)
                    "control-flow"]
                   (control-flow-quality-facets fact)))))
;; Json <- ControlFlowFact
(def (control-flow-fields-json fact)
  (hash (role (control-flow-fact-role fact))
        (caller (or (control-flow-fact-caller fact) ""))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (qualityFacets (control-flow-quality-facets fact))))
;; Json <- TypedContractFact
(def (typed-contract-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "typed-contract"
                                   (typed-contract-fact-path fact)
                                   (typed-contract-fact-definition-name fact)
                                   (typed-contract-fact-comment-start fact)))
        (kind "comment")
        (source "native-parser")
        (languageKind "typed-combinator-contract")
        (name (typed-contract-fact-definition-name fact))
        (ownerPath (typed-contract-fact-path fact))
        (location (fact-location-json (typed-contract-fact-path fact)
                                      (typed-contract-fact-comment-start fact)
                                      (typed-contract-fact-comment-end fact)))
        (queryKeys (typed-contract-query-keys fact))
        (fields (typed-contract-fields-json fact))))
;;; Boundary:
;;; - typed-contract-query-keys composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; TypedContractQueryKeys <- TypedContractFact
(def (typed-contract-query-keys fact)
  (dedupe
   (filter identity
           (append [(typed-contract-fact-definition-name fact)
                    (typed-contract-fact-definition-kind fact)
                    (typed-contract-fact-contract fact)
                    (typed-contract-fact-contract-output fact)
                    (typed-contract-fact-quality fact)
                    (typed-contract-fact-arity-alignment fact)
                    (typed-contract-fact-path fact)
                    "typed-combinator-style"
                    "typed-contract"]
                   (typed-contract-fact-definition-formals fact)
                   (typed-contract-fact-contract-inputs fact)
                   (typed-contract-fact-tokens fact)
                   (typed-contract-fact-reasons fact)
                   (typed-contract-fact-quality-facets fact)))))
;; Json <- TypedContractFact
(def (typed-contract-fields-json fact)
  (hash (role "typed-combinator-style")
        (definitionKind (typed-contract-fact-definition-kind fact))
        (definitionFormals (typed-contract-fact-definition-formals fact))
        (definitionArity (typed-contract-fact-definition-arity fact))
        (contract (typed-contract-fact-contract fact))
        (contractOutput (typed-contract-fact-contract-output fact))
        (contractInputs (typed-contract-fact-contract-inputs fact))
        (contractInputCount (typed-contract-fact-contract-input-count fact))
        (arityAlignment (typed-contract-fact-arity-alignment fact))
        (tokens (typed-contract-fact-tokens fact))
        (quality (typed-contract-fact-quality fact))
        (reasons (typed-contract-fact-reasons fact))
        (qualityFacets (typed-contract-fact-quality-facets fact))
        (repairEvidence (typed-contract-fact-repair-evidence fact))
        (arrowCount (typed-contract-fact-arrow-count fact))
        (groupCount (typed-contract-fact-group-count fact))
        (definitionStart (typed-contract-fact-definition-start fact))
        (definitionEnd (typed-contract-fact-definition-end fact))))

;; Json <- CommentQualityFact
(def (comment-quality-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "comment-quality"
                                   (comment-quality-fact-path fact)
                                   (comment-quality-fact-target-name fact)
                                   (comment-quality-fact-comment-start fact)))
        (kind "comment")
        (source "native-parser")
        (languageKind "engineering-comment-quality")
        (name (comment-quality-fact-target-name fact))
        (ownerPath (comment-quality-fact-path fact))
        (location (fact-location-json (comment-quality-fact-path fact)
                                      (comment-quality-fact-comment-start fact)
                                      (comment-quality-fact-comment-end fact)))
        (queryKeys (comment-quality-query-keys fact))
        (fields (comment-quality-fields-json fact))))

;;; Boundary:
;;; - comment-quality-query-keys composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List QueryKey) <- CommentQualityFact
(def (comment-quality-query-keys fact)
  (dedupe
   (filter identity
           (append [(comment-quality-fact-target-name fact)
                    (comment-quality-fact-target-kind fact)
                    (comment-quality-fact-context fact)
                    (comment-quality-fact-comment-kind fact)
                    (comment-quality-fact-quality fact)
                    (comment-quality-fact-path fact)
                    "engineering-comment"
                    "comment-quality"]
                   (comment-quality-fact-reasons fact)
                   (comment-quality-evidence-query-keys
                    (comment-quality-fact-evidence fact))))))

;;; Search boundary: index comment focus, repair mode, questions, and matched witness terms so R015 repairs can be found without source dumps.
;; (List QueryKey) <- Json
(def (comment-quality-evidence-query-keys evidence)
  (append [(hash-get evidence 'commentFocus)
           (hash-get evidence 'agentRepairMode)]
          (hash-get evidence 'commentQuestions)
          (apply append
                 (map comment-quality-matched-fact-query-keys
                      (hash-get evidence 'matchedFacts)))))

;;; Structural query keys mirror matched fact variants and emit only stable parser-owned fields for compact search projection.
;; (List QueryKey) <- Json
(def (comment-quality-matched-fact-query-keys fact)
  (let (fact-kind (hash-get fact 'factKind))
    (cond
     ((equal? fact-kind "macro")
      [(hash-get fact 'factKind)
       (hash-get fact 'name)
       (hash-get fact 'formKind)
       (hash-get fact 'transformer)
       (hash-get fact 'phase)
       (hash-get fact 'selector)])
     ((equal? fact-kind "poo")
      (append [(hash-get fact 'factKind)
               (hash-get fact 'name)
               (hash-get fact 'formKind)
               (hash-get fact 'role)
               (hash-get fact 'generic)
               (hash-get fact 'receiver)
               (hash-get fact 'receiverType)
               (hash-get fact 'selector)]
              (hash-get fact 'supers)
              (hash-get fact 'slots)
              (hash-get fact 'specializers)
              (hash-get fact 'specializerTypes)))
     ((equal? fact-kind "higher-order")
      (append [(hash-get fact 'factKind)
               (hash-get fact 'name)
               (hash-get fact 'formKind)
               (hash-get fact 'role)
               (hash-get fact 'caller)
               (hash-get fact 'selector)]
              (hash-get fact 'formals)))
     (else
      [(hash-get fact 'factKind)
       (hash-get fact 'name)
       (hash-get fact 'formKind)
       (hash-get fact 'role)
       (hash-get fact 'caller)
       (hash-get fact 'selector)]))))

;; Json <- CommentQualityFact
(def (comment-quality-fields-json fact)
  (hash (role "engineering-comment-quality")
        (targetKind (comment-quality-fact-target-kind fact))
        (context (comment-quality-fact-context fact))
        (commentKind (comment-quality-fact-comment-kind fact))
        (quality (comment-quality-fact-quality fact))
        (required (comment-quality-fact-required fact))
        (reasons (comment-quality-fact-reasons fact))
        (evidence (comment-quality-fact-evidence fact))
        (commentLines (comment-quality-fact-comment-lines fact))
        (targetStart (comment-quality-fact-target-start fact))
        (targetEnd (comment-quality-fact-target-end fact))))
;;; Boundary:
;;; - call-structural-fact-json composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Json <- Fact
(def (call-structural-fact-json fact)
  (hash (id (native-syntax-fact-id "call" (call-fact-path fact)
                                   (call-fact-callee fact)
                                   (call-fact-start fact)))
        (kind "call")
        (source "native-parser")
        (languageKind "call")
        (name (call-fact-callee fact))
        (ownerPath (call-fact-path fact))
        (location (fact-location-json (call-fact-path fact)
                                      (call-fact-start fact)
                                      (call-fact-end fact)))
        (queryKeys (dedupe [(call-fact-callee fact)
                            (or (call-fact-caller fact) "")
                            (call-fact-path fact)]))
        (fields (hash (arity (call-fact-arity fact))
                      (caller (or (call-fact-caller fact) ""))
                      (arguments (call-fact-arguments fact))
                      (argumentTypes
                       (map (lambda (type) (or type "unknown"))
                            (call-fact-argument-types fact)))))))
;; Json <- String Integer Integer
(def (fact-location-json path start end)
  (hash (path path)
        (lineRange (string-append (number->string start)
                                  ":"
                                  (number->string end)))))
;; String <- String String String Integer
(def (native-syntax-fact-id kind path name start)
  (string-append kind ":"
                 path ":"
                 (number->string start) ":"
                 name))
