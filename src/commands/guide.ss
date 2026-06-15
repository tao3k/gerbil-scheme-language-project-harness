;;; -*- Gerbil -*-
;;; Agent guide command output.
;;; Boundary:
;;; - Owns agent-facing guide rows and source-excerpt routing.
;;; - guide --code must emit extracted comments plus code, not search packets.

(import :gerbil/gambit
        :language/evidence
        :parser/facade
        :policy/catalog
        :support/args
        :support/io
        :support/list
        (only-in :std/srfi/13
                 string-contains
                 string-downcase
                 string-index
                 string-prefix?))

(export guide-lines
        guide-code-lines
        guide-main
        print-guide)
;;; Boundary:
;;; - guide-lines coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; String
(def (guide-lines)
  (append
   ["gerbil-scheme-harness guide"
   "|cmd guide-code=gerbil-scheme-harness guide --code"
   "|cmd guide-code-topic=gerbil-scheme-harness guide --code --topic higher-order-control"
   "|cmd guide-code-typed-combinator=gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style"
   "|cmd guide-code-more=gerbil-scheme-harness guide --code --topic higher-order-control --more"
   "|cmd guide-code-repair=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair"
   "|cmd guide-code-poo-repair=gerbil-scheme-harness guide --code --topic poo-policy --intent repair"
   "|cmd guide-code-macro-witness=gerbil-scheme-harness guide --code --topic macro-runtime-source --intent witness"
   "|cmd guide-code-branch-shape=gerbil-scheme-harness guide --code --topic controlled-branch-shape --intent style"
   "|cmd guide-code-comment-quality=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style"
   "|cmd guide-code-predicate-family=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style"
   "|cmd guide-code-dependency-adapter=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R017 --intent repair"
   "|cmd guide-code-explicit-import=gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R018 --intent repair"
   "|cmd guide-code-advanced=gerbil-scheme-harness guide --code --topic higher-order-control --level advanced"
   "|cmd prime=gerbil-scheme-harness search prime --view seeds ."
   "|cmd pipe=gerbil-scheme-harness search pipe '<term>' --view seeds ."
   "|cmd fzf=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds ."
   "|cmd owner=gerbil-scheme-harness search owner <path> --view seeds ."
   "|cmd owner-items=gerbil-scheme-harness search owner <path> items --query <symbol> --names-only ."
   "|cmd query-code=gerbil-scheme-harness query --selector <path:start-end> --workspace . --code"
   "|cmd env=gerbil-scheme-harness search env [term ...] --view seeds ."
   "|cmd runtime-source=gerbil-scheme-harness search runtime-source [term ...] --view seeds ."
   "|cmd lang=gerbil-scheme-harness search lang [term ...] --view seeds ."
   "|cmd std=gerbil-scheme-harness search std [term ...] --view seeds ."
   "|cmd capability=gerbil-scheme-harness search capability [term ...] --view seeds ."
   "|cmd extension=gerbil-scheme-harness search extension <extension> [term ...] --view seeds"
   "|cmd pattern=gerbil-scheme-harness search pattern <feature-or-extension> [term ...] --view seeds"
   "|cmd compare=gerbil-scheme-harness search compare <axis> [left right] --view seeds ."
   "|cmd structural=gerbil-scheme-harness search structural --view seeds ."
   "|cmd structural-interface-json=gerbil-scheme-harness search structural --json ."
   "|cmd structural-owner-facts-json=gerbil-scheme-harness search structural --owner <path> --json ."
   "|cmd structural-artifact-json=gerbil-scheme-harness search structural --json --artifact ."
   "|cmd evidence-graph=gerbil-scheme-harness evidence graph --json ."
   "|cmd evidence-analyze=gerbil-scheme-harness evidence analyze --json ."
   "|cmd info=gerbil-scheme-harness info --json ."
   "|cmd check=gerbil-scheme-harness check --changed ."
   "|cmd bench=gerbil-scheme-harness bench --json --iterations 1 --max-total-ms 2000 --max-interface-ms 50 ."
   "|policy structural-json-boundary=search structural --json emits a lightweight ASP-owned index interface; use --owner <path> for owner-bounded native facts and --artifact only for explicit validation"
   "|policy structural-index-owner=ASP Rust owns workspace structural index, graph topology, caching, and heavy ranking; Gerbil Scheme emits millisecond-level manifest and owner facts"
   "|policy configurable-interface=downstream gerbil.pkg policy may declare source-scope roots/runtime-roots/exclude-directories and agent-policy enabled-rules/disabled-rules; without explicit source-scope, build.ss defbuild-script targets provide runtime-root evidence"
   "|policy gerbil-build-discovery=prefer :std/make + :clan/base + :clan/building all-gerbil-modules discovery for Gerbil packages; filter non-module policy/config files before compiling harness provider sources"
   "|policy cli-option-composition=keep src/cli.ss as a thin dispatcher with precise only-in imports; when command option surfaces grow, compose option objects instead of expanding dispatcher parsing logic"
   "|policy package-module-style=Gerbil package modules should preserve package:/namespace:/import/export style instead of flattening into generic Scheme files"
   "|policy gerbil-feature-use=when POO/protocol capability is active, prefer parser-owned defclass/defgeneric/defmethod evidence over raw hash/alist object constructors; cite search pattern poo class when intentionally staying raw"]
   (agent-rule-policy-lines)
   [
   "|policy namespace-receipt=macro/module/type/poo edits should cite search env/lang/std/pattern/runtime-source output before editing"
   "|policy runtime-source-code-comments=runtime-source results should expose selectorResolver/sourceExample/sourceComment lines before selector code reads"
   "|policy typed-combinator-style-criteria=three criteria are required: adjacent Haskell-like transform signature block, compact expression-level composition, and optimization-boundary comments for specialized branches"
   "|policy typed-combinator-style-signature=write an adjacent contract block; it may be one line or multiple lines when that preserves precision, and must not append the function name inline"
   "|policy typed-combinator-style-composition=prefer small helper functions and expression-level map/filter/fold/cut/curry/compose chains when behavior fits"
   "|policy typed-combinator-style-optimization-boundary=for case-lambda or common-case specializations, comment why the branch exists; do not restate the code mechanics"
   "|policy engineering-comment-quality=typed contract comments describe algebraic shape only; engineering comments should cover parserEvidence with concise prose, bullets, or optional Boundary/Invariant/Intent labels; split multi-clause rationale across adjacent lines"
   "|policy dependency-protocol-adapter=when a dependency provides durable data primitives, do not hand-write loose hash/alist objects; wrap primitives as a thin define-type/protocol adapter with Key/Value/validate/serialization/equality slots, derived table/set/list/sexp/json/marshal capabilities, precise only-in imports, and generic t/ contract witnesses"
   "|policy dependency-protocol-adapter-repair-action=R017 findings should run guide --code --rule GERBIL-SCHEME-AGENT-R017 --intent repair first; the --code flag prints the adapter code shape the agent should follow"
   "|policy protocol-surface-minimality=define the minimal protocol slot surface first, then derive secondary capabilities such as table/set/list/json/bytes/marshal from those slots instead of duplicating behavior"
   "|policy reusable-contract-tests=prefer small t/ owners that apply generic contract tests to type descriptors, such as table-contract-tests or protocol-contract-tests, over monolithic copied assertion suites"
   "|policy poo-thin-macro-bridge=POO syntax macros such as brace/@method should stay thin syntax bridges; semantic behavior belongs in object, MOP, protocol, or method-family slots"
   "|policy poo-slot-resolution=POO object edits must account for C3 precedence and lazy slot cache resolution; query object/mop slot-resolution selectors before replacing objects with hash/alist guesses"
   "|policy poo-serialization-method-family=json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string should be modeled as method/type slots, not scattered helper functions"
   "|policy explicit-precise-import=runtime library, dependency, and owner-local helper imports should use (only-in <module> <symbols...>) so parser-owned moduleImportFacts expose the exact dependency surface to agents"
   "|policy poo-structural-facts=search structural --owner <path> --json exposes parser-owned POO forms as custom/generic/method owner facts with role,supers,slots,options,specializers,specializerTypes,dispatchArity; query owner facts before editing POO object/type/method forms"
   "|guideExemplar id=gerbil.higher-order-control.filter-map topic=higher-order-control intent=study rule=GERBIL-SCHEME-AGENT-R009 level=normal locator=parser-definition owner=src/checker/arity.ss symbols=call-arity-finding/known-signature,run-arity-checks comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control\" moreCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control --more\" advancedCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control --level advanced\""
   "|guideExemplar id=gerbil.functional-data-transform.filter-map topic=functional-data-transform intent=repair rule=GERBIL-SCHEME-AGENT-R009 level=normal locator=parser-definition owner=src/checker/arity.ss symbols=call-arity-finding/known-signature,run-arity-checks comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair\""
   "|guideExemplar id=gerbil.typed-combinator-style.policy-coverage topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-R013 level=normal locator=parser-definition owner=src/policy/agent-style.ss symbols=typed-combinator-style-findings,typed-combinator-style-function-definitions,typed-combinator-style-evidence-callers comments=leading nextCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style\" moreCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style --more\""
   "|guideExemplar id=gerbil.typed-combinator-style.policy-filter-map topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-R013 level=more locator=parser-definition owner=src/policy/agent.ss symbols=functional-idiom-advice-findings comments=leading nextCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style --more\""
   "|guideExemplar id=gerbil.poo-policy.parser-facts topic=poo-policy intent=repair rule=GERBIL-SCHEME-AGENT-R008 level=normal locator=parser-definition owner=src/parser/poo.ss symbols=poo-form-facts-from-form comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic poo-policy --intent repair\""
   "|guideExemplar id=gerbil.poo-policy.structural-owner-facts topic=poo-policy intent=witness rule=GERBIL-SCHEME-AGENT-R008 level=normal locator=structural-owner-facts owner=t/fixtures/parser/poo-method-dispatch.ss symbols=distance,:intersect fields=generic,specializers,specializerTypes,receiver,receiverType,dispatchArity nextCommand=\"gerbil-scheme-harness search structural --owner t/fixtures/parser/poo-method-dispatch.ss --json .\""
   "|guideExemplar id=gerbil.macro-runtime-source.witness topic=macro-runtime-source intent=witness rule=GERBIL-SCHEME-AGENT-R011 level=advanced locator=parser-definition owner=src/commands/search.ss symbols=matching-language-evidence-facts comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic macro-runtime-source --intent witness\""
   "|guideExemplar id=gerbil.controlled-branch-shape.bounded-selector topic=controlled-branch-shape intent=style rule=GERBIL-SCHEME-AGENT-R014 level=normal locator=parser-definition owner=src/commands/search-render.ss symbols=ranked-syntax-facts,select-ranked-syntax-facts comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic controlled-branch-shape --intent style\""
   "|guideExemplar id=gerbil.engineering-comment-quality.contract-boundary topic=engineering-comment-quality intent=style rule=GERBIL-SCHEME-AGENT-R015 level=normal locator=parser-definition owner=src/policy/agent-comment.ss symbols=comment-quality-details,comment-quality-fact-summary,weak-required-comment-quality-fact? comments=leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style\""
   "|guideExemplar id=gerbil.predicate-family-combinator.native-facts topic=predicate-family-combinator intent=style rule=GERBIL-SCHEME-AGENT-R016 level=normal locator=parser-definition owner=src/parser/quality-shape.ss symbols=predicate-family-facts-from-source,field-access-pattern-facts-from-source comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style\""
   "|guideExemplar id=gerbil.dependency-protocol-adapter.rationaldict-shape topic=dependency-protocol-adapter intent=repair rule=GERBIL-SCHEME-AGENT-R017 level=normal locator=runtime-source owner=gerbil-poo/rationaldict.ss symbols=RationalDict.,RationalSet comments=file-purpose+leading repairAction=inspect-code-shape guideCodeFlag=--code nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R017 --intent repair\" moreCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R017 --intent repair --more\""
   "|guideExemplar id=gerbil.explicit-precise-import.policy-shape topic=explicit-precise-import intent=repair rule=GERBIL-SCHEME-AGENT-R018 level=normal locator=parser-definition owner=src/policy/agent-import.ss symbols=explicit-precise-import-finding,imprecise-runtime-import?,explicit-precise-import-details comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R018 --intent repair\""
   "|policy guide-code-default=guide --code writes only extracted source comment plus source code; guide without --code carries selectors and next commands"
   "|policy guide-code-default-topic=guide --code defaults to typed-combinator-style so agents first see transform signatures plus compact expression-level helper functions"
   "|policy guide-code-progressive=guide --code defaults to one source-backed excerpt; --more adds one adjacent exemplar; --level advanced includes the macro runtime-source witness path"
   "|policy guide-code-routing=--rule/--finding route known policy ids to source-backed exemplars before agent repair; --intent witness routes to macro runtime-source evidence"
   "|policy guide-workspace=guide does not require a positional .; use --workspace . only when project-local exemplar selection needs context"
   "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed"]))
;; Boolean <- (List String) Flag
(def (arg-present? args flag)
  (and (member flag args) #t))
;; Boolean <- Value Fragment
(def (string-has? value fragment)
  (and value (string-contains value fragment) #t))
;;; Catalog route lookup: accept a full finding/rule fragment, then keep the
;;; first catalog-backed guide topic so guide and repair do not drift.
;; RuleTopic <- Rule
(def (rule-topic rule)
  (and rule
       (let (matches
             (filter-map (lambda (rule-id)
                           (and (string-has? rule rule-id)
                                (agent-rule-guide-topic rule-id)))
                         (agent-steering-rule-ids)))
         (and (pair? matches) (car matches)))))
;; String <- (List String)
(def (guide-intent args)
  (or (option "--intent" args)
      (option "--role" args)
      "study"))
;; IntentTopic <- String
(def (intent-topic intent)
  (cond
   ((equal? intent "witness") "macro-runtime-source")
   (else #f)))
;;; Canonicalization is the public guide compatibility layer: policy rules,
;;; user-facing topic aliases, and progressive exemplars can evolve without
;;; making callers learn every internal topic name.
;;; Boundary:
;;; - Add aliases only when they route to an existing source-backed exemplar.
;;; - Keep topic fallback stable so policy repair nextCommand rows remain valid.
;; CanonicalTopic <- String
(def (canonical-topic topic)
  (cond
   ((or (equal? topic "poo") (equal? topic "poo-policy")) "poo-policy")
   ((or (equal? topic "functional") (equal? topic "functional-data-transform"))
    "functional-data-transform")
   ((or (equal? topic "typed") (equal? topic "typed-combinator")
        (equal? topic "typed-combinator-style")
        (equal? topic "combinator") (equal? topic "combinator-style"))
    "typed-combinator-style")
   ((or (equal? topic "macro") (equal? topic "runtime-source")
        (equal? topic "macro-runtime-source"))
    "macro-runtime-source")
   ((or (equal? topic "controlled-branch-shape")
        (equal? topic "branch-shape")
        (equal? topic "match-readability"))
    "controlled-branch-shape")
   ((or (equal? topic "engineering-comment-quality")
        (equal? topic "comment-quality")
        (equal? topic "comments"))
    "engineering-comment-quality")
   ((or (equal? topic "predicate-family-combinator")
        (equal? topic "predicate-family")
        (equal? topic "field-access-pattern"))
    "predicate-family-combinator")
   ((or (equal? topic "dependency-protocol-adapter")
        (equal? topic "dependency-adapter")
        (equal? topic "protocol-adapter")
        (equal? topic "adapter-quality"))
    "dependency-protocol-adapter")
   ((or (equal? topic "explicit-precise-import")
        (equal? topic "precise-import")
        (equal? topic "only-in")
        (equal? topic "import-precision"))
    "explicit-precise-import")
   (else "higher-order-control")))
;; String <- (List String)
(def (guide-topic args)
  (canonical-topic
   (or (option "--topic" args)
       (rule-topic (option "--rule" args))
       (rule-topic (option "--finding" args))
       (intent-topic (guide-intent args))
       "typed-combinator-style")))
;; String <- (List String)
(def (guide-level args)
  (or (option "--level" args) "normal"))
;; Boolean <- Level
(def (advanced-level? level)
  (or (equal? level "advanced") (equal? level "full")))
;;; Boundary:
;;; - emit-exemplar-source composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- String String (List XX) IncludeFileComment
(def (emit-exemplar-source root owner symbols include-file-comment?)
  (let* ((index (collect-project root))
         (file (guide-source-file index owner)))
    (when include-file-comment?
      (let (comment (read-source-file-purpose-comment root owner))
        (when (not (string=? comment ""))
          (display comment)
          (newline))))
    (emit-definition-exemplar-sources
     root
     (map (lambda (symbol)
            (guide-definition file owner symbol))
          symbols))))
;;; Invariant:
;;; - emit-definition-exemplar-sources owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Unit <- String (List Definition)
(def (emit-definition-exemplar-sources root definitions)
  (display
   (join (map (cut read-definition-with-leading-comments root <>)
              definitions)
         "\n")))
;;; Invariant:
;;; - guide-source-file owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; String <- ProjectIndex String
(def (guide-source-file index owner)
  (or (find (lambda (file) (equal? (source-file-path file) owner))
            (project-index-files index))
      (error "guide exemplar owner not found" owner)))
;;; Invariant:
;;; - guide-definition owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; String <- SourceFile String Symbol
(def (guide-definition file owner symbol)
  (or (find (lambda (defn) (equal? (definition-name defn) symbol))
            (source-file-definitions file))
      (error "guide exemplar definition not found" owner symbol)))
;; (List HigherOrderFact) <- String
(def (emit-higher-order-exemplar-source root)
  (emit-exemplar-source root
                         "src/checker/arity.ss"
                         ["call-arity-finding/known-signature"
                          "run-arity-checks"]
                         #t))
;; Unit <- String
(def (emit-typed-combinator-style-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-style.ss"
                         ["typed-combinator-style-findings"
                          "typed-combinator-style-function-definitions"
                          "typed-combinator-style-evidence-callers"]
                         #f))
;; Unit <- String
(def (emit-typed-combinator-style-more-source root)
  (emit-exemplar-source root
                         "src/policy/agent.ss"
                         ["functional-idiom-advice-findings"]
                         #f))
;; Unit <- String
(def (emit-poo-policy-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/poo.ss"
                         ["poo-form-facts-from-form"]
                         #t))
;; Unit <- String
(def (emit-macro-runtime-source-exemplar-source root)
  (emit-runtime-source-exemplar-source "macro" 0 1))
;;; Boundary:
;;; - Emit only source/comment text selected from runtime-source acquisition facts.
;;; - Keep search packet rows out of guide --code output.
;; Unit <- RuntimeSourceQuery StartIndex Limit
(def (emit-runtime-source-exemplar-source query start limit)
  (let* ((examples (runtime-source-examples query))
         (sources (take* (filter-map runtime-source-example-source
                                      (drop* examples start))
                         limit)))
    (if (pair? sources)
      (display (join sources "\n"))
      (error "runtime-source exemplar selector did not resolve" query))))
;; (List RuntimeSourceExample) <- (List RuntimeSourceExample) StartIndex
(def (drop* xs n)
  (cond
   ((or (fx<= n 0) (null? xs)) xs)
   (else (drop* (cdr xs) (fx1- n)))))
;;; Intent:
;;; - Prefer runtime examples that carry source comment extraction evidence.
;;; - Preserve the acquisition packet order for examples without comments.
;; (List RuntimeSourceExample) <- RuntimeSourceQuery
(def (runtime-source-examples query)
  (let* ((facts (filter (lambda (fact)
                          (evidence-fact-matches-query? fact query))
                        (runtime-source-facts)))
         (fact (and (pair? facts) (car facts)))
         (details (if fact (hash-get fact 'details) (hash))))
    (if (and fact (hash-key? details 'sourceExamples))
      (prioritize-runtime-source-examples
       (hash-get details 'sourceExamples)
       (if (hash-key? details 'sourceComments)
         (hash-get details 'sourceComments)
         []))
      [])))
;;; Boundary:
;;; - Comment-backed selectors teach agents the code plus nearby rationale first.
;;; - Un-commented examples remain available through progressive --more output.
;; (List RuntimeSourceExample) <- (List RuntimeSourceExample) (List SourceComment)
(def (prioritize-runtime-source-examples examples comments)
  (let* ((selectors (filter-map (cut hash-get <> 'selector) comments))
         (commented (filter (lambda (example)
                              (member (hash-get example 'selector) selectors))
                            examples))
         (rest (filter (lambda (example)
                         (not (member (hash-get example 'selector) selectors)))
                       examples)))
    (append commented rest)))
;; Boolean <- Fact Query
(def (evidence-fact-matches-query? fact query)
  (let ((haystack (join (hash-get fact 'terms) " "))
        (q (string-downcase query)))
    (or (string=? query "")
        (string-contains (string-downcase haystack) q))))
;;; Boundary:
;;; - Resolve gerbil-runtime-source selectors through the active runtime tree.
;;; - Do not fall back to local harness examples when runtime source is absent.
;; SourceText <- RuntimeSourceExample
(def (runtime-source-example-source example)
  (let* ((selector (hash-get example 'selector))
         (parts (runtime-source-selector-parts selector)))
    (and parts
         (let* ((relpath (car parts))
                (symbol (cadr parts))
                (root (runtime-source-root-for relpath)))
           (and root
                (runtime-source-symbol-source root relpath symbol))))))
;;; Selector grammar is owned by selectorResolver.output in runtime-source facts.
;;; Keep parsing exact so malformed selectors surface as unresolved evidence.
;; SelectorParts <- RuntimeSourceSelector
(def (runtime-source-selector-parts selector)
  (let* ((prefix "gerbil-runtime-source://")
         (prefix-len (string-length prefix)))
    (and (string? selector)
         (string-prefix? prefix selector)
         (let* ((body (substring selector prefix-len (string-length selector)))
                (hash-index (string-index body #\#)))
           (and hash-index
                [(substring body 0 hash-index)
                 (substring body (fx1+ hash-index) (string-length body))])))))
;; RuntimeSourceRoot <- Relpath
(def (runtime-source-root-for relpath)
  (find (lambda (root)
          (file-exists? (path-expand relpath root)))
        (runtime-source-root-candidates)))
;; (List RuntimeSourceRoot)
(def (runtime-source-root-candidates)
  (dedupe
   (filter-map
    (lambda (path)
      (and path (path-normalize path)))
    (append
     [(gerbil-home)
      (path-expand ".." (gerbil-home))
      (path-expand "../.." (gerbil-home))]
     (runtime-source-ancestor-candidates)))))
;;; Self-apply often runs from a brewed runtime whose GERBIL_HOME contains only
;;; compiled artifacts. The source checkout remains ASP-managed under .data, so
;;; guide --code can resolve selectors without leaking local paths in packets.
;; (List RuntimeSourceRoot)
(def (runtime-source-ancestor-candidates)
  (filter file-directory?
          (map (cut path-expand ".data/gerbil" <>)
               (runtime-source-ancestor-directories))))

;;; Boundary:
;;; - Runtime source lookup is bounded to a small parent chain.
;;; - The explicit chain avoids open-ended filesystem walks in guide --code.
;; (List Directory)
(def (runtime-source-ancestor-directories)
  (let* ((d0 (path-normalize (current-directory)))
         (d1 (runtime-source-parent-directory d0))
         (d2 (runtime-source-parent-directory d1))
         (d3 (runtime-source-parent-directory d2))
         (d4 (runtime-source-parent-directory d3))
         (d5 (runtime-source-parent-directory d4))
         (d6 (runtime-source-parent-directory d5))
         (d7 (runtime-source-parent-directory d6))
         (d8 (runtime-source-parent-directory d7)))
    (dedupe [d0 d1 d2 d3 d4 d5 d6 d7 d8])))

;; Directory <- Directory
(def (runtime-source-parent-directory dir)
  (path-normalize (path-expand ".." dir)))
;;; Boundary:
;;; - Prefer parser-owned definitions before top-form fallback for macro-rule forms.
;;; - Both paths use source ranges from the native parser.
;; SourceText <- RuntimeSourceRoot Relpath Symbol
(def (runtime-source-symbol-source root relpath symbol)
  (let* ((file (parse-source-file root relpath))
         (definition (find (lambda (defn)
                             (equal? (definition-name defn) symbol))
                           (source-file-definitions file))))
    (cond
     (definition
      (read-definition-with-leading-comments root definition))
     (else
      (runtime-source-top-form-source root file symbol)))))
;;; Top-form fallback covers macro-form exemplars where the selector names the form head.
;;; Definition selectors must be handled before this branch.
;; SourceText <- RuntimeSourceRoot SourceFile Symbol
(def (runtime-source-top-form-source root file symbol)
  (let (form (find (lambda (form)
                    (or (equal? (top-form-head form) symbol)
                        (equal? (top-form-head form)
                                (string-append "(" symbol))))
                  (source-file-forms file)))
    (and form
         (read-line-range (path-expand (source-file-path file) root)
                          (top-form-start form)
                          (top-form-end form)))))
;; Unit <- String
(def (emit-controlled-branch-shape-exemplar-source root)
  (emit-exemplar-source root
                         "src/commands/search-render.ss"
                         ["ranked-syntax-facts"
                          "select-ranked-syntax-facts"]
                         #t))
;; Unit <- String
(def (emit-engineering-comment-quality-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-comment.ss"
                         ["comment-quality-details"
                          "comment-quality-fact-summary"
                          "weak-required-comment-quality-fact?"]
                         #f))
;; Unit <- String
(def (emit-predicate-family-combinator-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/quality-shape.ss"
                         ["predicate-family-facts-from-source"
                          "field-access-pattern-facts-from-source"]
                         #t))
;; SourceRelpath
(def +poo-rationaldict-exemplar-relpath+
  ".gerbil/pkg/git.cons.io/mighty-gerbils/gerbil-poo/rationaldict.ss")

;;; Boundary:
;;; - R017 default guidance is sourced from the dependency adapter itself.
;;; - The resolver stays bounded to the active workspace and its parent chain.
;; Unit <- String
(def (emit-poo-rationaldict-exemplar-source root)
  (let (source-root (poo-rationaldict-exemplar-root root))
    (if source-root
      (emit-external-exemplar-source source-root
                                     +poo-rationaldict-exemplar-relpath+
                                     ["RationalDict." "RationalSet"])
      (error "POO rationaldict exemplar source not found"
             +poo-rationaldict-exemplar-relpath+))))

;;; Boundary:
;;; - External package exemplars are parsed by the same native parser.
;;; - This keeps guide --code source-backed without copying dependency code.
;; Unit <- String Relpath (List Symbol)
(def (emit-external-exemplar-source root relpath symbols)
  (let (file (parse-source-file root relpath))
    (emit-definition-exemplar-sources
     root
     (map (lambda (symbol)
            (guide-definition file relpath symbol))
          symbols))))

;;; Intent:
;;; - Resolve the source root for the package-owned R017 exemplar.
;;; Data flow:
;;; - find checks the workspace candidate before parent cache candidates.
;;; - The lambda probes only the exact rationaldict source path.
;;; Invariant:
;;; - Keep lookup non-recursive so guide --code remains deterministic.
;; MaybeRoot <- String
(def (poo-rationaldict-exemplar-root root)
  (find (lambda (candidate)
          (file-exists?
           (path-expand +poo-rationaldict-exemplar-relpath+ candidate)))
        (dedupe
         (append [root (current-directory)]
                 (runtime-source-ancestor-directories)))))

;; Unit <- String
(def (emit-dependency-protocol-adapter-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/dependency-adapter-quality.ss"
                         ["dependency-adapter-quality-facts-from-candidates"
                          "dependency-adapter-derived-capabilities"
                          "dependency-adapter-manual-object-encoding-risk"
                          "dependency-adapter-quality-facets"]
                         #t))
;; Unit <- String
(def (emit-explicit-precise-import-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-import.ss"
                         ["explicit-precise-import-finding"
                          "imprecise-runtime-import?"
                          "explicit-precise-import-details"]
                         #t))
;; Unit <- String String
(def (emit-topic-exemplar-source topic root)
  (cond
   ((or (equal? topic "higher-order-control")
        (equal? topic "functional-data-transform"))
    (emit-higher-order-exemplar-source root))
   ((equal? topic "typed-combinator-style")
    (emit-typed-combinator-style-exemplar-source root))
   ((equal? topic "poo-policy")
    (emit-poo-policy-exemplar-source root))
   ((equal? topic "macro-runtime-source")
    (emit-macro-runtime-source-exemplar-source root))
   ((equal? topic "controlled-branch-shape")
    (emit-controlled-branch-shape-exemplar-source root))
   ((equal? topic "engineering-comment-quality")
    (emit-engineering-comment-quality-exemplar-source root))
   ((equal? topic "predicate-family-combinator")
    (emit-predicate-family-combinator-exemplar-source root))
   ((equal? topic "dependency-protocol-adapter")
    (emit-poo-rationaldict-exemplar-source root))
   ((equal? topic "explicit-precise-import")
    (emit-explicit-precise-import-exemplar-source root))
   (else
    (emit-higher-order-exemplar-source root))))
;;; Boundary:
;;; - emit-progressive-exemplar-source coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Unit <- String String Advanced
(def (emit-progressive-exemplar-source topic root advanced?)
  (cond
   ((or (equal? topic "higher-order-control")
        (equal? topic "functional-data-transform"))
    (newline)
    (emit-poo-policy-exemplar-source root)
    (when advanced?
      (newline)
      (emit-macro-runtime-source-exemplar-source root)))
   ((equal? topic "typed-combinator-style")
    (newline)
    (emit-typed-combinator-style-more-source root)
    (when advanced?
      (newline)
      (emit-poo-policy-exemplar-source root)))
   ((equal? topic "poo-policy")
    (newline)
    (emit-higher-order-exemplar-source root)
    (when advanced?
      (newline)
      (emit-macro-runtime-source-exemplar-source root)))
   ((equal? topic "macro-runtime-source")
    (newline)
    (emit-runtime-source-exemplar-source "macro" 1 1)
    (when advanced?
      (newline)
      (emit-higher-order-exemplar-source root)))
   ((equal? topic "controlled-branch-shape")
    (newline)
    (emit-typed-combinator-style-exemplar-source root)
    (when advanced?
      (newline)
      (emit-higher-order-exemplar-source root)))
   ((equal? topic "engineering-comment-quality")
    (newline)
    (emit-typed-combinator-style-exemplar-source root)
    (when advanced?
      (newline)
      (emit-controlled-branch-shape-exemplar-source root)))
   ((equal? topic "predicate-family-combinator")
    (newline)
    (emit-controlled-branch-shape-exemplar-source root)
    (when advanced?
      (newline)
      (emit-typed-combinator-style-exemplar-source root)))
   ((equal? topic "dependency-protocol-adapter")
    (newline)
    (emit-dependency-protocol-adapter-exemplar-source root)
    (when advanced?
      (newline)
      (emit-typed-combinator-style-exemplar-source root)))
   (else
    (newline)
    (emit-poo-policy-exemplar-source root))))
;; String <- (List String)
(def (default-guide-source-root args)
  (cond
   ((option "--workspace" args) => values)
   ((file-directory? "src") ".")
   ((file-directory? "languages/gerbil-scheme-language-project-harness/src")
    "languages/gerbil-scheme-language-project-harness")
   (else (project-root args))))
;; String <- (List String)
(def (guide-code-lines args)
  (let* ((topic (guide-topic args))
         (selector (option "--selector" args))
         (root (default-guide-source-root args))
         (advanced? (advanced-level? (guide-level args)))
         (more? (or (arg-present? args "--more") advanced?)))
    (cond
     (selector
      (display (read-selector root selector)))
     (else
      (emit-topic-exemplar-source topic root)
      (when more?
        (emit-progressive-exemplar-source topic root advanced?)))))
  [])
;; String
(def (print-guide)
  (for-each displayln (guide-lines)))
;; String <- (List String)
(def (print-guide-code args)
  (guide-code-lines args))
;; String <- (List String)
(def (guide-main args)
  (if (arg-present? args "--code")
    (print-guide-code args)
    (print-guide))
  0)
