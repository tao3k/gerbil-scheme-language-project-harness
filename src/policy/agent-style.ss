;;; -*- Gerbil -*-
;;; Agent-facing style policy checks.

(import :parser/facade
        :policy/agent-support
        :policy/agent-style-shape
        :policy/model
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar cut filter filter-map foldl hash hash-get ormap)
        :support/list
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
    "sequence-map" "sequence-filter" "sequence-filter-map"
    "sequence-append-map" "sequence-predicate" "sequence-search"
    "sequence-fold" "loop-fold" "list-builder"))
;; (List String)
(def +typed-combinator-style-call-heads+
  '("!>" "!!>" "left-to-right" "rcompose" "compose" "compose1"
    "curry" "rcurry" "cut" "cute" "map" "filter" "filter-map"
    "append-map" "fold" "foldl" "foldr" "fold-left" "fold-right"
    "andmap" "ormap" "every" "any" "find" "list-index"
    "with-list-builder"))
;; (List String)
(def +poo-declarative-definition-kinds+
  '(".def" "define-type" "defclass" ".defclass" "defmethod" ".defmethod"
    "defgeneric" ".defgeneric" "defprotocol" ".defprotocol"))
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
        (expectedCommentShape "adjacent Scheme-native typed block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
        (signatureShape "adjacent Scheme-native signature block using ;; : (forall (a) (-> Input Output)), optional ;; | type aliases, U unions, Values, and Refine predicates")
        (expectedDocShape "full form for exported helpers, macros, and policy-sensitive helpers: leading name matching the definition, ;;   : signature, optional ;;   | type/contract/requires/warning/rationale fields, and ;;   | doc m% with # Examples fenced Scheme input/result")
        (typedDocRequiredWhen "exported arity-bearing helper, macro, src/policy helper, or policy-sensitive helper")
        (typedCommentMetadataFields
         ["leadingName" "signatureType" "localTypes" "runtimeContracts"
          "runtimeContractsDetailed" "requires" "requiresDetailed"
          "warnings" "rationales" "docs" "docs.examples"
          "docs.hasResultExamples" "refinements"])
        (runtimeWitnessPolicy
         "use | contract for runtime predicate evidence, | requires for named preconditions, and | warning/| rationale only with concrete parser-visible witness")
        (typedDocMissing typed-doc-missing?)
        (typedDocMissingCount (length typed-doc-missing-targets))
        (typedDocMissingTargets
         (take-at-most typed-doc-missing-targets 12))
        (typedCommentMigrationNeeded
         (not
          (not
           (member "scheme-native-typed-block-migration" quality-facets))))
        (typedCommentMigration
         "rewrite legacy ;; Output <- Input comments to Scheme-native ;; : (-> Input Output) blocks; add ;; | type aliases for Order, Refine, or finite enum names")
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
         (take-at-most implementation-evidence 5))
        (missingImplementationEvidence missing-implementation-evidence?)
        (implementationEvidenceCallers
         (take-at-most implementation-evidence-callers 8))
        (coveredDefinitionCount covered-definition-count)
        (coveredDefinitions
         (take-at-most covered-definition-names 8))
        (functionDefinitionCount function-definition-count)
        (minimumCoveredDefinitionCount minimum-covered-definition-count)
        (uncoveredDefinitionCount (length uncovered-definition-names))
        (uncoveredDefinitions
         (take-at-most uncovered-definition-names 8))
        (implementationCoverageInsufficient
         implementation-coverage-insufficient?)
        (minimumImplementationCoverage
         "at least half of arity-bearing definitions must have parser-owned expression-level evidence")
        (gerbilUtilsImplementationSignals
         ["!>/!!> pipeline" "apply compose" "cut/curry/rcurry" "map/filter/filter-map/fold" "with-list-builder"])
        (implementationEvidenceSource
         "parser-owned higherOrderFacts plus callFacts; do not use raw text heuristics")
        (qualityFacetSource
         "parser-owned typedContractFacts, higherOrderFacts, and functionQualityProfiles derived from native call, higher-order, and control-flow facts")
        (qualityFacets quality-facets)
        (qualityFacetSteering
         (typed-combinator-style-quality-facet-steering quality-facets))
        (qualityRepairTriggered quality-repair-triggered?)
        (agentRepairEnvelope
         (hash (flexibility "agent may choose helper names and exact composition shape")
               (constraints ["preserve selector behavior"
                             "keep public exports stable unless policy evidence permits"
                             "do not cross IO/runtime/macro boundaries without witness"])
               (nativeRepairEvidence (take-at-most repair-evidence 6))))
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

;;; Boundary:
;;; - source-file-has-engineering-module-comment? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile Boolean )
(def (source-file-has-engineering-module-comment? file)
  (ormap
   (lambda (fact)
     (and (equal? (comment-quality-fact-target-kind fact) "module")
          (pair? (comment-quality-fact-comment-lines fact))))
   (source-file-comment-quality-facts file)))

;;; Boundary:
;;; - Full-form documentation is required for public and policy-sensitive helpers.
;;; - Ordinary private helpers may keep the short `;; :` form.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-missing-doc-targets file)
  (unique-strings
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
       (or (function-quality-profile-exported profile)
           (string-prefix? "src/policy/" (function-quality-profile-path profile)))))

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
    (and typed-comment
         (hash-get typed-comment 'fullForm)
         (equal? (hash-get typed-comment 'leadingName) expected-name)
         (typed-combinator-style-docs-have-body?
          (or (hash-get typed-comment 'docs) []))
         (typed-combinator-style-docs-have-result-example?
          (or (hash-get typed-comment 'docs) [])))))

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
  (not (not (hash-get example 'hasExpectedResult))))

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
  (unique-strings
   (filter non-empty-string?
           (map (lambda (evidence) (hash-get evidence 'caller))
                implementation-evidence))))
;; : (-> String Boolean )
(def (non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))
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
;;; Boundary:
;;; - typed-combinator-style-implementation-evidence composes first-class procedures.
;;; - Keep data-flow evidence visible.
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
  (unique-strings
   (append
    (apply append
           (map typed-contract-fact-quality-facets
                (source-file-typed-contract-facts file)))
    (apply append
           (map higher-order-quality-facets
                (source-file-higher-order-forms file)))
    (apply append
           (map typed-combinator-style-profile-quality-facets
                (source-file-function-quality-profiles file))))))

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
                     "function-specialization-opportunity"]))
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
           (and (member "parameterized-transform" quality-facets)
                "keep lambda parameters meaningful and push repeated destructuring into named helpers")
           (and (member "case-lambda-optimization-boundary" quality-facets)
                "preserve case-lambda or common-case specialization and document the optimization boundary")
           (and (member "multi-arity-abstraction" quality-facets)
                "use case-lambda when a helper has real arity variants instead of branching on raw argument lists")
           (and (member "function-specialization-abstraction" quality-facets)
                "use cut/curry/rcurry for first-class specialization instead of repeated wrapper lambdas")
           (and (member "function-pipeline-abstraction" quality-facets)
                "use compose/rcompose/!>/!!> when the data flow is a reusable function pipeline")
           (and (member "base-style-combinator-composition" quality-facets)
                "model reusable data flow after gerbil-utils/base.ss combinators: compose a small first-class boundary instead of expanding call-site scaffolding")
           (and (member "higher-order-constructor-abstraction" quality-facets)
                "preserve function-constructor boundaries that combine case-lambda with returned procedures")
           (and (member "arity-specialized-function-factory" quality-facets)
                "use nested case-lambda only for real arity specialization and keep the optimization boundary explicit")
           (and (member "wrapper-lambda-drift" quality-facets)
                "extract repeated wrapper lambdas into a named factory, curry/rcurry specializer, or compose/rcompose pipeline")
           (and (member "function-specialization-opportunity" quality-facets)
                "repair anonymous specialization by introducing one first-class helper boundary before changing call sites")
           (and (member "builder-or-fold-combinator" quality-facets)
                "prefer for/fold or with-list-builder only when parser facts show a real accumulator or builder boundary")]))

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
  (or (not
       (not
        (ormap (cut member <> quality-facets)
               ["manual-loop-drift"
                "over-abstracted-contract-risk"
                "scheme-native-typed-block-migration"])))
      (and (typed-combinator-style-runtime-wrapper-source-file? file)
           (not
            (not
             (ormap (cut member <> quality-facets)
                    ["wrapper-lambda-drift"
                     "function-specialization-opportunity"]))))))

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
  (unique-strings
   (apply append
          (map typed-contract-fact-reasons
               (filter invalid-typed-contract-fact?
                       (source-file-typed-contract-facts file))))))
;;; Boundary:
;;; - file-typed-contract-invalid-examples composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractExample) )
(def (file-typed-contract-invalid-examples file)
  (map typed-contract-fact-example
       (take-at-most (filter invalid-typed-contract-fact?
                             (source-file-typed-contract-facts file))
                     3)))
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
;;; Boundary:
;;; - unique-strings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List String) (List String) )
(def (unique-strings values)
  (reverse
   (foldl (lambda (value out)
            (if (member value out)
              out
              (cons value out)))
          '()
          values)))
;;; Boundary:
;;; - string-has-uppercase? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceLine Boolean )
(def (string-has-uppercase? text)
  (ormap char-upper-case? (string->list text)))
