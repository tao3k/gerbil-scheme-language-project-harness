;;; -*- Gerbil -*-
;;; Parser-owned function quality profiles composed from native facts.

(import :parser/model
        :parser/higher-order
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar cut filter find foldl ormap)
        :support/list)

(export function-quality-profiles-from-source)

;;; Profile fan-out is a pure definition-to-profile transform.
;;; The cut captures shared owner evidence once, then map keeps each function
;;; profile independent so policy can repair one function boundary at a time.
;; : (-> Relpath Exports Definitions TypedContracts CommentFacts ControlFlowFacts HigherOrderFacts PredicateFamilies FieldAccessFacts LoopDrivers MacroFacts PooFacts (List FunctionQualityProfile) )
(def (function-quality-profiles-from-source relpath exports definitions typed-contracts comment-facts control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (map (cut function-quality-profile-from-definition
            relpath exports <>
            typed-contracts comment-facts
            control-flow-forms higher-order-forms
            predicate-family-facts field-access-pattern-facts
            loop-driver-facts macros poo-forms)
       definitions))

;;; Profile materialization stays parser-owned: policy receives one
;;; function-level packet instead of re-joining typed, comment, control-flow,
;;; higher-order, POO, macro, and predicate-family evidence.
;; : (-> Relpath Exports Definition TypedContracts CommentFacts ControlFlowFacts HigherOrderFacts PredicateFamilies FieldAccessFacts LoopDrivers MacroFacts PooFacts FunctionQualityProfile )
(def (function-quality-profile-from-definition relpath exports definition typed-contracts comment-facts control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (let* ((name (definition-name definition))
         (typed-contract (matching-typed-contract name typed-contracts))
         (comment-fact (matching-comment-quality name comment-facts))
         (matched-control-flow (matching-control-flow name control-flow-forms))
         (matched-higher-order (matching-higher-order name higher-order-forms))
         (matched-predicate-families (matching-predicate-families name predicate-family-facts))
         (matched-field-access (matching-field-access name field-access-pattern-facts))
         (matched-loop-drivers (matching-loop-drivers name loop-driver-facts))
         (matched-macros (matching-macros name macros))
         (matched-poo (matching-poo-protocols name poo-forms))
         (exported? (and (member name exports) #t))
         (role (function-quality-role definition exported?
                                      matched-macros matched-poo
                                      matched-loop-drivers))
         (typed-quality (if typed-contract
                          (typed-contract-fact-quality typed-contract)
                          "missing"))
         (comment-quality (if comment-fact
                            (comment-quality-fact-quality comment-fact)
                            "missing"))
         (quality-facets
          (function-quality-facets role exported? typed-quality comment-quality
                                   typed-contract comment-fact
                                   matched-control-flow matched-higher-order
                                   matched-predicate-families matched-field-access
                                   matched-loop-drivers matched-macros matched-poo))
         (preservation-reasons
          (function-quality-preservation-reasons exported?
                                                 matched-loop-drivers
                                                 matched-macros
                                                 matched-poo))
         (repair-class
          (function-quality-repair-class typed-quality comment-quality
                                         quality-facets
                                         matched-predicate-families))
         (parser-confidence
          (function-quality-parser-confidence typed-contract comment-fact
                                              matched-control-flow
                                              matched-higher-order
                                              matched-predicate-families
                                              matched-field-access
                                              matched-loop-drivers
                                              matched-macros
                                              matched-poo)))
    (make-function-quality-profile
     name
     "function-quality-profile"
     relpath
     (definition-start definition)
     (definition-end definition)
     (definition-formals definition)
     (definition-arity definition)
     role
     exported?
     typed-quality
     comment-quality
     (unique-strings (map control-flow-fact-role matched-control-flow))
     (unique-strings (map higher-order-fact-role matched-higher-order))
     (map predicate-family-fact-name matched-predicate-families)
     (map field-access-pattern-fact-name matched-field-access)
     (map loop-driver-fact-name matched-loop-drivers)
     (map macro-fact-name matched-macros)
     (map poo-form-fact-name matched-poo)
     quality-facets
     preservation-reasons
     repair-class
     parser-confidence
     (function-quality-advice repair-class preservation-reasons quality-facets))))

;;; Matching helpers keep correlation parser-owned and local to one name.
;;; `find` preserves the first adjacent typed contract fact without inventing
;;; fallback evidence from rendered comments or source text.
;; : (-> DefinitionName TypedContracts TypedContractFact )
(def (matching-typed-contract name facts)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        facts))

;;; Comment facts are keyed by definition target, not by free text.
;;; This prevents file/module comments from satisfying a function-level repair.
;; : (-> DefinitionName CommentFacts CommentQualityFact )
(def (matching-comment-quality name facts)
  (find (lambda (fact)
          (and (equal? (comment-quality-fact-target-kind fact) "definition")
               (equal? (comment-quality-fact-target-name fact) name)))
        facts))

;;; Control-flow correlation is caller-owned.
;;; The filter keeps loops, continuations, and resource scopes attached to the
;;; function that would be rewritten by a style policy.
;; : (-> DefinitionName ControlFlowFacts (List ControlFlowFact) )
(def (matching-control-flow name facts)
  (filter (lambda (fact)
            (equal? (or (control-flow-fact-caller fact) "") name))
          facts))

;;; Higher-order evidence is caller-owned.
;;; The filtered roles show whether a function already uses map/filter/fold/cut
;;; or needs a combinator-style repair.
;; : (-> DefinitionName HigherOrderFacts (List HigherOrderFact) )
(def (matching-higher-order name facts)
  (filter (lambda (fact)
            (equal? (or (higher-order-fact-caller fact) "") name))
          facts))

;;; Predicate-family facts point back to predicate function names.
;;; Filtering by membership lets policy repair repeated predicate shape without
;;; scanning source bodies again.
;; : (-> DefinitionName PredicateFamilies (List PredicateFamilyFact) )
(def (matching-predicate-families name facts)
  (filter (lambda (fact)
            (member name (predicate-family-fact-predicate-names fact)))
          facts))

;;; Field-access patterns record callers that repeat the same selector shape.
;;; Filtering by caller keeps selector-helper advice scoped to the functions
;;; that own the repeated access.
;; : (-> DefinitionName FieldAccessFacts (List FieldAccessPatternFact) )
(def (matching-field-access name facts)
  (filter (lambda (fact)
            (member name (field-access-pattern-fact-callers fact)))
          facts))

;;; Loop-driver facts can name either the loop or its enclosing function.
;;; Both links are preserved so pure-transform repair does not erase IO/state
;;; driver boundaries.
;; : (-> DefinitionName LoopDrivers (List LoopDriverFact) )
(def (matching-loop-drivers name facts)
  (filter (lambda (fact)
            (or (equal? (loop-driver-fact-name fact) name)
                (equal? (or (loop-driver-fact-caller fact) "") name)))
          facts))

;;; Macro matching marks transformer-owned helpers as preservation boundaries.
;;; A name match is enough here because macro facts already carry parser-owned
;;; selectors and quality facets.
;; : (-> DefinitionName MacroFacts (List MacroFact) )
(def (matching-macros name facts)
  (filter (lambda (fact)
            (equal? (macro-fact-name fact) name))
          facts))

;;; POO facts can relate through class/protocol name, generic, or receiver.
;;; The disjunction keeps method and receiver evidence attached before policy
;;; suggests object-system repairs.
;; : (-> DefinitionName PooFacts (List PooFormFact) )
(def (matching-poo-protocols name facts)
  (filter (lambda (fact)
            (or (equal? (poo-form-fact-name fact) name)
                (equal? (or (poo-form-fact-generic fact) "") name)
                (equal? (or (poo-form-fact-receiver fact) "") name)))
          facts))

;;; Role classification compresses parser evidence into a repair boundary.
;;; Specific preservation roles win before generic public/internal helper roles.
;; : (-> Definition Exported? MacroFacts PooFacts LoopDrivers Role )
(def (function-quality-role definition exported? macros poo-forms loop-drivers)
  (cond
   ((pair? macros) "macro-helper")
   ((poo-method-profile? poo-forms) "protocol-method")
   ((pair? poo-forms) "poo-protocol-boundary")
   ((pair? loop-drivers) "driver")
   ((string-suffix? "?" (definition-name definition)) "predicate")
   (exported? "public-api")
   ((zero? (definition-arity definition)) "constant")
   (else "internal-helper")))

;;; Method profiles preserve protocol dispatch before generic POO evidence.
;;; The predicate stays small so role precedence remains obvious.
;; : (-> PooFacts Boolean )
(def (poo-method-profile? poo-forms)
  (ormap (lambda (fact)
           (member (poo-form-fact-role fact) '("method" "protocol")))
         poo-forms))

;;; Facet aggregation is the profile's searchable vocabulary.
;;; Each parser fact family contributes only stable role/facet tokens so search
;;; and policy can compose repairs without reading source text.
;; : (-> Role Exported? TypedQuality CommentQuality TypedContract CommentFact ControlFlow HigherOrder PredicateFamilies FieldAccess LoopDrivers Macros PooFacts (List QualityFacet) )
(def (function-quality-facets role exported? typed-quality comment-quality typed-contract comment-fact control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (unique-strings
   (filter identity
           (append ["function-quality-profile"
                    "functionQualityProfile"
                    "quality-profile"
                    "function-quality"
                    role
                    (and exported? "public-api")
                    (string-append "typed-contract-" typed-quality)
                    (string-append "comment-quality-" comment-quality)
                    (and (not typed-contract) "typed-contract-missing")
                    (and (not comment-fact) "comment-quality-missing")
                    (and (pair? predicate-family-facts)
                         "predicate-family-combinator")
                    (and (pair? field-access-pattern-facts)
                         "selector-helper")
                    (and (pair? loop-driver-facts)
                         "loop-driver-classified")
                    (and (pair? macros)
                         "macro-runtime-source-witness")
                    (and (pair? poo-forms)
                         "poo-protocol-evidence")]
                   (apply append
                          (map typed-contract-profile-facets
                               (if typed-contract [typed-contract] [])))
                   (apply append
                          (map comment-quality-fact-reasons
                               (if comment-fact [comment-fact] [])))
                   (function-quality-higher-order-profile-facets
                    higher-order-forms)
                   (map control-flow-fact-role control-flow-forms)
                   (map higher-order-fact-role higher-order-forms)
                   (apply append
                          (map higher-order-quality-facets
                               higher-order-forms))
                   (apply append
                          (map predicate-family-fact-quality-facets
                               predicate-family-facts))
                   (apply append
                          (map field-access-pattern-fact-quality-facets
                               field-access-pattern-facts))
                   (apply append
                          (map loop-driver-fact-quality-facets
                               loop-driver-facts))))))

;;; Typed-contract profile facets forward parser-owned contract quality.
;;; Keeping this as a helper makes the aggregate facet pipeline uniform.
;; : (-> TypedContractFact (List QualityFacet) )
(def (typed-contract-profile-facets fact)
  (typed-contract-fact-quality-facets fact))

;;; Higher-order profile facets distinguish good gerbil-utils/base.ss-style
;;; constructor abstraction from anonymous wrapper drift.  The drift facet is
;;; intentionally conjunctive: repeated lambdas alone are not enough. Sequence,
;;; arity, generator, or combinator witnesses suppress the warning.
;;; This keeps policy free to warn on real function factory opportunities
;;; without treating callback-heavy code as low-quality Scheme.
;; : (-> (List HigherOrderFact) (List QualityFacet) )
(def (function-quality-higher-order-profile-facets higher-order-forms)
  (let* ((anonymous-count
          (function-quality-higher-order-role-count
           higher-order-forms "anonymous-function"))
         (multi-arity?
          (function-quality-higher-order-role? higher-order-forms
                                               "multi-arity-function"))
         (specializer?
          (function-quality-higher-order-any-role?
           higher-order-forms
           ["partial-application" "function-curry"]))
         (pipeline?
          (function-quality-higher-order-any-role?
           higher-order-forms
           ["function-composition" "pipeline-composition"]))
         (sequence?
          (function-quality-higher-order-any-role?
           higher-order-forms
           ["sequence-map" "sequence-filter" "sequence-filter-map"
            "sequence-append-map" "sequence-predicate" "sequence-search"
            "sequence-fold"]))
         (driver?
          (function-quality-higher-order-any-role?
           higher-order-forms
           ["generator-transform" "generator-control-inversion"
            "stateful-protocol-wrapper" "loop-fold" "list-builder"]))
         (constructor?
          (and multi-arity?
               (or (> anonymous-count 0) specializer? pipeline?)))
         (wrapper-drift?
          (and (>= anonymous-count 3)
               (function-quality-repeated-anonymous-formals?
                higher-order-forms 3)
               (not multi-arity?)
               (not specializer?)
               (not pipeline?)
               (not sequence?)
               (not driver?))))
    (filter identity
            [(and (or specializer? pipeline?)
                  "base-style-combinator-composition")
             (and constructor?
                  "higher-order-constructor-abstraction")
             (and (and constructor? (> anonymous-count 0))
                  "arity-specialized-function-factory")
             (and wrapper-drift?
                  "wrapper-lambda-drift")
             (and wrapper-drift?
                  "function-specialization-opportunity")])))

;;; Role counts stay local to one function profile so repeated syntax in another
;;; definition cannot accidentally raise a repair signal.
;; : (-> (List HigherOrderFact) Role Integer )
(def (function-quality-higher-order-role-count higher-order-forms role)
  (length
   (filter (lambda (fact)
             (equal? (higher-order-fact-role fact) role))
           higher-order-forms)))

;;; A profile-level role predicate keeps the constructor/drift combinator easy
;;; to read without duplicating the fact role lookup at each gate.
;; : (-> (List HigherOrderFact) Role Boolean )
(def (function-quality-higher-order-role? higher-order-forms role)
  (> (function-quality-higher-order-role-count higher-order-forms role) 0))

;;; Any-role checks encode the positive witnesses that suppress wrapper drift:
;;; sequence transforms, case-lambda factories, generators, and combinators.
;; : (-> (List HigherOrderFact) (List Role) Boolean )
(def (function-quality-higher-order-any-role? higher-order-forms roles)
  (ormap (lambda (fact)
           (member (higher-order-fact-role fact) roles))
         higher-order-forms))

;;; Repeated anonymous formals are the parser-owned approximation for function
;;; factory drift. Empty thunks and placeholder callbacks are filtered out below.
;;; The repeated shape must occur inside one caller profile, which prevents
;;; unrelated lambdas elsewhere in the owner from combining into a warning.
;; : (-> (List HigherOrderFact) Nat Boolean )
(def (function-quality-repeated-anonymous-formals? higher-order-forms minimum-count)
  (ormap (lambda (fact)
           (and (equal? (higher-order-fact-role fact) "anonymous-function")
                (function-quality-informative-formals?
                 (higher-order-fact-formals fact))
                (>= (function-quality-anonymous-formals-count
                     higher-order-forms
                     (higher-order-fact-formals fact))
                    minimum-count)))
         higher-order-forms))

;;; The duplicate count is shape-based rather than name-based in source text:
;;; the native lambda formal list must repeat inside the same caller profile.
;; : (-> (List HigherOrderFact) (List FormalName) Integer )
(def (function-quality-anonymous-formals-count higher-order-forms formals)
  (length
   (filter (lambda (fact)
             (and (equal? (higher-order-fact-role fact) "anonymous-function")
                  (equal? (higher-order-fact-formals fact) formals)))
           higher-order-forms)))

;;; Empty thunk lambdas and `_` placeholders are common test/runtime callbacks,
;;; so they cannot by themselves prove a reusable function factory opportunity.
;; : (-> (List FormalName) Boolean )
(def (function-quality-informative-formals? formals)
  (and (pair? formals)
       (not (member "_" formals))))

;;; Preservation reasons are guardrails for automated repair.
;;; Public API, macro, POO, and driver evidence become explicit constraints
;;; before style rewrites are proposed.
;; : (-> Exported? LoopDrivers MacroFacts PooFacts (List PreservationReason) )
(def (function-quality-preservation-reasons exported? loop-drivers macros poo-forms)
  (unique-strings
   (filter identity
           (append [(and exported? "preserve-public-api")
                    (and (pair? macros)
                         "macro-runtime-source-witness-required")
                    (and (pair? poo-forms)
                         "poo-protocol-boundary")]
                   (map loop-driver-preservation-reason loop-drivers)))))

;;; Loop-driver preservation separates stateful drivers from pure loops.
;;; The driver kind decides whether policy may suggest a pure transform rewrite.
;; : (-> LoopDriverFact PreservationReason )
(def (loop-driver-preservation-reason fact)
  (if (member (loop-driver-fact-driver-kind fact)
              '("io-reader-driver" "state-driver-candidate"
                "higher-order-boundary"))
    (string-append "preserve-" (loop-driver-fact-driver-kind fact))
    "pure-transform-rewrite-allowed-when-tests-preserve-behavior"))

;;; Repair class is ordered from structural drift to comment polish.
;;; Comment repair is chosen only after parser facts rule out stronger shape or
;;; boundary repairs.
;; : (-> TypedQuality CommentQuality QualityFacets PredicateFamilies RepairClass )
(def (function-quality-repair-class typed-quality comment-quality quality-facets predicate-family-facts)
  (cond
   ((pair? predicate-family-facts) "predicate-family-combinator")
   ((member "manual-loop-drift" quality-facets) "typed-combinator-style")
   ((member "wrapper-lambda-drift" quality-facets) "typed-combinator-style")
   ((member "function-specialization-opportunity" quality-facets)
    "typed-combinator-style")
   ((member typed-quality '("missing" "invalid" "weak"))
    "typed-combinator-style")
   ((member comment-quality '("missing" "absent" "weak"))
    "engineering-comment-quality")
   ((member "poo-protocol-evidence" quality-facets) "poo-policy")
   ((member "macro-runtime-source-witness" quality-facets)
    "macro-runtime-source-witness")
   (else "stable")))

;;; Parser confidence is a simple evidence count, not a semantic proof.
;;; It tells downstream ranking how much native evidence backs the profile.
;; : (-> TypedContract CommentFact ControlFlow HigherOrder PredicateFamilies FieldAccess LoopDrivers MacroFacts PooFacts ParserConfidence )
(def (function-quality-parser-confidence typed-contract comment-fact control-flow-forms higher-order-forms predicate-family-facts field-access-pattern-facts loop-driver-facts macros poo-forms)
  (let (evidence-count
        (+ (if typed-contract 1 0)
           (if comment-fact 1 0)
           (length control-flow-forms)
           (length higher-order-forms)
           (length predicate-family-facts)
           (length field-access-pattern-facts)
           (length loop-driver-facts)
           (length macros)
           (length poo-forms)))
    (cond
     ((>= evidence-count 4) "high")
     ((>= evidence-count 2) "medium")
     (else "baseline"))))

;;; Advice is intentionally compact because LLM repair receives the profile too.
;;; The text names the repair direction while preservation reasons carry the
;;; concrete constraints.
;; : (-> RepairClass PreservationReasons QualityFacets Advice )
(def (function-quality-advice repair-class preservation-reasons quality-facets)
  (cond
   ((equal? repair-class "predicate-family-combinator")
    "repair predicate drift with small selector helpers or a bounded predicate combinator; keep public predicate names stable")
   ((member "wrapper-lambda-drift" quality-facets)
    "replace repeated wrapper lambdas with a named function factory, cut/curry/rcurry, or compose/rcompose pipeline; use case-lambda when arity variants are real")
   ((member "function-specialization-opportunity" quality-facets)
    "turn repeated anonymous specialization into a first-class helper boundary before editing call sites")
   ((equal? repair-class "typed-combinator-style")
    "prefer small expression-returning helpers and map/filter/fold/cut when parser facts show pure transform drift")
   ((equal? repair-class "engineering-comment-quality")
    "write as many adjacent engineering comment lines as the parser evidence needs after code shape is stable")
   ((equal? repair-class "poo-policy")
    "preserve defclass/defgeneric/defmethod/defprotocol boundaries and cite parser-owned receiver evidence")
   ((equal? repair-class "macro-runtime-source-witness")
    "check runtime-source macro witness before editing transformers")
   ((pair? preservation-reasons)
    "preserve public, macro, POO, IO, or state boundaries before style repair")
   (else "no policy repair is implied; profile is available for search and future correlation")))

;;; Stable unique strings keep facet order deterministic for snapshots.
;;; False values are discarded before dedupe so optional evidence does not leak
;;; placeholder tokens.
;; : (-> (List String) (List String) )
(def (unique-strings values)
  (reverse
   (foldl (lambda (value out)
            (if (or (not value) (member value out))
              out
              (cons value out)))
          '()
          values)))
