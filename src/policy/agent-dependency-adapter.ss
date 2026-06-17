;;; -*- Gerbil -*-
;;; Agent-facing dependency protocol adapter policy.

(import :parser/facade
        :policy/agent-support
        :policy/model
        (only-in :std/srfi/13 string-contains string-prefix?)
        :support/list
        :types/findings)

(export dependency-protocol-adapter-findings
        dependency-protocol-adapter-finding)

;; (List String)
(def +dependency-adapter-contract-witness-callees+
  '("test-suite" "test-case" "table-tests" "universal-tests"
    "check" "check-equal?" "assert-equal!"))

;; (List String)
(def +dependency-adapter-generic-contract-witness-callees+
  '("adapter-contract-tests" "protocol-contract-tests" "table-contract-tests"
    "table-tests" "universal-tests" "json-contract-tests"
    "marshal-contract-tests" "list-contract-tests"))

;; Command
(def +dependency-adapter-repair-code-command+
  "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R017 --intent repair")
;; Command
(def +dependency-adapter-search-example-command+
  "asp gerbil-scheme search pattern poo rationaldict adapter --workspace . --view seeds")

;;; Entry boundary: policy only consumes parser-owned adapter facts.
;;; It does not infer adapter quality from raw source text.
;; (List TypeFinding) <- ProjectIndex
(def (dependency-protocol-adapter-findings index)
  (apply append
         (map (lambda (file)
                (filter-map
                 (cut dependency-protocol-adapter-finding index file <>)
                 (source-file-dependency-adapter-quality-facts file)))
              (project-index-files index))))

;;; Finding gate: incomplete local adapter evidence or missing project contract
;;; witness triggers agent repair. Complete local facts stay advisory only when
;;; a t/ witness exercises the adapter.
;; TypeFinding <- ProjectIndex SourceFile DependencyAdapterQualityFact
(def (dependency-protocol-adapter-finding index file fact)
  (and (index-source-runtime-file-path? index (source-file-path file))
       (let (missing (dependency-protocol-adapter-missing-evidence index fact))
         (and (pair? missing)
              (make-type-finding
               (policy-rule-id +agent-dependency-protocol-adapter-rule+)
               (policy-rule-severity +agent-dependency-protocol-adapter-rule+)
               (source-file-path file)
               (dependency-protocol-adapter-message fact missing)
               (dependency-adapter-quality-fact-selector fact)
               (dependency-protocol-adapter-details index fact missing))))))

;; (List MissingEvidence) <- ProjectIndex DependencyAdapterQualityFact
(def (dependency-protocol-adapter-missing-evidence index fact)
  (dedupe
   (append (dependency-adapter-quality-fact-missing-evidence fact)
           (if (dependency-adapter-generic-contract-witness-exists? index fact)
             []
             ["generic-contract-test-witness"]))))

;; String <- DependencyAdapterQualityFact MissingEvidence
(def (dependency-protocol-adapter-message fact missing)
  (string-append
   "dependency adapter " (dependency-adapter-quality-fact-name fact)
   " wraps " (dependency-adapter-quality-fact-dependency fact)
   " but is missing " (join missing ",")
   "; lift dependency primitives into a thin typed protocol adapter and add a contract witness"))

;;; Boundary:
;;; - Details packet is the agent repair contract for adapter quality.
;;; - Keep fields evidence-shaped so the model can repair without reading policy code.
;;; - Do not inline source snippets.
;;; - Parser facts and guide commands own follow-up.
;; Json <- ProjectIndex DependencyAdapterQualityFact MissingEvidence
(def (dependency-protocol-adapter-details index fact missing)
  (hash (styleGuide "dependency-protocol-adapter")
        (styleCommand
         "asp gerbil-scheme guide --code --topic dependency-protocol-adapter --intent repair")
        (repairAction "search-forwarded-example-then-guide-code")
        (guideCodeFlag "--code")
        (searchExampleCommand +dependency-adapter-search-example-command+)
        (repairCodeCommand +dependency-adapter-repair-code-command+)
        (codeShapeExemplar "gerbil-poo rationaldict-style typed protocol adapter")
        (sourcePatternLineage "gerbil-poo build/cli/rationaldict/table/brace/object/mop/io patterns")
        (definition (dependency-adapter-quality-fact-name fact))
        (dependency (dependency-adapter-quality-fact-dependency fact))
        (imports (dependency-adapter-quality-fact-imports fact))
        (importedSymbols
         (take-at-most (dependency-adapter-quality-fact-imported-symbols fact) 12))
        (usedSymbols
         (take-at-most (dependency-adapter-quality-fact-used-symbols fact) 12))
        (protocolRefs
         (dependency-adapter-quality-fact-protocol-refs fact))
        (slots (dependency-adapter-quality-fact-slots fact))
        (derivedCapabilities
         (dependency-adapter-quality-fact-derived-capabilities fact))
        (protocolSurface
         "minimal protocol slots first; derive table/set/list/sexp/json/marshal-facing capabilities from the slot surface")
        (protocolSurfaceReference
         "gerbil-poo table.ss methods.table")
        (reusableContractTestPattern
         "small t/ owner calls generic table-contract-tests or protocol-contract-tests against the adapter type descriptor")
        (macroBridgeBoundary
         "syntax forms should stay thin bridges like gerbil-poo brace.ss @method; runtime semantics belong in object/mop/protocol slots")
        (slotResolutionModel
         "POO objects resolve slots through C3 precedence plus lazy slot function cache; do not replace this with raw hash/alist guesses")
        (ioSerializationMethodFamily
         "json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string are method/type slots")
        (buildPattern
         "use :std/make + :clan/base + :clan/building discovery, while filtering non-module policy/config files for this harness")
        (cliOptionPattern
         "keep src/cli.ss as a thin dispatcher; compose option objects when command option surfaces grow")
        (manualObjectEncodingRisk
         (dependency-adapter-quality-fact-manual-object-encoding-risk fact))
        (genericContractWitnessKind
         (dependency-adapter-quality-fact-generic-contract-witness-kind fact))
        (quality (dependency-adapter-quality-fact-quality fact))
        (qualityFacets
         (dependency-adapter-quality-fact-quality-facets fact))
        (missingEvidence missing)
        (contractWitnessPresent
         (dependency-adapter-generic-contract-witness-exists? index fact))
        (contractWitnessKind
         (or (dependency-adapter-contract-witness-kind index fact) "missing"))
        (contractWitnessSource
         "project-level t/ owner with adapter call plus generic table/protocol contract tests; basic check calls are diagnostic but not sufficient")
        (adapterRepairShape
         "query the search-forwarded rationaldict adapter example first, then use R017 guide --code for local parser/policy repair snippets; follow exact only-in dependency import -> define-type protocol surface -> Key/Value/validation/serialization/equality slots -> generic contract tests")
        (agentRepairStandard
         "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value/validate/serialization/equality slots, behavior on protocol slots, derived table/set/list/sexp/json/marshal capabilities when slots exist, and generic contract tests")
        (allowedMoves
         [(string-append "run " +dependency-adapter-search-example-command+
                         " to inspect the dependency example before editing")
          (string-append "run " +dependency-adapter-repair-code-command+
                         " to inspect local R017 parser/policy repair code")
          "add or tighten only-in dependency primitive imports"
          "wrap dependency primitives with define-type and protocol slots"
          "add .validate, .sexp<-, .=?, .list<- or .<-list boundaries when behavior exists"
          "derive table/set/list/sexp/json/marshal-facing capability from protocol slots"
          "add t/ generic contract tests such as table-contract-tests or protocol-contract-tests"])
        (disallowedMoves
         ["do not replace dependency primitives with hand-written hash/alist storage"
          "do not satisfy R017 with a line-number fixture or a single incidental check call"
          "do not call imported primitives directly from scattered owners when a typed adapter boundary is missing"
          "do not invent protocol capabilities that are not backed by slots or dependency primitives"])
        (agentFlexibility
         "agent may choose helper names, exact slot grouping, and generic test helper shape; preserve public adapter name and dependency primitive semantics")
        (nativeFactSource
         "parser-owned dependencyAdapterQualityFacts joined with moduleImportFacts; do not use raw text heuristics")
        (advice (dependency-adapter-quality-fact-advice fact))
        (next +dependency-adapter-search-example-command+)))

;;; Contract witness detection stays project-level because tests usually live
;;; outside the adapter owner. The predicate still uses parser-owned calls.
;; Boolean <- ProjectIndex DependencyAdapterQualityFact
(def (dependency-adapter-contract-witness-exists? index fact)
  (and (dependency-adapter-contract-witness-kind index fact) #t))

;; Boolean <- ProjectIndex DependencyAdapterQualityFact
(def (dependency-adapter-generic-contract-witness-exists? index fact)
  (equal? (dependency-adapter-contract-witness-kind index fact)
          "generic-contract-test"))

;;; Boundary:
;;; - Contract witness classification is project-wide.
;;; - Tests often live outside the adapter owner.
;;; - The first matching test owner is enough for this policy warning.
;;; - Richer witness ranking belongs to ASP evidence graph consumers.
;; WitnessKind <- ProjectIndex DependencyAdapterQualityFact
(def (dependency-adapter-contract-witness-kind index fact)
  (ormap (cut dependency-adapter-contract-witness-file? fact <>)
         (project-index-files index)))

;; WitnessKind <- DependencyAdapterQualityFact SourceFile
(def (dependency-adapter-contract-witness-file? fact file)
  (and (test-owner-path? (source-file-path file))
       (source-file-references-adapter? file
                                        (dependency-adapter-quality-fact-name fact))
       (source-file-contract-witness-kind file)))

;; Boolean <- Path
(def (test-owner-path? path)
  (and path
       (or (string-prefix? "t/" path)
           (string-contains path "/t/"))))

;;; Boundary:
;;; - Adapter witness lookup is parser evidence, not raw text matching.
;;; - POO type descriptors are often passed as arguments to generic tests or
;;;   bound as local fixtures instead of called as constructors.
;;; - Keep the exact-callee path as the strongest witness, but accept parser
;;;   argument and binding facts so R017 does not force fake adapter calls.
;; Boolean <- SourceFile AdapterName
(def (source-file-references-adapter? file adapter-name)
  (or (source-file-calls-adapter? file adapter-name)
      (source-file-call-mentions-adapter? file adapter-name)
      (source-file-binding-mentions-adapter? file adapter-name)))

;;; Exact callee matches are the strongest adapter reference signal: a single
;;; parser-owned ormap proves at least one call site invokes the descriptor
;;; directly without scanning source text.
;; Boolean <- SourceFile AdapterName
(def (source-file-calls-adapter? file adapter-name)
  (ormap (lambda (call)
           (equal? (call-fact-callee call) adapter-name))
         (source-file-calls file)))

;;; Data-flow transform: project call facts are projected to their argument
;;; lists, then ormap encodes the existential "any call mentions adapter"
;;; query.  The one-argument lambda mirrors the call fact stream shape, so this
;;; stays a parser-fact predicate instead of a hand-written source loop.
;; Boolean <- SourceFile AdapterName
(def (source-file-call-mentions-adapter? file adapter-name)
  (ormap (lambda (call)
           (member adapter-name (call-fact-arguments call)))
         (source-file-calls file)))

;;; Binding mentions preserve witness evidence during fixture extraction:
;;; local adapter aliases still prove the test owner sees the adapter surface.
;; Boolean <- SourceFile AdapterName
(def (source-file-binding-mentions-adapter? file adapter-name)
  (ormap (lambda (binding)
           (equal? (binding-fact-name binding) adapter-name))
         (source-file-bindings file)))

;;; Boundary:
;;; - Contract witness calls prove the adapter is exercised by project tests.
;;; - The accepted call vocabulary is small and data-owned at module scope.
;; WitnessKind <- SourceFile
(def (source-file-contract-witness-kind file)
  (cond
   ((source-file-has-generic-contract-witness? file)
    "generic-contract-test")
   ((source-file-has-basic-contract-witness? file)
    "basic-test-call")
   (else #f)))

;; Boolean <- SourceFile
(def (source-file-has-generic-contract-witness? file)
  (or (source-file-has-generic-contract-witness-call? file)
      (source-file-has-generic-contract-witness-definition? file)))

;;; Generic witness calls prove the adapter is exercised through reusable
;;; protocol/table contract helpers rather than one-off assertions.
;; Boolean <- SourceFile
(def (source-file-has-generic-contract-witness-call? file)
  (source-file-has-any-contract-witness-call?
   file
   +dependency-adapter-generic-contract-witness-callees+))

;;; Generic witness definitions catch local contract helper declarations before
;;; they are invoked, preserving project-level evidence during test refactors.
;; Boolean <- SourceFile
(def (source-file-has-generic-contract-witness-definition? file)
  (source-file-has-any-contract-witness-definition?
   file
   +dependency-adapter-generic-contract-witness-callees+))

;;; Basic witnesses are weaker than generic protocol tests but still useful as
;;; diagnostic evidence when an adapter is first introduced.
;; Boolean <- SourceFile
(def (source-file-has-basic-contract-witness? file)
  (or (source-file-has-basic-contract-witness-call? file)
      (source-file-has-basic-contract-witness-definition? file)))

;;; Basic witness calls keep the fallback path parser-owned instead of letting
;;; arbitrary test text satisfy R017.
;; Boolean <- SourceFile
(def (source-file-has-basic-contract-witness-call? file)
  (source-file-has-any-contract-witness-call?
   file
   +dependency-adapter-contract-witness-callees+))

;;; Basic witness definitions support test helper extraction while preserving
;;; the weaker witness kind until a generic contract helper is present.
;; Boolean <- SourceFile
(def (source-file-has-basic-contract-witness-definition? file)
  (source-file-has-any-contract-witness-definition?
   file
   +dependency-adapter-contract-witness-callees+))

;;; Boundary:
;;; - Witness callees are a closed vocabulary owned by this policy module.
;;; - Parser-owned call facts keep this check independent of source formatting
;;;   and avoid treating comments or string literals as tests.
;; Boolean <- SourceFile Callees
(def (source-file-has-any-contract-witness-call? file callees)
  (ormap (lambda (call) (member (call-fact-callee call) callees))
         (source-file-calls file)))

;;; Data-flow transform: definition facts are projected to names, then ormap
;;; checks whether any helper definition belongs to the closed contract-witness
;;; vocabulary.  The one-argument lambda preserves the definition fact arity and
;;; avoids mixing helper declarations with raw text search.
;; Boolean <- SourceFile Callees
(def (source-file-has-any-contract-witness-definition? file callees)
  (ormap (lambda (definition) (member (definition-name definition) callees))
         (source-file-definitions file)))
