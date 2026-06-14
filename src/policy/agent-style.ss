;;; -*- Gerbil -*-
;;; Agent-facing style policy checks.

(import :parser/facade
        :policy/agent-support
        :policy/model
        :std/srfi/13
        :std/sugar
        :support/list
        :types/findings)

(export typed-combinator-style-findings
        typed-combinator-style-finding
        controlled-branch-shape-findings
        controlled-branch-shape-finding)
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
;;; Entry boundary: emit at most one typed-combinator finding per owner so repair stays file-scoped.
;; (List TypeFinding) <- ProjectIndex
(def (typed-combinator-style-findings index)
  (filter-map (cut typed-combinator-style-finding index <>)
              (project-index-files index)))
;;; Policy gate: combine typed contracts, parser-owned implementation evidence, and coverage before repair.
;; TypeFinding <- ProjectIndex SourceFile
(def (typed-combinator-style-finding index file)
  (and (source-file-path file)
       (typed-combinator-style-source-file? index file)
       (pair? (source-file-definitions file))
       (let* ((definition-count (length (source-file-definitions file)))
              (typed-comment-summary
               (file-typed-combinator-style-summary index file))
              (typed-comment-line-count (car typed-comment-summary))
              (valid-typed-comment-count (cadr typed-comment-summary))
              (invalid-typed-comment-count (caddr typed-comment-summary))
              (missing-count
               (typed-combinator-style-missing-count definition-count
                                                     valid-typed-comment-count))
              (implementation-evidence
               (typed-combinator-style-implementation-evidence file))
              (implementation-evidence-count
               (length implementation-evidence))
              (quality-facets
               (typed-combinator-style-quality-facets file))
              (repair-evidence
               (typed-combinator-style-repair-evidence file))
              (quality-repair-triggered?
               (typed-combinator-style-quality-repair-triggered? quality-facets))
              (module-engineering-comment?
               (source-file-has-engineering-module-comment? file))
              (implementation-evidence-callers
               (typed-combinator-style-evidence-callers implementation-evidence))
              (covered-definition-names
               (typed-combinator-style-covered-definition-names
                file implementation-evidence-callers))
              (covered-definition-count
               (length covered-definition-names))
              (function-definition-count
               (length (typed-combinator-style-function-definitions file)))
              (minimum-covered-definition-count
               (typed-combinator-style-minimum-covered-definition-count
                function-definition-count))
              (uncovered-definition-names
               (typed-combinator-style-uncovered-definition-names
                file implementation-evidence-callers))
              (missing-implementation-evidence?
               (typed-combinator-style-missing-implementation-evidence?
                definition-count
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
                      implementation-coverage-insufficient?])
              (make-type-finding
               (policy-rule-id +agent-typed-combinator-style-rule+)
               (policy-rule-severity +agent-typed-combinator-style-rule+)
               (source-file-path file)
               (typed-combinator-style-message definition-count
                                               valid-typed-comment-count
                                               invalid-typed-comment-count
                                               missing-implementation-evidence?
                                               implementation-coverage-insufficient?
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
                quality-facets
                repair-evidence
                quality-repair-triggered?))))))

;;; Repair payload: keep agent-facing fields bounded while preserving enough evidence to edit safely.
;; PolicyDetails <- SourceFile Nat Nat Nat Nat Nat Evidence Nat Boolean Coverage QualityFacets RepairEvidence Boolean
(def (typed-combinator-style-details file definition-count typed-comment-line-count valid-typed-comment-count invalid-typed-comment-count missing-count implementation-evidence implementation-evidence-count missing-implementation-evidence? implementation-evidence-callers covered-definition-names covered-definition-count function-definition-count minimum-covered-definition-count uncovered-definition-names implementation-coverage-insufficient? quality-facets repair-evidence quality-repair-triggered?)
  (hash (styleGuide "typed-combinator-style")
        (styleCommand "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
        (expectedCommentPrefix ";;")
        (expectedCommentShape "adjacent contract block such as ;; (Z <- YY) <- (Z <- XX YY) XX")
        (signatureShape "adjacent Haskell-like transform signature block, one or more lines, no inline function name")
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
         "parser-owned typedContractFacts.qualityFacets derived from native call, higher-order, and control-flow facts")
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

;;; Scope boundary: typed-combinator style applies to runtime source and tests, not generated caches.
;; Boolean <- ProjectIndex SourceFile
(def (typed-combinator-style-source-file? index file)
  (let (path (source-file-path file))
    (and path
         (ormap (lambda (accept?) (accept? path))
                [(cut index-source-runtime-file-path? index <>)
                 (cut string-prefix? "t/" <>)]))))
;; Boolean <- Nat Nat Nat Nat Nat
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
;; Boolean <- SourceFile
(def (source-file-has-engineering-module-comment? file)
  (ormap
   (lambda (fact)
     (and (equal? (comment-quality-fact-target-kind fact) "module")
          (pair? (comment-quality-fact-comment-lines fact))))
   (source-file-comment-quality-facts file)))
;; Boolean <- Nat Nat Nat Nat Nat Nat
(def (typed-combinator-style-implementation-coverage-insufficient? function-definition-count covered-definition-count minimum-covered-definition-count valid-typed-comment-count invalid-typed-comment-count missing-count module-engineering-comment?)
  (and (> function-definition-count 2)
       (> valid-typed-comment-count 0)
       (= invalid-typed-comment-count 0)
       (= missing-count 0)
       (not module-engineering-comment?)
       (< covered-definition-count minimum-covered-definition-count)))
;; Nat <- Nat
(def (typed-combinator-style-minimum-covered-definition-count function-definition-count)
  (if (zero? function-definition-count)
    0
    (quotient (+ function-definition-count 1) 2)))
;;; Coverage denominator: constants are excluded so only arity-bearing helpers need expression evidence.
;; (List Definition) <- SourceFile
(def (typed-combinator-style-function-definitions file)
  (filter (lambda (defn) (> (definition-arity defn) 0))
          (source-file-definitions file)))
;;; Coverage numerator: parser evidence is attributed by caller before compacting duplicate facts.
;; (List String) <- (List Evidence)
(def (typed-combinator-style-evidence-callers implementation-evidence)
  (unique-strings
   (filter non-empty-string?
           (map (lambda (evidence) (hash-get evidence 'caller))
                implementation-evidence))))
;; Boolean <- String
(def (non-empty-string? value)
  (and (string? value)
       (> (string-length value) 0)))
;;; Coverage report: expose covered helpers so agents can see which functions already match the style.
;; (List String) <- SourceFile (List String)
(def (typed-combinator-style-covered-definition-names file implementation-evidence-callers)
  (filter (cut member <> implementation-evidence-callers)
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Repair target list: uncovered helpers tell the agent where to add expression-level evidence first.
;; (List String) <- SourceFile (List String)
(def (typed-combinator-style-uncovered-definition-names file implementation-evidence-callers)
  (filter (lambda (name) (not (member name implementation-evidence-callers)))
          (map definition-name
               (typed-combinator-style-function-definitions file))))
;;; Boundary:
;;; - typed-combinator-style-implementation-evidence composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Evidence) <- SourceFile
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
;; (List QualityFacet) <- SourceFile
(def (typed-combinator-style-quality-facets file)
  (unique-strings
   (append
    (apply append
           (map typed-contract-fact-quality-facets
                (source-file-typed-contract-facts file)))
    (apply append
           (map higher-order-quality-facets
                (source-file-higher-order-forms file))))))

;;; Native facet steering turns parser-owned Gerbil quality facts into bounded repair moves.
;;; This keeps agent freedom in naming while constraining the rewrite strategy to witnessed syntax.
;; (List RepairMove) <- (List QualityFacet)
(def (typed-combinator-style-quality-facet-steering quality-facets)
  (filter identity
          [(and (member "expression-level-composition" quality-facets)
                "prefer map/filter/filter-map/fold pipelines; extract predicate, mapper, or reducer helpers before rewriting loops")
           (and (member "combinator-composition" quality-facets)
                "prefer cut/curry/rcurry/compose helper composition when arity evidence already matches")
           (and (member "case-lambda-optimization-boundary" quality-facets)
                "preserve case-lambda or common-case specialization and document the optimization boundary")
           (and (member "builder-or-fold-combinator" quality-facets)
                "prefer for/fold or with-list-builder only when parser facts show a real accumulator or builder boundary")]))

;;; Repair evidence carries concrete parser witnesses into guide output.
;;; Agents may choose the rewrite shape, but the witness set stays bounded.
;; (List RepairEvidence) <- SourceFile
(def (typed-combinator-style-repair-evidence file)
  (map typed-contract-fact-repair-evidence
       (source-file-typed-contract-facts file)))

;;; Quality facets can explain improvement opportunities without failing check.
;;; Hard findings come from missing/invalid contracts or insufficient evidence.
;; Boolean <- (List QualityFacet)
(def (typed-combinator-style-quality-repair-triggered? quality-facets)
  (not
   (not
    (ormap (cut member <> quality-facets)
           ["manual-loop-drift"
            "over-abstracted-contract-risk"]))))

;;; Boundary:
;;; - typed-combinator-style-higher-order-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- HigherOrderFact
(def (typed-combinator-style-higher-order-fact? fact)
  (ormap (cut equal? (higher-order-fact-role fact) <>)
         +typed-combinator-style-higher-order-roles+))
;;; Boundary:
;;; - typed-combinator-style-call-fact? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- CallFact
(def (typed-combinator-style-call-fact? fact)
  (ormap (cut equal? (call-fact-callee fact) <>)
         +typed-combinator-style-call-heads+))
;; Evidence <- HigherOrderFact
(def (higher-order-style-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (caller (or (higher-order-fact-caller fact) ""))
        (selector (higher-order-fact-selector fact))))
;; Evidence <- CallFact
(def (call-style-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (caller (or (call-fact-caller fact) ""))
        (selector (call-fact-selector fact))))
;;; Boundary:
;;; - controlled-branch-shape-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (controlled-branch-shape-findings index)
  (apply append
         (map (cut file-controlled-branch-shape-findings index <>)
              (project-index-files index))))
;;; Boundary:
;;; - file-controlled-branch-shape-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex SourceFile
(def (file-controlled-branch-shape-findings index file)
  (if (index-source-runtime-file-path? index (source-file-path file))
    (filter-map (cut controlled-branch-shape-finding file <>)
                (controlled-branch-shape-groups
                 (filter controlled-branch-shape-control-flow?
                         (source-file-control-flow-forms file))))
    '()))
;; Boolean <- ControlFlowFact
(def (pattern-branch-control-flow? fact)
  (equal? (control-flow-fact-role fact) "pattern-branch"))
;; Boolean <- ControlFlowFact
(def (manual-loop-control-flow? fact)
  (equal? (control-flow-fact-role fact) "manual-loop"))
;;; Boundary:
;;; - controlled-branch-shape-control-flow? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ControlFlowFact
(def (controlled-branch-shape-control-flow? fact)
  (ormap (lambda (predicate) (predicate fact))
         [pattern-branch-control-flow?
          manual-loop-control-flow?]))
;;; Boundary:
;;; - controlled-branch-shape-groups composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List ControlFlowGroup) <- (List ControlFlowFact)
(def (controlled-branch-shape-groups facts)
  (foldl (lambda (fact groups)
           (add-control-flow-shape-group groups fact))
         '()
         facts))
;; (List ControlFlowGroup) <- (List ControlFlowGroup) ControlFlowFact
(def (add-control-flow-shape-group groups fact)
  (let* ((key (control-flow-shape-group-key fact))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons fact (cdr prior)))
            (remove-control-flow-shape-group key groups))
      (cons (cons key [fact]) groups))))
;;; Boundary:
;;; - remove-control-flow-shape-group composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List ControlFlowGroup) <- ControlFlowCaller (List ControlFlowGroup)
(def (remove-control-flow-shape-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))
;; (List ControlFlowFact) <- ControlFlowFact
(def (control-flow-shape-group-key fact)
  (or (control-flow-fact-caller fact) "<top-level>"))
;;; Boundary:
;;; - controlled-branch-shape-kind composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- ControlFlowGroup
(def (controlled-branch-shape-kind group)
  (let* ((facts (cdr group))
         (pattern-facts (filter pattern-branch-control-flow? facts))
         (manual-loop-facts (filter state-selector-manual-loop? facts)))
    (cond
     ((> (length pattern-facts) 1) "repeated-pattern-branch")
     ((and (pair? pattern-facts) (pair? manual-loop-facts))
      "pattern-branch-with-manual-loop")
     (else #f))))
;; Boolean <- ControlFlowFact
(def (state-selector-manual-loop? fact)
  (and (manual-loop-control-flow? fact)
       (>= (control-flow-fact-binding-count fact) 4)
       (<= (control-flow-fact-line-span fact) 24)))
;; Integer <- ControlFlowFact
(def (control-flow-fact-line-span fact)
  (fx1+ (- (control-flow-fact-end fact)
           (control-flow-fact-start fact))))
;;; Boundary:
;;; - controlled-branch-shape-finding composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; TypeFinding <- SourceFile ControlFlowGroup
(def (controlled-branch-shape-finding file group)
  (let (shape-kind (controlled-branch-shape-kind group))
    (and shape-kind
         (let* ((caller (car group))
                (facts (cdr group))
                (pattern-facts (filter pattern-branch-control-flow? facts))
                (manual-loop-facts (filter state-selector-manual-loop? facts))
                (first-fact (earliest-control-flow-fact facts)))
           (make-type-finding
            (policy-rule-id +agent-controlled-branch-shape-rule+)
            (policy-rule-severity +agent-controlled-branch-shape-rule+)
            (source-file-path file)
            (controlled-branch-shape-message caller shape-kind)
            (control-flow-fact-selector first-fact)
            (controlled-branch-shape-details
             caller
             shape-kind
             pattern-facts
             manual-loop-facts
             first-fact))))))

;; PolicyDetails <- String String ControlFlowFacts ControlFlowFacts ControlFlowFact
(def (controlled-branch-shape-details caller shape-kind pattern-facts manual-loop-facts first-fact)
  (hash (caller caller)
        (shape shape-kind)
        (matchCount (length pattern-facts))
        (manualLoopCount (length manual-loop-facts))
        (selector (control-flow-fact-selector first-fact))
        (evidence "parser-owned controlFlowFacts role=pattern-branch plus manual-loop bindingCount>=4")
        (advice "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
        (styleGuide "controlled-branch-shape")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")
        (rewriteScope "same caller or extracted helper only")
        (qualityReference "gerbil-utils")
        (functionShape "small selector/predicate/helper first; keep match branches shallow and expression-returning")
        (agentRepairStandard "rewrite toward gerbil-utils style: extract branch selectors, replace stateful named-let with fold/filter-map when pure, keep IO/state drivers explicit")
        (expressionLevelRewrite "turn repeated match plus accumulator shape into a named predicate/mapper/reducer pipeline before changing behavior")
        (next "guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")))
;; Message <- String String
(def (controlled-branch-shape-message caller shape-kind)
  (cond
   ((equal? shape-kind "pattern-branch-with-manual-loop")
    (string-append "caller " caller
                   " combines match state destructuring with a named-let loop; keep the repair policy-driven, split the selector/update step or use a bounded pipeline before editing for style or performance"))
   (else
    (string-append "caller " caller
                   " has repeated match branches; keep the repair policy-driven, split nested branch logic into named helpers or a bounded selector pipeline before editing for style or performance"))))
;;; Boundary:
;;; - earliest-control-flow-fact composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ControlFlowFact <- (NonEmptyList ControlFlowFact)
(def (earliest-control-flow-fact facts)
  (foldl (lambda (fact earliest)
           (if (< (control-flow-fact-start fact)
                  (control-flow-fact-start earliest))
             fact
             earliest))
         (car facts)
         (cdr facts)))
;;; Boundary:
;;; - typed-combinator-style-message coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Message <- DefinitionCount ValidContractCount InvalidContractCount Boolean Boolean Nat Nat Nat
(def (typed-combinator-style-message definition-count typed-comment-count invalid-typed-comment-count missing-implementation-evidence? implementation-coverage-insufficient? covered-definition-count function-definition-count minimum-covered-definition-count)
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
   "; typed-combinator-style has three criteria: adjacent Haskell-like transform signature block such as ;; (Z <- YY) <- (Z <- XX YY) XX, compact expression-level composition, and optimization-boundary comments for specialized branches"))
;; Integer <- Integer Integer
(def (typed-combinator-style-missing-count definition-count typed-comment-count)
  (if (> definition-count typed-comment-count)
    (- definition-count typed-comment-count)
    0))
;; ContractSummary <- ProjectIndex SourceFile
(def (file-typed-combinator-style-summary index file)
  (typed-contract-fact-summary (source-file-typed-contract-facts file)))
;; Integer <- ProjectIndex SourceFile
(def (file-typed-combinator-style-count index file)
  (cadr (file-typed-combinator-style-summary index file)))
;;; Boundary:
;;; - typed-contract-fact-summary composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ContractSummary <- (List TypedContractFact)
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
;; (List InvalidContractReason) <- SourceFile
(def (file-typed-contract-invalid-reasons file)
  (unique-strings
   (apply append
          (map typed-contract-fact-reasons
               (filter invalid-typed-contract-fact?
                       (source-file-typed-contract-facts file))))))
;;; Boundary:
;;; - file-typed-contract-invalid-examples composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List InvalidContractExample) <- SourceFile
(def (file-typed-contract-invalid-examples file)
  (map typed-contract-fact-example
       (take-at-most (filter invalid-typed-contract-fact?
                             (source-file-typed-contract-facts file))
                     3)))
;; Boolean <- TypedContractFact
(def (invalid-typed-contract-fact? fact)
  (equal? (typed-contract-fact-quality fact) "invalid"))
;; InvalidContractExample <- TypedContractFact
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
;; (List String) <- (List String)
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
;; Boolean <- SourceLine
(def (string-has-uppercase? text)
  (ormap char-upper-case? (string->list text)))
