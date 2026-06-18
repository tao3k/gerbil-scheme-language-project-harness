;;; -*- Gerbil -*-
;;; Agent-facing style policy checks.

(import :parser/facade
        :policy/agent-style-gerbil-signals
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
    "curry" "rcurry" "cut" "cute" "map" "filter" "filter-map"
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
;; (List Role)
(def +typed-combinator-style-doc-required-roles+
  '("macro-helper" "protocol-method" "poo-protocol-boundary" "driver"))
;; (List QualityFacet)
(def +typed-combinator-style-doc-required-facets+
  '("macro-runtime-source-witness" "poo-protocol-evidence"
    "loop-driver-classified"))
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
                valid-typed-comment-count
                invalid-typed-comment-count
                missing-count
                module-engineering-comment?)))
         (and (ormap (lambda (triggered?) triggered?)
                     [(> missing-count 0)
                      (> invalid-typed-comment-count 0)
                      missing-implementation-evidence?
                      implementation-coverage-insufficient?
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
        (typedCommentMigrationNeeded
         (quality-facet-present? quality-facets
                                 "gerbil-contract-projection-migration"))
        (typedCommentMigration
         "rewrite legacy ;; Output <- Input comments to Gerbil contract projection ;; : (-> Input Output) blocks; add ;; | type aliases for Order, Refine, or finite enum names")
        (contractLinePolicy "multi-line typed-combinator-style contracts are allowed when needed to preserve precision")
        (compositionShape "compact expression-level helper or combinator chain; prefer map/filter/fold/cut/curry/compose when behavior fits")
        (qualityReference "gerbil-utils")
        (functionShape "single-purpose expression-returning helper; one visible data-flow shape per function")
        (agentRepairStandard "rewrite toward gerbil-utils style: small algebraic helpers, dense but readable composition, minimal let*/mutation scaffolding")
        (expressionLevelRewrite "extract predicate/mapper/reducer helpers, then compose with filter-map/map/fold/andmap/ormap/cut/curry/compose when behavior fits")
        (antiPattern "procedural let* pipeline, broad named-let accumulator, or nested match body when a small selector/helper would expose the data flow")
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
         "at least half of arity-bearing definitions must have parser-owned expression-level evidence")
        (gerbilUtilsImplementationSignals +gerbil-utils-implementation-signals+)
        (generatorCombinatorSignals
         (typed-combinator-style-generator-combinator-signals file))
        (generatorContractTargets
         (typed-combinator-style-generator-contract-targets file))
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
         "parser-owned typedContractFacts, higherOrderFacts, booleanConditionFacts, and functionQualityProfiles derived from native call, higher-order, and control-flow facts")
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
;; Boolean <- ProjectIndex SourceFile
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
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-missing-doc-targets file)
  (unique
   (append
    (filter-map (cut typed-combinator-style-profile-missing-doc-target file <>)
                (source-file-function-quality-profiles file))
    (filter-map (cut typed-combinator-style-macro-missing-doc-target file <>)
                (source-file-macros file)))))

;; : (-> SourceFile FunctionQualityProfile MaybeTargetName )
(def (typed-combinator-style-profile-missing-doc-target file profile)
  (and (typed-combinator-style-profile-requires-doc? profile)
       (not (typed-combinator-style-profile-has-doc? file profile))
       (function-quality-profile-name profile)))

;; : (-> FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-requires-doc? profile)
  (and (> (function-quality-profile-arity profile) 0)
       (or (member (function-quality-profile-role profile)
                   +typed-combinator-style-doc-required-roles+)
           (and (function-quality-profile-exported profile)
                (typed-combinator-style-profile-doc-required-facet? profile)))))

;;; Boundary:
;;; - Facet-driven doc requirements come from parser-owned quality evidence.
;;; - This keeps R013 extensible without hard-coding path-specific policy exceptions.
;; : (-> FunctionQualityProfile Boolean)
(def (typed-combinator-style-profile-doc-required-facet? profile)
  (ormap (lambda (facet)
           (member facet
                   (function-quality-profile-quality-facets profile)))
         +typed-combinator-style-doc-required-facets+))

;; : (-> SourceFile FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-has-doc? file profile)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (function-quality-profile-name profile)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (function-quality-profile-name profile)))))

;; : (-> SourceFile MacroFact MaybeTargetName )
(def (typed-combinator-style-macro-missing-doc-target file macro)
  (and (not (typed-combinator-style-macro-has-doc? file macro))
       (macro-fact-name macro)))

;; : (-> SourceFile MacroFact Boolean )
(def (typed-combinator-style-macro-has-doc? file macro)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (macro-fact-name macro)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (macro-fact-name macro)))))

;;; Boundary:
;;; - Typed contract lookup is keyed by parser-owned definition name.
;;; - Policy must not scan source text to decide whether docs are complete.
;; : (-> SourceFile String MaybeTypedContractFact )
(def (typed-combinator-style-typed-contract-fact file name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        (source-file-typed-contract-facts file)))

;; : (-> TypedContractFact String Boolean)
(def (typed-combinator-style-typed-comment-has-full-doc? fact expected-name)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (and (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
         (typed-combinator-style-docs-complete
          (typed-combinator-style-typed-comment-docs typed-comment)))))

;;; Ownership checks stay separate from documentation content so policy can
;;; explain whether a full-form block is missing or merely incomplete.
;; : (-> TypedCommentMetadata String Boolean)
(def (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
  (and typed-comment
       (hash-get typed-comment 'fullForm)
       (equal? (hash-get typed-comment 'leadingName) expected-name)))

;;; Typed-comment docs are projected once from parser metadata; downstream
;;; body/example predicates consume the list without reaching back into hashes.
;; : (-> TypedCommentMetadata (List Json))
(def (typed-combinator-style-typed-comment-docs typed-comment)
  (or (hash-get typed-comment 'docs) []))

;;; Completeness is an aggregator over the two public doc evidence predicates.
;;; It is deliberately not a `?` helper so R016 does not treat it as another
;;; predicate-family member over `docs`.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-complete docs)
  (and (typed-combinator-style-docs-have-body? docs)
       (typed-combinator-style-docs-have-result-example? docs)))

;;; Boundary:
;;; - Documentation body evidence comes from typed-comment metadata.
;;; - Empty `| doc` sections cannot satisfy public helper documentation.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-body? docs)
  (ormap (lambda (doc)
           (let (body (or (hash-get doc 'body) ""))
             (not (blank-string? body))))
         docs))

;;; Boundary:
;;; - Result examples prove the doc block carries repair-checkable output.
;;; - Accept either section-level result evidence or parsed example packets.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-result-example? docs)
  (ormap (lambda (doc)
           (or (hash-get doc 'hasResultExamples)
               (ormap typed-combinator-style-example-has-result?
                      (or (hash-get doc 'examples) []))))
         docs))

;; : (-> Json Boolean)
(def (typed-combinator-style-example-has-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;; : (-> Nat Nat Nat Nat Nat Nat Boolean )
(def (typed-combinator-style-implementation-coverage-insufficient? function-definition-count covered-definition-count minimum-covered-definition-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (> function-definition-count 2)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (not module-engineering-comment?)
       (< covered-definition-count minimum-covered-definition-count)))
;; : (-> Nat Nat )
(def (typed-combinator-style-minimum-covered-definition-count function-definition-count)
  (if (zero? function-definition-count)
    0
    (quotient (+ function-definition-count 1) 2)))
;;; Coverage denominator: constants are excluded so only arity-bearing helpers need expression evidence.
;; : (-> SourceFile (List Definition) )
(def (typed-combinator-style-function-definitions file)
  (filter (lambda (defn)
            (and (> (definition-arity defn) 0)
                 (not (poo-declarative-definition? defn))))
          (source-file-definitions file)))
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
    (typed-combinator-style-controlled-macro-quality-facets file)
    (typed-combinator-style-typeclass-quality-facets file))))

;;; R015 consumes only the profile facets that steer gerbil-utils/base.ss style
;;; abstraction.  Broader profile facts stay available to search/report without
;;; turning every legacy contract migration hint into an actionable warning.
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

;;; Native facet steering turns parser-owned Gerbil quality facts into bounded repair moves.
;;; This keeps agent freedom in naming while constraining the rewrite strategy to witnessed syntax.
;; : (-> (List QualityFacet) (List RepairMove) )
(def (typed-combinator-style-quality-facet-steering quality-facets)
  (filter identity
          [(and (member "expression-level-composition" quality-facets)
                "prefer map/filter/filter-map/fold pipelines; extract predicate, mapper, or reducer helpers before rewriting loops")
           (and (member "manual-loop-drift" quality-facets)
                "replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness")
           (and (member "over-abstracted-contract-risk" quality-facets)
                "replace abstract grouped contracts with concrete domain/result names or add parser-owned callsite evidence")
           (and (member "scheme-native-typed-block-migration" quality-facets)
                "migrate legacy ;; Output <- Input contract comments to adjacent Scheme-native ;; : (-> Input Output) blocks; add ;; | type aliases for enum/refinement names")
           (and (member "combinator-composition" quality-facets)
                "prefer cut/curry/rcurry/compose helper composition when arity evidence already matches")
           (and (member "lambda-local-abstraction" quality-facets)
                "prefer small local lambda/function-factory helpers when the behavior is a reusable transform")
           (and (member "lambda-match-rewrite-opportunity" quality-facets)
                "replace unary lambdas whose whole body matches the same argument with gerbil-utils/base.ss lambda-match or lambda-ematch")
           (and (member "lambda-match-destructuring" quality-facets)
                "keep pattern destructuring at the function boundary instead of hiding it behind anonymous wrapper lambdas")
           (and (member "named-lambda-helper" quality-facets)
                "use gerbil-utils/base.ss style fun helpers when a local named lambda makes the transform reusable without recursive self-reference")
           (and (member "parameterized-transform" quality-facets)
                "keep lambda/lambda-match parameters meaningful and push repeated destructuring into named helpers")
           (and (member "case-lambda-optimization-boundary" quality-facets)
                "preserve case-lambda or common-case specialization and document the optimization boundary")
           (and (member "multi-arity-abstraction" quality-facets)
                "use case-lambda when a helper has real arity variants instead of branching on raw argument lists")
           (and (member "function-specialization-abstraction" quality-facets)
                "use cut/curry/rcurry for first-class specialization instead of repeated wrapper lambdas")
           (and (member "eta-wrapper-drift" quality-facets)
                "replace eta-wrapper lambdas with the direct function, cut, curry/rcurry, or compose/rcompose according to argument shape")
           (and (member "function-pipeline-abstraction" quality-facets)
                "use compose/rcompose/!>/!!> when the data flow is a reusable function pipeline")
           (and (member "base-style-combinator-composition" quality-facets)
                "model reusable data flow after gerbil-utils/base.ss combinators: λ/lambda-match for local destructuring, fun for named lambdas, and compose/!>/curry/rcurry for first-class flow")
           (and (member "higher-order-constructor-abstraction" quality-facets)
                "preserve function-constructor boundaries that combine case-lambda with returned procedures")
           (and (member "arity-specialized-function-factory" quality-facets)
                "use nested case-lambda only for real arity specialization and keep the optimization boundary explicit")
           (and (member "wrapper-lambda-drift" quality-facets)
                "extract repeated wrapper lambdas into a named factory, case-lambda function factory, curry/rcurry specializer, or compose/rcompose pipeline")
           (and (member "function-specialization-opportunity" quality-facets)
                "repair anonymous specialization by introducing one first-class helper boundary before changing call sites")
           (and (member "boolean-normalization-drift" quality-facets)
                "replace double-negation scaffolding with the underlying boolean expression, or name the predicate boundary when truthiness normalization is intentional")
           (and (member "generated-scaffold-shape" quality-facets)
                "treat obvious generated scaffolding as a repair trigger: remove redundant wrappers before adding new abstraction")
           (and (member "builder-or-fold-combinator" quality-facets)
                "prefer for/fold or with-list-builder only when parser facts show a real accumulator or builder boundary")
           (and (member "generator-combinator-boundary" quality-facets)
                "when contracts mention Generating, prefer gerbil-utils/generator.ss combinators such as generating-map, generating-fold, generating-partition, and generating-merge before hand-written producer loops")
           (and (member "controlled-macro-syntax-boundary" quality-facets)
                "when parser facts show macro owners, use upstream Gerbil macro-library idioms; keep syntax wrappers thin and hygienic, and push reusable runtime behavior into ordinary helpers")
           (and (member "poo-typeclass-algebra-boundary" quality-facets)
                "when POO facts expose typeclass/functor/wrapper options, model the implementation after gerbil-poo/fun.ss algebra instead of raw object adapters or ad hoc tables")
           (and (member "method-table-combinator-body" quality-facets)
                "preserve method-table slots that already use cut/curry/compose/pipeline or selector-shaped bodies")
           (and (member "method-table-lambda-drift" quality-facets)
                "repair method-table lambdas by extracting slot-shaped helpers or using cut/curry/compose while preserving the receiver/protocol boundary")
           (and (member "method-table-low-level-body" quality-facets)
                "move low-level method-table calls or compounds behind named helpers before widening the adapter")]))

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
                          ["manual-loop-drift"
                           "scheme-native-typed-block-migration"
                           "method-table-lambda-drift"])
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

;; : (-> (List QualityFacet) QualityFacet Boolean )
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
;; : (-> DefinitionCount ValidContractCount InvalidContractCount Boolean Boolean Boolean Boolean Nat Nat Nat Nat Message )
(def (typed-combinator-style-message definition-count typed-comment-count invalid-typed-comment-count missing-implementation-evidence? implementation-coverage-insufficient? typed-doc-missing? quality-repair-triggered? typed-doc-missing-count covered-definition-count function-definition-count minimum-covered-definition-count)
  (string-append
   "Scheme source owner has "
   (number->string definition-count)
   " definitions but only "
   (number->string typed-comment-count)
   " adjacent typed-combinator-style algebraic contracts"
   (if (> invalid-typed-comment-count 0)
     (string-append " and "
                    (number->string invalid-typed-comment-count)
                    " low-information typed comments")
     "")
   (if missing-implementation-evidence?
     "; typed contracts are present but no parser-owned expression-level implementation evidence was found"
     "")
   (if implementation-coverage-insufficient?
     (string-append
      "; parser-owned expression-level implementation evidence covers "
      (number->string covered-definition-count)
      "/"
      (number->string function-definition-count)
      " arity-bearing definitions, below minimum "
      (number->string minimum-covered-definition-count))
     "")
   (if typed-doc-missing?
     (string-append
      "; "
      (number->string typed-doc-missing-count)
      " public/policy-sensitive helpers need full typed doc blocks with | doc m%, # Examples, and result comments")
     "")
   (if quality-repair-triggered?
     "; parser-owned quality facets require repair toward compact expression-level composition"
     "")
   "; typed-combinator-style has three criteria: adjacent Scheme-native typed block such as ;; : (-> Input Output), compact expression-level composition, and optimization-boundary comments for specialized branches"))
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
;;; Boundary:
;;; - file-typed-contract-invalid-reasons composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractReason) )
(def (file-typed-contract-invalid-reasons file)
  (unique
   (apply append
          (map typed-contract-fact-reasons
               (filter invalid-typed-contract-fact?
                       (source-file-typed-contract-facts file))))))
;;; Boundary:
;;; - file-typed-contract-invalid-examples composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractExample) )
(def (file-typed-contract-invalid-examples file)
  (let (facts (filter invalid-typed-contract-fact?
                      (source-file-typed-contract-facts file)))
    (map typed-contract-fact-example
         (take facts (min 3 (length facts))))))
;; : (-> TypedContractFact Boolean )
(def (invalid-typed-contract-fact? fact)
  (equal? (typed-contract-fact-quality fact) "invalid"))
;; : (-> TypedContractFact InvalidContractExample )
(def (typed-contract-fact-example fact)
  (hash (definition (typed-contract-fact-definition-name fact))
        (selector (typed-contract-fact-selector fact))
        (contract (typed-contract-fact-contract fact))
        (tokens (typed-contract-fact-tokens fact))
        (quality (typed-contract-fact-quality fact))
        (reasons (typed-contract-fact-reasons fact))
        (arrowCount (typed-contract-fact-arrow-count fact))
        (groupCount (typed-contract-fact-group-count fact))))
