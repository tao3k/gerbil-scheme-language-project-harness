;;; -*- Gerbil -*-
;;; Agent-facing style policy checks.

(import :parser/facade
        :policy/agent-style-steering
        :policy/agent-style-gerbil-signals
        :policy/agent-style-destructuring-signals
        :policy/agent-style-docs
        :policy/agent-style-performance-signals
        :policy/gerbil-utils-source
        :policy/agent-support
        :policy/agent-style-shape
        :policy/model
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-empty? string-prefix?)
        (only-in :std/srfi/1 take)
        (only-in :std/sugar cut filter filter-map foldl hash hash-get ormap)
        :types/findings)

(export typed-combinator-style-findings
        typed-combinator-style-finding
        controlled-branch-shape-findings
        controlled-branch-shape-finding
        predicate-family-combinator-findings
        predicate-family-combinator-finding)
;; (List String)
(def +typed-combinator-style-higher-order-roles+
  '("partial-application" "function-curry" "function-composition"
    "pipeline-composition" "higher-order-combinator"
    "anonymous-function" "named-lambda-abstraction"
    "eta-wrapper-lambda"
    "lambda-match-opportunity" "pattern-matching-function"
    "multi-arity-function" "autocurry-semantics"
    "sequence-map" "sequence-filter" "sequence-filter-map"
    "sequence-append-map" "sequence-predicate" "sequence-search"
    "sequence-fold" "loop-fold" "list-builder"))
;; (List String)
(def +typed-combinator-style-call-heads+
  '("!>" "!!>" "left-to-right" "rcompose" "compose" "compose1"
    "fun" "lambda-match" "λ" "λ-match"
    "match" "match*" "with" "with*" "ast-case"
    "curry" "rcurry" "cut" "cute" "chain" "if-let" "when-let"
    "map" "filter" "filter-map"
    "append-map" "fold" "foldl" "foldr" "fold-left" "fold-right"
    "andmap" "ormap" "every" "any" "find" "list-index"
    "with-list-builder"
    "generating-map" "generating-fold" "generating-filter"
    "generating-partition" "generating-merge" "generating<-list"
    "generating<-cothread"))
;; (List String)
(def +poo-declarative-definition-kinds+
  '(".def" "define-type" "defclass" ".defclass" "defmethod" ".defmethod"
    "defgeneric" ".defgeneric" "defprotocol" ".defprotocol"))

;; : Nat
(def +typed-combinator-style-file-evidence-floor+ 5)
;;; Entry boundary: emit at most one typed-combinator finding per owner so repair stays file-scoped.
;; : (-> ProjectIndex (List TypeFinding) )
(def (typed-combinator-style-findings index)
  (filter-map (cut typed-combinator-style-finding index <>)
              (project-index-files index)))
;;; Policy gate: combine typed contracts, parser-owned implementation evidence, and coverage before repair.
;; : (-> ProjectIndex SourceFile TypeFinding )
(def (typed-combinator-style-finding index file)
  (and (source-file-path file)
       (typed-combinator-style-source-file? index file)
       (pair? (source-file-definitions file))
       (let* ((definition-count (length (source-file-definitions file)))
              (function-definitions
               (typed-combinator-style-function-definitions file))
              (function-definition-count
               (length function-definitions))
              (typed-comment-summary
               (file-typed-combinator-style-summary index file))
              (typed-comment-line-count (car typed-comment-summary))
              (valid-typed-comment-count (cadr typed-comment-summary))
              (invalid-typed-comment-count (caddr typed-comment-summary))
              (missing-count
               (typed-combinator-style-missing-count function-definition-count
                                                     valid-typed-comment-count))
              (implementation-evidence
               (typed-combinator-style-implementation-evidence file))
              (implementation-evidence-count
               (length implementation-evidence))
              (quality-facets
               (typed-combinator-style-quality-facets file))
              (repair-evidence
               (typed-combinator-style-repair-evidence file))
              (typed-doc-missing-targets
               (typed-combinator-style-missing-doc-targets file))
              (typed-doc-missing?
               (pair? typed-doc-missing-targets))
              (quality-repair-triggered?
               (and (typed-combinator-style-quality-repair-source-file? file)
                    (typed-combinator-style-quality-repair-triggered?
                     file quality-facets)))
              (module-engineering-comment?
               (source-file-has-engineering-module-comment? file))
              (implementation-evidence-callers
               (typed-combinator-style-evidence-callers implementation-evidence))
              (covered-definition-names
               (typed-combinator-style-covered-definition-names
                file implementation-evidence-callers))
              (covered-definition-count
               (length covered-definition-names))
              (minimum-covered-definition-count
               (typed-combinator-style-minimum-covered-definition-count
                function-definition-count))
              (uncovered-definition-names
               (typed-combinator-style-uncovered-definition-names
                file implementation-evidence-callers))
              (missing-implementation-evidence?
               (typed-combinator-style-missing-implementation-evidence?
                function-definition-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                implementation-evidence-count
                module-engineering-comment?))
              (implementation-coverage-insufficient?
               (typed-combinator-style-implementation-coverage-insufficient?
                function-definition-count
                covered-definition-count
                minimum-covered-definition-count
                implementation-evidence-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                module-engineering-comment?)))
         (and (ormap (lambda (triggered?) triggered?)
                     [(> missing-count 0)
                      (> invalid-typed-comment-count 0)
                      missing-implementation-evidence?
                      implementation-coverage-insufficient?
                      typed-doc-missing?
                      quality-repair-triggered?])
              (make-type-finding
               (policy-rule-id +agent-typed-combinator-style-rule+)
               (policy-rule-severity +agent-typed-combinator-style-rule+)
               (source-file-path file)
               (typed-combinator-style-message definition-count
                                               valid-typed-comment-count
                                               invalid-typed-comment-count
                                               missing-implementation-evidence?
                                               implementation-coverage-insufficient?
                                               typed-doc-missing?
                                               quality-repair-triggered?
                                               (length typed-doc-missing-targets)
                                               covered-definition-count
                                               function-definition-count
                                               minimum-covered-definition-count)
               (source-file-path file)
               (typed-combinator-style-details
                file
                definition-count
                typed-comment-line-count
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                implementation-evidence
                implementation-evidence-count
                missing-implementation-evidence?
                implementation-evidence-callers
                covered-definition-names
                covered-definition-count
                function-definition-count
                minimum-covered-definition-count
                uncovered-definition-names
                implementation-coverage-insufficient?
                typed-doc-missing-targets
                quality-facets
                repair-evidence
                typed-doc-missing?
                quality-repair-triggered?))))))

;;; Repair payload: keep agent-facing fields bounded while preserving enough evidence to edit safely.
;; : (-> SourceFile Nat Nat Nat Nat Nat Evidence Nat Boolean Coverage QualityFacets RepairEvidence Boolean PolicyDetails )
(def (typed-combinator-style-details file definition-count typed-comment-line-count valid-typed-comment-count invalid-typed-comment-count missing-count implementation-evidence implementation-evidence-count missing-implementation-evidence? implementation-evidence-callers covered-definition-names covered-definition-count function-definition-count minimum-covered-definition-count uncovered-definition-names implementation-coverage-insufficient? typed-doc-missing-targets quality-facets repair-evidence typed-doc-missing? quality-repair-triggered?)
  (hash (styleGuide "typed-combinator-style")
        (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
        (expectedCommentPrefix ";;")
        (expectedCommentShape "adjacent Gerbil contract projection block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
        (signatureShape "adjacent Gerbil contract/signature projection using ;; : (forall (a) (-> Input Output)), optional ;; | type aliases, U unions, Values, and Refine predicates")
        (expectedDocShape "full form for role/facet risk boundaries: leading name matching the definition, ;;   : signature, optional ;;   | type/contract/requires/warning/rationale fields, and ;;   | doc m% with # Examples fenced Scheme input/result")
        (typedDocRequiredWhen "arity-bearing macro/protocol/driver roles, or exported helpers that also carry parser-owned risk facets such as macro-runtime-source-witness, poo-protocol-evidence, or loop-driver-classified")
        (typedCommentMetadataFields +typed-comment-metadata-fields+)
        (runtimeWitnessPolicy
         "use | contract for runtime predicate evidence, | requires for named preconditions, and | warning/| rationale only with concrete parser-visible witness")
        (typedDocMissing typed-doc-missing?)
        (typedDocMissingCount (length typed-doc-missing-targets))
        (typedDocMissingTargets
         (take typed-doc-missing-targets
               (min 12 (length typed-doc-missing-targets))))
        (contractLinePolicy "multi-line typed-combinator-style contracts are allowed when needed to preserve precision")
        (compositionShape "Gerbil-native expression shape; prefer lambda-match/match for shape dispatch, cut/curry/rcurry for specialization, case-lambda for real arity boundaries, values/call-with-values for tuple projection, and map/filter/filter-map/fold/andmap/ormap for sequence transforms")
        (qualityReferenceCorpus "gerbil-reference-corpus")
        (qualityReference
         (typed-combinator-style-quality-reference-details
          file
          quality-facets))
        (functionShape "single-purpose expression-returning helper; one visible data-flow shape per function")
        (agentRepairStandard "rewrite toward learned Gerbil/Gambit style: small algebraic helpers, lambda-match/match where shape is the boundary, cut/curry/case-lambda for specialization, values for tuple protocols, and minimal let*/mutation scaffolding")
        (expressionLevelRewrite "extract predicate/mapper/reducer helpers, then compose with lambda-match/match/cut/curry/case-lambda/values/filter-map/map/fold/andmap/ormap when behavior fits")
        (antiPattern "basic Scheme scaffolding: procedural let* pipeline, broad named-let accumulator, repeated car/cdr/list-ref projection, or nested conditional body when a Gerbil-native helper, match, selector, or combinator would expose the data flow")
        (passiveRepairFlow "policy-finding -> agentRepair -> guide-code -> bounded edit")
        (implementationEvidenceCount implementation-evidence-count)
        (implementationEvidence
         (take implementation-evidence
               (min 5 (length implementation-evidence))))
        (missingImplementationEvidence missing-implementation-evidence?)
        (implementationEvidenceCallers
         (take implementation-evidence-callers
               (min 8 (length implementation-evidence-callers))))
        (coveredDefinitionCount covered-definition-count)
        (coveredDefinitions
         (take covered-definition-names
               (min 8 (length covered-definition-names))))
        (functionDefinitionCount function-definition-count)
        (minimumCoveredDefinitionCount minimum-covered-definition-count)
        (uncoveredDefinitionCount (length uncovered-definition-names))
        (uncoveredDefinitions
         (take uncovered-definition-names
               (min 8 (length uncovered-definition-names))))
        (implementationCoverageInsufficient
         implementation-coverage-insufficient?)
        (minimumImplementationCoverage
         "at least two thirds of arity-bearing definitions must have parser-owned Gerbil-native idiom evidence")
        (gerbilNativeIdiomPriority
         ["lambda-match/match at destructuring boundaries"
          "with/with* for local destructuring boundaries"
          "alet/alet* for dependent maybe-value chains"
          "case for closed symbolic/datum dispatch"
          "ast-case/syntax-case only for real syntax-object or AST owners"
          "cut/curry/rcurry for partial application"
          "case-lambda only for real arity specialization"
          "values/call-with-values instead of anonymous vector/list tuple protocols"
          "map/filter/filter-map/fold/andmap/ormap for sequence transforms"
          "parameterize/dynamic-wind when control state or cleanup is the boundary"])
        (gerbilUtilsImplementationSignals +gerbil-utils-implementation-signals+)
        (generatorCombinatorSignals
         (typed-combinator-style-generator-combinator-signals file))
        (generatorContractTargets
         (typed-combinator-style-generator-contract-targets file))
        (serializationBoundarySignals
         (typed-combinator-style-serialization-boundary-signals file))
        (serializationBoundaryTargets
         (typed-combinator-style-serialization-boundary-targets file))
        (antiAiScaffoldSignals
         (typed-combinator-style-anti-ai-scaffold-signals file))
        (antiAiScaffoldTargets
         (typed-combinator-style-anti-ai-scaffold-targets file))
        (listCombinatorBoundarySignals
         (typed-combinator-style-list-combinator-signals file))
        (listCombinatorBoundaryTargets
         (typed-combinator-style-list-combinator-targets file))
        (gerbilUpstreamIdiomSignals
         (typed-combinator-style-gerbil-upstream-idiom-signals file))
        (gerbilUpstreamIdiomTargets
         (typed-combinator-style-gerbil-upstream-idiom-targets file))
        (stdSugarFlowBoundarySignals
         (typed-combinator-style-std-sugar-flow-signals file))
        (stdSugarFlowBoundaryTargets
         (typed-combinator-style-std-sugar-flow-targets file))
        (loopDriverCombinatorSignals
         (typed-combinator-style-loop-driver-signals file))
        (loopDriverCombinatorTargets
         (typed-combinator-style-loop-driver-targets file))
        (destructuringBoundarySignals
         (typed-combinator-style-destructuring-signals file))
        (destructuringBoundaryTargets
         (typed-combinator-style-destructuring-targets file))
        (slotLensBoundarySignals
         (typed-combinator-style-slot-lens-boundary-signals file))
        (slotLensBoundaryTargets
         (typed-combinator-style-slot-lens-boundary-targets file))
        (concurrencyControlBoundarySignals
         (typed-combinator-style-concurrency-control-signals file))
        (concurrencyControlBoundaryTargets
         (typed-combinator-style-concurrency-control-targets file))
        (ssxiOptimizerMetadataBoundarySignals
         (typed-combinator-style-ssxi-optimizer-metadata-boundary-signals
          file))
        (ssxiOptimizerMetadataBoundaryTargets
         (typed-combinator-style-ssxi-optimizer-metadata-boundary-targets
          file))
        (expanderRootBoundarySignals
         (typed-combinator-style-expander-root-boundary-signals file))
        (expanderRootBoundaryTargets
         (typed-combinator-style-expander-root-boundary-targets file))
        (actorRuntimeBoundarySignals
         (typed-combinator-style-actor-runtime-boundary-signals file))
        (actorRuntimeBoundaryTargets
         (typed-combinator-style-actor-runtime-boundary-targets file))
        (mopC3LinearizationBoundarySignals
         (typed-combinator-style-mop-c3-linearization-boundary-signals file))
        (mopC3LinearizationBoundaryTargets
         (typed-combinator-style-mop-c3-linearization-boundary-targets file))
        (exceptionContinuationBoundarySignals
         (typed-combinator-style-exception-continuation-boundary-signals
          file))
        (exceptionContinuationBoundaryTargets
         (typed-combinator-style-exception-continuation-boundary-targets
          file))
        (macroFamilySignals
         (typed-combinator-style-macro-family-signals file))
        (macroFamilyTargets
         (typed-combinator-style-macro-family-targets file))
        (phaseAwareMacroBoundarySignals
         (typed-combinator-style-phase-aware-macro-boundary-signals file))
        (phaseAwareMacroBoundaryTargets
         (typed-combinator-style-phase-aware-macro-boundary-targets file))
        (controlledMacroSyntaxSignals
         (typed-combinator-style-controlled-macro-syntax-signals file))
        (controlledMacroTargets
         (typed-combinator-style-controlled-macro-targets file))
        (typeclassAlgebraSignals
         (typed-combinator-style-typeclass-algebra-signals file))
        (typeclassAlgebraTargets
         (typed-combinator-style-typeclass-algebra-targets file))
        (gerbilContractProjectionSignals +gerbil-contract-projection-signals+)
        (implementationEvidenceSource
         "parser-owned higherOrderFacts plus callFacts; do not use raw text heuristics")
        (qualityFacetSource
         "parser-owned typedContractFacts, higherOrderFacts, booleanConditionFacts, loopDriverFacts, and functionQualityProfiles derived from native call, higher-order, and control-flow facts")
        (qualityFacets quality-facets)
        (qualityFacetSteering
         (typed-combinator-style-quality-facet-steering quality-facets))
        (qualityRepairTriggered quality-repair-triggered?)
        (agentRepairEnvelope
         (hash (flexibility "agent may choose helper names and exact composition shape")
               (constraints ["preserve selector behavior"
                             "keep public exports stable unless policy evidence permits"
                             "do not cross IO/runtime/macro boundaries without witness"])
               (nativeRepairEvidence
                (take repair-evidence (min 6 (length repair-evidence))))))
        (optimizationBoundary "when using case-lambda or a specialized branch, comment why that branch exists and keep the comment about the boundary, not the code mechanics")
        (definitionCount definition-count)
        (typedCommentCount valid-typed-comment-count)
        (typedCommentLineCount typed-comment-line-count)
        (validTypedContractCount valid-typed-comment-count)
        (invalidTypedContractCount invalid-typed-comment-count)
        (missingTypedCommentCount missing-count)
        (invalidReason "typed-combinator-style comments must be parser-owned adjacent algebraic transform signatures; see invalidTypedContractReasons for exact parser reasons")
        (invalidTypedContractReasons
         (file-typed-contract-invalid-reasons file))
        (invalidTypedContractExamples
         (file-typed-contract-invalid-examples file))
        (contractFactSource "native-parser")
        (scope "source-or-test-owner")
        (adjacency "definition-leading-comment")))

;;; Scope boundary:
;;; - Runtime source and real tests must keep typed-combinator contracts.
;;; - t/scenarios contains fixture projects that intentionally encode bad shapes.
;; : (-> ProjectIndex SourceFile Boolean)
;;; Source-class scope guard:
;;; - Parser source classes own fixture/scenario/generated classification.
;;; - Policy only decides which parser-owned classes are actionable.
;; : (-> ProjectIndex SourceFile Boolean )
(def (typed-combinator-style-source-file? index file)
  (let (path (source-file-path file))
    (and path
         (typed-combinator-style-actionable-source-class? (source-path-class path))
         (ormap (lambda (accept?) (accept? path))
                [(cut index-source-runtime-file-path? index <>)
                 (cut string-prefix? "t/" <>)]))))

;;; Quality-trigger scope excludes parser fixtures: fixture owners intentionally
;;; encode bad and unusual syntax that policy tests assert elsewhere.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-quality-repair-source-file? file)
  (let (path (source-file-path file))
    (and path
         (typed-combinator-style-actionable-source-class? (source-path-class path)))))

;;; Actionable source classes:
;;; - Generated data, fixtures, snapshots, and policy scenario projects are
;;;   evidence fixtures, not owners the agent should repair in place.
;;; - New parser-owned classes can be excluded here without path matching.
;; : (-> SourceClass Boolean )
(def (typed-combinator-style-actionable-source-class? source-class)
  (not (member source-class
               ["policy-scenario"
                "fixture"
                "snapshot-output"
                "generated"])))

;;; Evidence absence boundary:
;;; - Fire only after typed contracts are complete and valid.
;;; - A module-level engineering comment can intentionally waive expression
;;;   evidence when the owner explains the boundary.
;; : (-> Nat Nat Nat Nat Nat Boolean )
(def (typed-combinator-style-missing-implementation-evidence? definition-count valid-typed-comment-count invalid-typed-comment-count missing-count implementation-evidence-count module-engineering-comment?)
  (and (> definition-count 1)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (= implementation-evidence-count 0)
       (not module-engineering-comment?)))

;;; Boundary: module-level engineering comments count only when the native
;;; parser attached concrete comment lines to the module owner.
;; : (-> SourceFile Boolean )
(def (source-file-has-engineering-module-comment? file)
  (ormap
   (lambda (fact)
     (and (equal? (comment-quality-fact-target-kind fact) "module")
          (pair? (comment-quality-fact-comment-lines fact))))
   (source-file-comment-quality-facts file)))

;;; Boundary:
;;; - Full-form documentation is required when parser facts show semantic risk.
;;; - Exported status alone is not enough; it must combine with role or facet evidence.
;;; - Ordinary public constructors and accessors may keep the short `;; :` form.
;;; Coverage threshold boundary:
;;; - Valid typed contracts are necessary before coverage warnings fire.
;;; - Module engineering comments may waive coverage-ratio pressure for
;;;   declarative or boundary modules, but never waive missing contracts,
;;;   invalid contracts, missing evidence, or parser-owned quality repairs.
;; : (-> Nat Nat Nat Nat Nat Nat Nat Boolean )
(def (typed-combinator-style-implementation-coverage-insufficient? function-definition-count covered-definition-count minimum-covered-definition-count implementation-evidence-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (typed-combinator-style-coverage-gate-open?
        function-definition-count
        valid-typed-comment-count
        invalid-typed-comment-count
        missing-count
        module-engineering-comment?)
       (typed-combinator-style-below-coverage-floor?
        covered-definition-count
        minimum-covered-definition-count
        implementation-evidence-count)))
;; : (-> Nat Nat Nat Nat Boolean Boolean )
(def (typed-combinator-style-coverage-gate-open? function-definition-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (> function-definition-count 2)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (not module-engineering-comment?)))
;; : (-> Nat Nat Nat Boolean )
(def (typed-combinator-style-below-coverage-floor? covered-definition-count minimum-covered-definition-count implementation-evidence-count)
  (and (< covered-definition-count minimum-covered-definition-count)
       (< implementation-evidence-count
          (typed-combinator-style-minimum-file-evidence-count
           minimum-covered-definition-count))))

;;; Absolute evidence floor:
;;; - Large orchestration/parser owners should not fail solely because every
;;;   tiny wrapper lacks its own combinator witness when the file already has
;;;   several parser-owned Gerbil-native idiom witnesses.
;;; - Sparse owners still fail, preserving the policy's repair signal.
;; : (-> Nat Nat)
(def (typed-combinator-style-minimum-file-evidence-count minimum-covered-definition-count)
  (min minimum-covered-definition-count
       +typed-combinator-style-file-evidence-floor+))

;;; Minimum coverage boundary:
;;; - Require roughly two thirds of arity-bearing helpers to have Gerbil-native
;;;   expression evidence.
;;; - Zero-definition owners stay valid and do not force artificial witnesses.
;; : (-> Nat Nat )
(def (typed-combinator-style-minimum-covered-definition-count function-definition-count)
  (if (zero? function-definition-count)
    0
    (quotient (+ (* function-definition-count 2) 2) 3)))
;;; Coverage denominator: constants are excluded so only arity-bearing helpers need expression evidence.
;; : (-> SourceFile (List Definition) )
(def (typed-combinator-style-function-definitions file)
  (filter (lambda (defn)
            (and (> (definition-arity defn) 0)
                 (not (poo-declarative-definition? defn))))
          (source-file-definitions file)))

;;; Declarative POO boundary:
;;; - POO type and method declarations are structural forms, not helper bodies.
;;; - Excluding them keeps coverage focused on arity-bearing behavior.
;; : (-> Definition Boolean )
(def (poo-declarative-definition? defn)
  (member (definition-kind defn) +poo-declarative-definition-kinds+))
;;; Coverage numerator: parser evidence is attributed by caller before compacting duplicate facts.
;; : (-> (List Evidence) (List String) )
(def (typed-combinator-style-evidence-callers implementation-evidence)
  (unique
   (filter (lambda (value)
             (and (string? value)
                  (not (string-empty? value))))
           (map (lambda (evidence) (hash-get evidence 'caller))
                implementation-evidence))))
;;; Coverage report: expose covered helpers so agents can see which functions already match the style.
;; : (-> SourceFile (List String) (List String) )
(def (typed-combinator-style-covered-definition-names file implementation-evidence-callers)
  (filter (cut member <> implementation-evidence-callers)
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Repair target list: uncovered helpers tell the agent where to add expression-level evidence first.
;; : (-> SourceFile (List String) (List String) )
(def (typed-combinator-style-uncovered-definition-names file implementation-evidence-callers)
  (filter (lambda (name) (not (member name implementation-evidence-callers)))
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Evidence boundary: implementation coverage merges higher-order facts and
;;; call-shape facts, leaving threshold decisions to the policy details layer.
;; : (-> SourceFile (List Evidence) )
(def (typed-combinator-style-implementation-evidence file)
  (append
   (map higher-order-style-evidence
        (filter typed-combinator-style-higher-order-fact?
                (source-file-higher-order-forms file)))
   (map call-style-evidence
        (filter typed-combinator-style-call-fact?
                (source-file-calls file)))))

;;; Quality facets summarize parser-owned style evidence for a source owner.
;;; Keep advisory signals available even when they do not trigger a finding.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-quality-facets file)
  (unique
   (append
    (apply append
           (map typed-contract-fact-quality-facets
                (source-file-typed-contract-facts file)))
    (apply append
           (map higher-order-quality-facets
                (source-file-higher-order-forms file)))
    (apply append
           (map boolean-condition-fact-quality-facets
                (source-file-boolean-condition-facts file)))
    (apply append
           (map typed-combinator-style-profile-quality-facets
                (source-file-function-quality-profiles file)))
    (typed-combinator-style-generator-quality-facets file)
    (typed-combinator-style-anti-ai-scaffold-quality-facets file)
    (typed-combinator-style-gerbil-upstream-idiom-quality-facets file)
    (typed-combinator-style-list-combinator-quality-facets file)
    (typed-combinator-style-std-sugar-flow-quality-facets file)
    (typed-combinator-style-loop-driver-quality-facets file)
    (typed-combinator-style-destructuring-quality-facets file)
    (typed-combinator-style-serialization-boundary-quality-facets file)
    (typed-combinator-style-slot-lens-boundary-quality-facets file)
    (typed-combinator-style-concurrency-control-quality-facets file)
    (typed-combinator-style-ssxi-optimizer-metadata-boundary-quality-facets
     file)
    (typed-combinator-style-expander-root-boundary-quality-facets file)
    (typed-combinator-style-actor-runtime-boundary-quality-facets file)
    (typed-combinator-style-mop-c3-linearization-boundary-quality-facets file)
    (typed-combinator-style-exception-continuation-boundary-quality-facets file)
    (typed-combinator-style-macro-family-quality-facets file)
    (typed-combinator-style-phase-aware-macro-boundary-quality-facets file)
    (typed-combinator-style-controlled-macro-quality-facets file)
    (typed-combinator-style-upstream-performance-quality-facets file)
    (typed-combinator-style-result-index-scaffold-quality-facets file)
    (typed-combinator-style-typeclass-quality-facets file))))

;;; R015 consumes only the profile facets that steer gerbil-utils/base.ss style
;;; abstraction.  Broader profile facts stay available to search/report without
;;; turning every typed-block shape hint into an actionable warning.
;; : (-> FunctionQualityProfile (List QualityFacet) )
(def (typed-combinator-style-profile-quality-facets profile)
  (filter (lambda (facet)
            (member facet
                    ["base-style-combinator-composition"
                     "higher-order-constructor-abstraction"
                     "arity-specialized-function-factory"
                     "wrapper-lambda-drift"
                     "function-specialization-opportunity"
                     "eta-wrapper-drift"
                     "lambda-match-destructuring"
                     "lambda-match-rewrite-opportunity"
                     "method-table-combinator-body"
                     "method-table-lambda-drift"
                     "method-table-low-level-body"]))
          (function-quality-profile-quality-facets profile)))

;;; Repair evidence carries concrete parser witnesses into guide output.
;;; Agents may choose the rewrite shape, but the witness set stays bounded.
;; : (-> SourceFile (List RepairEvidence) )
(def (typed-combinator-style-repair-evidence file)
  (map typed-contract-fact-repair-evidence
       (source-file-typed-contract-facts file)))

;;; Quality facets are parser-owned repair triggers, not passive advice.
;;; The policy turns manual-loop drift into warnings so self-apply can repair.
;; : (-> SourceFile (List QualityFacet) Boolean )
(def (typed-combinator-style-quality-repair-triggered? file quality-facets)
  (or (quality-facet-any? quality-facets
                          ["scheme-native-typed-block-migration"])
      (and (not (typed-combinator-style-positive-quality-covered?
                 quality-facets))
           (quality-facet-any? quality-facets
                               ["manual-loop-drift"
                                "method-table-lambda-drift"
                                "anti-ai-scaffold-boundary"
                                "gerbil-upstream-idiom-boundary"
                                "list-combinator-boundary"
                                "std-sugar-flow-boundary"
                                "destructuring-combinator-boundary"
                                "gerbil-native-pattern-boundary"
                                "match-with-destructuring-boundary"
                                "pair-tuple-projection-boundary"
                                "values-tuple-protocol"
                                "result-index-scaffold"
                                "slot-lens-boundary"
                                "concurrency-control-boundary"
                                "ssxi-optimizer-metadata-boundary"
                                "actor-runtime-boundary"
                                "exception-continuation-boundary"
                                "macro-family-boundary"
                                "phase-aware-macro-boundary"
                                "macro-phase-optimizer-visible-fast-path"
                                "gambit-numeric-primitive-boundary"
                                "gerbil-inline-rule-call-shape"]))
      (and (typed-combinator-style-runtime-wrapper-source-file? file)
           (not (typed-combinator-style-positive-quality-covered?
                 quality-facets))
           (quality-facet-any? quality-facets
                               ["wrapper-lambda-drift"
                                "function-specialization-opportunity"
                                "boolean-normalization-drift"
                                "generated-scaffold-shape"]))))

;;; Positive coverage gate: broad parser facets become warning triggers only
;;; when the file lacks concrete combinator or expression-level evidence.
;; : (-> (List QualityFacet) Boolean )
(def (typed-combinator-style-positive-quality-covered? facets)
  (and (quality-facet-present? facets "expression-level-composition")
       (quality-facet-any? facets
                           ["higher-order-used"
                            "combinator-backed"
                            "base-style-combinator-composition"])))

;;; Facet membership is normalized once so policy triggers read as predicates
;;; instead of carrying generated double-negation scaffolding at call sites.
;; : (-> (List QualityFacet) QualityFacet Boolean )
(def (quality-facet-present? facets facet)
  (if (member facet facets) #t #f))

;;; Candidate checks keep trigger lists data-shaped while returning a strict
;;; boolean for finding assembly and detail packets.
;; : (-> (List QualityFacet) (List QualityFacet) Boolean )
(def (quality-facet-any? facets candidates)
  (ormap (cut quality-facet-present? facets <>) candidates))

;;; Runtime wrapper scope:
;;; - Tests and fixtures can encode negative examples without this extra gate.
;;; - Runtime files need stronger coverage before broad quality facets warn.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-runtime-wrapper-source-file? file)
  (let (path (source-file-path file))
    (and path
         (not (string-prefix? "t/" path)))))

;;; Boundary:
;;; - typed-combinator-style-higher-order-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> HigherOrderFact Boolean )
(def (typed-combinator-style-higher-order-fact? fact)
  (ormap (cut equal? (higher-order-fact-role fact) <>)
         +typed-combinator-style-higher-order-roles+))
;;; Boundary:
;;; - typed-combinator-style-call-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> CallFact Boolean )
(def (typed-combinator-style-call-fact? fact)
  (ormap (cut equal? (call-fact-callee fact) <>)
         +typed-combinator-style-call-heads+))

;;; Native result protocol quality:
;;; - The parser already owns callee and argument facts for `vector-ref`.
;;; - A result-ish temporary indexed by small numeric slots is an anonymous
;;;   tuple protocol; prefer values binding, a named record, or a domain object.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-result-index-scaffold-quality-facets file)
  (if (pair? (typed-combinator-style-result-index-scaffold-calls file))
    ["result-index-scaffold" "anonymous-result-protocol"]
    []))

;; : (-> SourceFile (List CallFact) )
(def (typed-combinator-style-result-index-scaffold-calls file)
  (filter typed-combinator-style-result-index-scaffold-call?
          (source-file-calls file)))

;; : (-> CallFact Boolean )
(def (typed-combinator-style-result-index-scaffold-call? call)
  (and (equal? (call-fact-callee call) "vector-ref")
       (typed-combinator-style-result-index-arguments?
        (call-fact-arguments call))))

;; : (-> (List Argument) Boolean )
(def (typed-combinator-style-result-index-arguments? arguments)
  (and (pair? arguments)
       (pair? (cdr arguments))
       (typed-combinator-style-result-name? (car arguments))
       (member (cadr arguments) ["0" "1" "2" "3"])))

;; : (-> Argument Boolean )
(def (typed-combinator-style-result-name? value)
  (and value
       (or (equal? value "result")
           (typed-combinator-style-string-suffix? "-result" value))))

;; : (-> String String Boolean )
(def (typed-combinator-style-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (>= value-length suffix-length)
         (string=? (substring value
                              (- value-length suffix-length)
                              value-length)
                   suffix))))
;; : (-> HigherOrderFact Evidence )
(def (higher-order-style-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (selector (higher-order-fact-selector fact))))
;; : (-> CallFact Evidence )
(def (call-style-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (caller (or (call-fact-caller fact) ""))
        (selector (call-fact-selector fact))))
;;; Boundary:
;;; - typed-combinator-style-message coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Boolean String String )
(def (typed-combinator-style-message-fragment condition text)
  (if condition text ""))
;; : (-> InvalidContractCount String )
(def (typed-combinator-style-invalid-comment-fragment invalid-typed-comment-count)
  (typed-combinator-style-message-fragment
   (> invalid-typed-comment-count 0)
   (string-append " and "
                  (number->string invalid-typed-comment-count)
                  " low-information typed comments")))
;; : (-> Nat Nat Nat String )
(def (typed-combinator-style-coverage-fragment covered-definition-count function-definition-count minimum-covered-definition-count)
  (string-append
   "; parser-owned expression-level implementation evidence covers "
   (number->string covered-definition-count)
   "/"
   (number->string function-definition-count)
   " arity-bearing definitions, below minimum "
   (number->string minimum-covered-definition-count)))
;; : (-> Boolean Nat String )
(def (typed-combinator-style-doc-fragment typed-doc-missing? typed-doc-missing-count)
  (typed-combinator-style-message-fragment
   typed-doc-missing?
   (string-append
    "; "
    (number->string typed-doc-missing-count)
    " public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments")))
;; : (-> DefinitionCount ValidContractCount InvalidContractCount Boolean Boolean Boolean Boolean Nat Nat Nat Nat Message )
(def (typed-combinator-style-message definition-count typed-comment-count invalid-typed-comment-count missing-implementation-evidence? implementation-coverage-insufficient? typed-doc-missing? quality-repair-triggered? typed-doc-missing-count covered-definition-count function-definition-count minimum-covered-definition-count)
  (string-append
   "Scheme source owner has "
   (number->string definition-count)
   " definitions but only "
   (number->string typed-comment-count)
   " adjacent typed-combinator-style algebraic contracts"
   (typed-combinator-style-invalid-comment-fragment invalid-typed-comment-count)
   (typed-combinator-style-message-fragment
    missing-implementation-evidence?
    "; typed contracts are present but no parser-owned expression-level implementation evidence was found")
   (typed-combinator-style-message-fragment
    implementation-coverage-insufficient?
    (typed-combinator-style-coverage-fragment
     covered-definition-count
     function-definition-count
     minimum-covered-definition-count))
   (typed-combinator-style-doc-fragment
    typed-doc-missing?
    typed-doc-missing-count)
   (typed-combinator-style-message-fragment
    quality-repair-triggered?
    "; parser-owned quality facets require repair toward compact expression-level composition")
   "; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))

;;; Missing contract count:
;;; - Clamp at zero so extra parser facts never produce negative diagnostics.
;;; - The caller still reports invalid typed comments separately.
;; : (-> Integer Integer Integer )
(def (typed-combinator-style-missing-count definition-count typed-comment-count)
  (if (> definition-count typed-comment-count)
    (- definition-count typed-comment-count)
    0))
;; : (-> ProjectIndex SourceFile ContractSummary )
(def (file-typed-combinator-style-summary index file)
  (typed-contract-fact-summary (source-file-typed-contract-facts file)))
;; : (-> ProjectIndex SourceFile Integer )
(def (file-typed-combinator-style-count index file)
  (cadr (file-typed-combinator-style-summary index file)))
;;; Boundary:
;;; - typed-contract-fact-summary composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypedContractFact) ContractSummary )
(def (typed-contract-fact-summary facts)
  (foldl (lambda (fact summary)
           (if (equal? (typed-contract-fact-quality fact) "invalid")
             (list (+ (car summary) 1)
                   (cadr summary)
                   (+ (caddr summary) 1))
             (list (+ (car summary) 1)
                   (+ (cadr summary) 1)
                   (caddr summary))))
         (list 0 0 0)
         facts))
