;;; -*- Gerbil -*-
;;; Gerbil-specific style signals for R013 typed-combinator guidance.

(import :parser/facade
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter ormap))

(export typed-combinator-style-generator-quality-facets
        +typed-comment-metadata-fields+
        +gerbil-utils-implementation-signals+
        +gerbil-contract-projection-signals+
        typed-combinator-style-anti-ai-scaffold-quality-facets
        typed-combinator-style-anti-ai-scaffold-signals
        typed-combinator-style-anti-ai-scaffold-targets
        typed-combinator-style-list-combinator-quality-facets
        typed-combinator-style-list-combinator-signals
        typed-combinator-style-list-combinator-targets
        typed-combinator-style-generator-combinator-signals
        typed-combinator-style-generator-contract-targets
        typed-combinator-style-serialization-boundary-quality-facets
        typed-combinator-style-serialization-boundary-signals
        typed-combinator-style-serialization-boundary-targets
        typed-combinator-style-slot-lens-boundary-quality-facets
        typed-combinator-style-slot-lens-boundary-signals
        typed-combinator-style-slot-lens-boundary-targets
        typed-combinator-style-concurrency-control-quality-facets
        typed-combinator-style-concurrency-control-signals
        typed-combinator-style-concurrency-control-targets
        typed-combinator-style-exception-continuation-boundary-quality-facets
        typed-combinator-style-exception-continuation-boundary-signals
        typed-combinator-style-exception-continuation-boundary-targets
        typed-combinator-style-controlled-macro-quality-facets
        typed-combinator-style-controlled-macro-syntax-signals
        typed-combinator-style-controlled-macro-targets
        typed-combinator-style-typeclass-quality-facets
        typed-combinator-style-typeclass-algebra-signals
        typed-combinator-style-typeclass-algebra-targets)

;;; Boundary:
;;; - This owner converts parser facts into bounded R013 steering signals.
;;; - It does not decide whether a finding should fire.
;;; - agent-style.ss owns policy triggering and message assembly.
;;; - Keeping these signals separate prevents the main policy owner from
;;;   becoming a sink for every Gerbil library idiom.

;;; Payload boundary:
;;; - These fields are provider-owned typedComment projection slots.
;;; - Keep them stable so policy details and JSON facts use one vocabulary.
;; (List String)
(def +typed-comment-metadata-fields+
  ["leadingName" "signatureType" "localTypes" "runtimeContracts"
   "runtimeContractsDetailed" "requires" "requiresDetailed"
   "warnings" "rationales" "docs" "docs.examples"
   "docs.hasResultExamples" "refinements"])

;;; Exemplar boundary:
;;; - These are gerbil-utils style signals, not mandatory syntax forms.
;;; - They steer repair suggestions without making policy depend on one library.
;; (List String)
(def +gerbil-utils-implementation-signals+
  ["λ/lambda-match local destructuring"
   "fun named lambda abstraction"
   "!>/!!> pipeline"
   "apply compose"
   "cut/curry/rcurry"
   "syntax-case/syntax-rules hygienic macro boundary"
   "map/filter/filter-map/fold"
   "with-list-builder"])

;;; Projection boundary:
;;; - These strings describe how upstream Gerbil contracts reach harness facts.
;;; - Keep agent guidance tied to projection evidence instead of invented grammar.
;; (List String)
(def +gerbil-contract-projection-signals+
  ["legacy contracts split at top-level <-, not nested arrows"
   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"])

;;; Facet helper boundary:
;;; - Converts proven parser facts into one public quality facet.
;;; - Empty facts mean no guidance; callers still own fact discovery.
;; : (forall (fact) (-> (List fact) QualityFacet (List QualityFacet)) )
(def (typed-combinator-style-facts->quality-facet facts facet)
  (if (pair? facts) [facet] []))

;;; Signal helper boundary:
;;; - Keeps feature signal lists declarative beside each feature owner.
;;; - The helper only gates on parser facts and never performs detection.
;; : (forall (fact) (-> (List fact) (List String) (List String)) )
(def (typed-combinator-style-facts->signals facts signals)
  (if (pair? facts) signals []))

;;; Target helper boundary:
;;; - Projects parser fact owners into compact policy target names.
;;; - The accessor keeps typed-contract, macro, and POO facts separate.
;; : (forall (fact) (-> (List fact) (-> fact TargetName) (List TargetName)) )
(def (typed-combinator-style-facts->targets facts target-name)
  (map target-name facts))

;;; Anti-scaffold boundary:
;;; - gerbil-poo/io.ss and fun.ss teach protocol layers, not copyable code.
;;; - Emit this only when existing parser facts prove collapsed representation
;;;   or POO algebra responsibilities in one owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-anti-ai-scaffold-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-anti-ai-scaffold-facts file)
   "anti-ai-scaffold-boundary"))

;;; Guidance boundary:
;;; - Signals name repair moves for generated-looking protocol scaffolds.
;;; - They do not require importing gerbil-poo or gerbil-utils downstream.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-anti-ai-scaffold-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-anti-ai-scaffold-facts file)
   ["replace one-owner protocol conversion scaffolding with local adapter boundaries"
    "prefer define-type methods.* or named protocol helpers over hand-written dispatch tables"
    "use compose when json/string adapter flow is a direct transform"
    "keep marshal self-delimiting and bytes representation-only boundaries separate"
    "lift wrapper IO/JSON/bytes/marshal through wrap/unwrap when a typeclass wrapper is present"]))

;;; Target boundary:
;;; - Reuse the precise targets from proven feature facts.
;;; - The target list points at the collapsed local owner, not reference repos.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-anti-ai-scaffold-targets file)
  (append
   (typed-combinator-style-serialization-boundary-targets file)
   (typed-combinator-style-typeclass-algebra-targets file)))

;;; Fact boundary:
;;; - Anti-scaffold evidence is a union of existing parser-owned facts.
;;; - No implementation text scanning is allowed here.
;; : (-> SourceFile (List ParserOwnedFact) )
(def (typed-combinator-style-anti-ai-scaffold-facts file)
  (append
   (typed-combinator-style-serialization-boundary-facts file)
   (typed-combinator-style-typeclass-poo-forms file)))

;;; List combinator boundary:
;;; - gerbil-utils/list.ss and base.ss teach list traversal expression shape.
;;; - Emit only when parser facts prove both a List contract and manual-loop
;;;   drift in the same owner.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-list-combinator-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-list-combinator-facts file)
   "list-combinator-boundary"))

;;; Guidance boundary:
;;; - Signals name local repair moves for generated-looking list traversal.
;;; - They do not require importing gerbil-utils downstream.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-list-combinator-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-list-combinator-facts file)
   ["replace hand-written list recursion scaffolding with map/filter/fold or a named reducer boundary"
    "use lambda-match at the list destructuring boundary when pair shape is the point"
    "prefer filter-map when selection and projection happen in the same traversal"
    "use with-list-builder only when output construction needs an explicit builder"]))

;;; Target boundary:
;;; - Report typed-contract owners with proven list traversal drift.
;;; - The target list stays local to the owner being repaired.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-list-combinator-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-list-combinator-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - A List contract alone is not enough: the parser must also classify a
;;;   manual loop profile for this owner.
;;; - The filter remains typed-contract based so policy does not read source.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-list-combinator-facts file)
  (if (typed-combinator-style-list-combinator-profile? file)
    (filter typed-combinator-style-list-combinator-fact?
            (source-file-typed-contract-facts file))
    []))

;;; Profile gate:
;;; - Manual-loop drift is parser-owned shape evidence.
;;; - Positive sequence roles alone must not trigger this anti-scaffold facet.
;; : (-> SourceFile Boolean )
(def (typed-combinator-style-list-combinator-profile? file)
  (ormap (lambda (profile)
           (member "manual-loop-drift"
                   (function-quality-profile-quality-facets profile)))
         (source-file-function-quality-profiles file)))

;;; Contract gate:
;;; - Require an explicit list traversal contract, not an arbitrary List type.
;;; - Scenario fixtures may use legacy projection comments while production
;;;   owners can use typed-combinator-style blocks.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-list-combinator-fact? fact)
  (and (typed-contract-fact-mentions-any?
        fact
        ["List" "NonEmptyList" "list"])
       (typed-contract-fact-mentions-any?
        fact
        ["Map" "map" "Filter" "filter" "Fold" "fold" "Builder" "builder"
         "Traversal" "traversal"])))

;;; Generator contracts are first-class style evidence.  They should steer the
;;; agent toward named generator protocol boundaries instead of ad hoc producer
;;; loops. gerbil-utils/generator.ss is the reference corpus, not a required
;;; downstream dependency.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-generator-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-generator-contract-facts file)
   "generator-combinator-boundary"))

;;; Signal boundary:
;;; - Generator guidance is emitted only when typed-contract facts prove it.
;;; - Empty output means the caller should not recommend generator rewrites.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-generator-combinator-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-generator-contract-facts file)
   ["Generating contract projection"
    "generating<-list source adapter"
    "generating-map transform"
    "generating-fold reducer"
    "generating-partition split"
    "generating-merge priority merge"
    "generating<-cothread continuation bridge"]))

;;; Target projection keeps the public policy payload compact.
;;; Mapping over facts is safe here because the detector already filtered to
;;; generator contracts; no fallback source scan is needed.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-generator-contract-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-generator-contract-facts file)
   typed-contract-fact-definition-name))

;;; Boundary:
;;; - Generator detection is derived from typed-contract facts.
;;; - Output, inputs, and tokens are all checked because legacy contracts can
;;;   carry `Generating` at different nesting levels.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-generator-contract-facts file)
  (filter typed-combinator-style-generator-contract-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - A generator contract can mention `Generating` in output, input, or tokens.
;;; - The ormap path preserves nested legacy contracts without flattening them
;;;   into raw text heuristics.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-generator-contract-fact? fact)
  (or (member "Generating" (typed-contract-fact-tokens fact))
      (and (string? (typed-contract-fact-contract-output fact))
           (string-contains (typed-contract-fact-contract-output fact)
                            "Generating"))
      (ormap (lambda (input)
               (and (string? input)
                    (string-contains input "Generating")))
             (typed-contract-fact-contract-inputs fact))))

;;; Serialization protocol boundaries are learned from reference corpus style,
;;; not from package dependencies.  A finding is only exposed when one contract
;;; collapses three or more representation layers into the same owner boundary.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-serialization-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-serialization-boundary-facts file)
   "protocol-serialization-boundary"))

;;; Guidance boundary:
;;; - Signals name local repair moves, not reference package APIs.
;;; - Empty output keeps ordinary typed-contract files out of serialization
;;;   guidance unless the mixed-representation fact is proven.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-serialization-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-serialization-boundary-facts file)
   ["split JSON/string/bytes/marshal representation layers"
    "keep marshal boundaries self-delimited"
    "keep raw bytes adapters non-self-delimited"
    "preserve reader/writer symmetry through local protocol helpers"]))

;;; Target boundary:
;;; - Report only definition names from parser-owned typed-contract facts.
;;; - The policy payload stays compact and avoids source snippets.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-serialization-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-serialization-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This avoids raw text scans while still supporting legacy contract syntax.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-serialization-boundary-facts file)
  (filter typed-combinator-style-serialization-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Three representation categories mark a collapsed protocol owner.
;;; - One- or two-step local adapters remain valid expected repairs.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-serialization-boundary-fact? fact)
  (>= (length (typed-combinator-style-serialization-boundary-categories fact))
      3))

;;; Category boundary:
;;; - Categories are representation layers, not exact type names.
;;; - The list is intentionally small so ordinary domain names do not trigger.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-serialization-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["JSON" "Json" "json"])
                "json")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["String" "string"])
                "string")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Bytes" "Byte" "bytes" "u8vector" "U8Vector"])
                "bytes")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Marshal" "marshal" "Unmarshal" "unmarshal"])
                "marshal")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Sexp" "sexp" "Symbolic"])
                "sexp")]))

;;; Slot/lens boundaries are learned from gerbil-poo/mop.ss style, but the
;;; repair target is a local descriptor boundary, not a POO dependency.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-slot-lens-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-slot-lens-boundary-facts file)
   "slot-lens-boundary"))

;;; Guidance boundary:
;;; - Signals describe local helpers the agent can introduce in any package.
;;; - Empty output keeps ordinary hash or slot code out of lens advice unless a
;;;   typed contract collapses slot/get/set/modify/validation responsibilities.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-slot-lens-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-slot-lens-boundary-facts file)
   ["introduce local slot descriptor or lens helpers"
    "centralize get/set/modify around the slot boundary"
    "keep validation attached to the slot update boundary"
    "preserve reader/writer symmetry without gerbil-poo or gerbil-utils dependencies"]))

;;; Target boundary:
;;; - Report only definition names from parser-owned typed-contract facts.
;;; - The target list points at the collapsed owner, not the reference corpus.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-slot-lens-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-slot-lens-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This detector must not scan implementation text or infer package usage.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-slot-lens-boundary-facts file)
  (filter typed-combinator-style-slot-lens-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four slot/lens categories mark a collapsed descriptor owner.
;;; - Split local helpers should mention only one or two categories each.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-slot-lens-boundary-fact? fact)
  (>= (length (typed-combinator-style-slot-lens-boundary-categories fact))
      4))

;;; Category boundary:
;;; - Categories model responsibilities, not exact library names.
;;; - Keep the vocabulary small so normal domain fields do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-slot-lens-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Slot" "slot" "Descriptor" "descriptor"])
                "slot")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Lens" "lens"])
                "lens")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Get" "get" "Getter" "getter" "Ref" "ref"])
                "get")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Set" "set" "Setter" "setter" "Put" "put"])
                "set")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Modify" "modify" "Update" "update"])
                "modify")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Validate" "validate" "Valid" "valid" "Check" "check"])
                "validate")]))

;;; Concurrency control quality is learned from gerbil:// runtime control and
;;; gerbil-utils/concurrency.ss. The repair target is a local concurrency
;;; boundary that preserves reentry/cleanup semantics while naming spawn, join,
;;; sequentialization, race, and parameter propagation responsibilities.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-concurrency-control-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-concurrency-control-facts file)
   "concurrency-control-boundary"))

;;; Guidance boundary:
;;; - Signals describe local helper responsibilities, not reference imports.
;;; - Empty output keeps ordinary threaded helpers out of concurrency advice
;;;   unless a typed contract collapses several scheduling responsibilities.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-concurrency-control-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-concurrency-control-facts file)
   ["split spawn/join/mutex/race responsibilities"
    "preserve reentry guards and cleanup around dynamic-wind/unwind boundaries"
    "name the sequentialization boundary before sharing state"
    "keep parallel map join boundaries explicit"
    "preserve thread parameter propagation at the spawn boundary"]))

;;; Target boundary:
;;; - Report only parser-owned typed-contract definition names.
;;; - The target is the collapsed local owner, not the reference corpus file.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-concurrency-control-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-concurrency-control-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - This detector must not infer package dependencies from implementation text.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-concurrency-control-facts file)
  (filter typed-combinator-style-concurrency-control-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four concurrency categories mark a collapsed control owner.
;;; - Narrow spawn wrappers, lock helpers, or join helpers remain valid repairs.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-concurrency-control-fact? fact)
  (>= (length
       (typed-combinator-style-concurrency-control-categories fact))
      4))

;;; Category boundary:
;;; - Categories are control responsibilities, not exact API names.
;;; - Keep the vocabulary small so normal domain task names do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-concurrency-control-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Thread" "thread"])
                "thread")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Spawn" "spawn"])
                "spawn")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Join" "join"])
                "join")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Mutex" "mutex" "Lock" "lock" "Sequentialize"
                  "sequentialize"])
                "mutex")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Race" "race" "Shutdown" "shutdown"])
                "race")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parallel" "parallel" "Worker" "worker"])
                "parallel")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Parameter" "parameter" "Dynamic" "dynamic"])
                "parameter")]))

;;; Exception/continuation quality is learned from gerbil-utils/exception.ss.
;;; The repair target is a local error boundary that preserves context and
;;; re-raise behavior, not a dependency on the reference package.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-exception-continuation-boundary-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-exception-continuation-boundary-facts file)
   "exception-continuation-boundary"))

;;; Guidance boundary:
;;; - Signals name the exception-control invariants an agent should preserve.
;;; - Empty output keeps ordinary try/catch code out of this guidance unless a
;;;   typed contract collapses exception, continuation, handler, and context.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-exception-continuation-boundary-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-exception-continuation-boundary-facts file)
   ["capture exception and continuation at the local boundary"
    "restore the prior exception handler before escaping"
    "log exception context before re-raising"
    "keep printable exception fallback local to diagnostics"]))

;;; Target boundary:
;;; - Report parser-owned typed-contract definition names only.
;;; - Reference corpus owners stay in qualityReference, not in target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-exception-continuation-boundary-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-exception-continuation-boundary-facts file)
   typed-contract-fact-definition-name))

;;; Fact boundary:
;;; - Reuse typed-contract facts collected by the parser.
;;; - Avoid text scans so exception advice remains schema-owned.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-exception-continuation-boundary-facts file)
  (filter typed-combinator-style-exception-continuation-boundary-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - Four exception-control categories mark a collapsed owner.
;;; - A narrow try/catch wrapper or printable-exception helper should not fire.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-exception-continuation-boundary-fact? fact)
  (>= (length
       (typed-combinator-style-exception-continuation-boundary-categories fact))
      4))

;;; Category boundary:
;;; - Categories are exception-control responsibilities, not exact APIs.
;;; - Keep the vocabulary small so domain error names do not trigger R013.
;; : (-> TypedContractFact (List String) )
(def (typed-combinator-style-exception-continuation-boundary-categories fact)
  (filter (lambda (category) category)
          [(and (typed-contract-fact-mentions-any?
                 fact
                 ["Exception" "exception" "Error" "error" "Exn" "exn"])
                "exception")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Continuation" "continuation" "Cont" "cont"])
                "continuation")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Handler" "handler" "Catch" "catch"])
                "handler")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Context" "context" "Log" "log" "Backtrace" "backtrace"])
                "context")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Raise" "raise" "Reraise" "reraise"])
                "raise")
           (and (typed-contract-fact-mentions-any?
                 fact
                 ["Thunk" "thunk" "Try" "try"])
                "thunk")]))

;;; Matching boundary:
;;; - Match candidate spellings across tokens, output, and inputs.
;;; - This keeps nested or legacy contract projections from losing evidence.
;; : (-> TypedContractFact (List String) Boolean )
(def (typed-contract-fact-mentions-any? fact needles)
  (ormap (lambda (needle)
           (typed-contract-fact-mentions? fact needle))
         needles))

;;; Text boundary:
;;; - This is bounded to parser-owned typed-contract fields.
;;; - It must not expand into source-file scanning or dependency detection.
;; : (-> TypedContractFact String Boolean )
(def (typed-contract-fact-mentions? fact needle)
  (or (member needle (typed-contract-fact-tokens fact))
      (and (string? (typed-contract-fact-contract-output fact))
           (string-contains (typed-contract-fact-contract-output fact)
                            needle))
      (ormap (lambda (input)
               (and (string? input)
                    (string-contains input needle)))
             (typed-contract-fact-contract-inputs fact))))

;;; Macro facts already classify syntax owners.  R013 exposes the engineering
;;; steering so macro-heavy files use upstream macro-library idioms without
;;; inventing a project-specific DSL.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-controlled-macro-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (source-file-macros file)
   "controlled-macro-syntax-boundary"))

;;; Signal boundary:
;;; - Controlled macro guidance is driven by parser macro facts, not text matching.
;;; - The suggestions keep transformer shape separate from runtime helpers.
;;; - This is Gerbil Scheme macro usage, not a license to create a DSL.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-controlled-macro-syntax-signals file)
  (typed-combinator-style-facts->signals
   (source-file-macros file)
   ["syntax-case/with-syntax transformer shape"
    "syntax-rules thin macro DSL"
    "hygienic macro boundary"
    "stx-lambda or def-stx helper boundary"
    "macro syntax stays a thin hygienic syntax wrapper"
    "runtime behavior remains in ordinary helpers"
    "docs explain the expansion contract and example result"]))

;;; Target projection mirrors macro-fact ownership exactly.
;;; The map is intentionally direct: policy details should cite macro names
;;; already emitted by the parser, not derive display names from syntax text.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-controlled-macro-targets file)
  (typed-combinator-style-facts->targets
   (source-file-macros file)
   macro-fact-name))

;;; POO typeclass facts come from the parser's options, not source text scans.
;;; The details expose concrete targets for gerbil-poo/fun.ss style repair.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-typeclass-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-typeclass-poo-forms file)
   "poo-typeclass-algebra-boundary"))

;;; Signal boundary:
;;; - POO algebra guidance is emitted only for parser-owned POO option facts.
;;; - This keeps typeclass repair tied to gerbil-poo semantics.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-typeclass-algebra-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-typeclass-poo-forms file)
   ["Category. compose/identity algebra"
    "Functor. map/tap/ap algebra"
    "Wrapper. wrap/unwrap/bind/map algebra"
    "ParametricFunctor. higher-kinded adapter boundary"
    "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
    "method bodies stay protocol-shaped instead of table-shaped"]))

;;; Target projection keeps typeclass advice attached to the POO declaration.
;;; The upstream filter owns algebra recognition, so this function only exposes
;;; the repair target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-typeclass-algebra-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-typeclass-poo-forms file)
   poo-form-fact-name))

;;; Boundary:
;;; - Typeclass detection consumes POO options emitted by parser/poo.ss.
;;; - The option vocabulary mirrors gerbil-poo/fun.ss algebra families.
;; : (-> SourceFile (List PooFormFact) )
(def (typed-combinator-style-typeclass-poo-forms file)
  (filter typed-combinator-style-typeclass-poo-form?
          (source-file-poo-forms file)))

;;; Option predicate:
;;; - Compare only parser-owned option tokens from parser/poo.ss.
;;; - The inline lambda keeps the accepted algebra vocabulary local and avoids
;;;   spreading raw typeclass strings through policy assembly.
;; : (-> PooFormFact Boolean )
(def (typed-combinator-style-typeclass-poo-form? fact)
  (ormap (lambda (option)
           (member option
                   ["typeclass:category"
                    "typeclass:functor"
                    "typeclass:parametric-functor"
                    "typeclass:wrapper"
                    "categoryAlgebra:compose-identity"
                    "functorAlgebra:tap-ap-map"
                    "wrapperAlgebra:wrap-unwrap-bind-map"]))
         (poo-form-fact-options fact)))
