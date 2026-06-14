;;; -*- Gerbil -*-
;;; Agent guide command output.

(import :gerbil/gambit
        :parser/facade
        :policy/catalog
        :support/args
        :support/io
        :support/list
        :std/srfi/13)

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
   "|cmd extension=gerbil-scheme-harness search extension <extension> [term ...] --view seeds ."
   "|cmd pattern=gerbil-scheme-harness search pattern <feature-or-extension> [term ...] --view seeds ."
   "|cmd compare=gerbil-scheme-harness search compare <axis> [left right] --view seeds ."
   "|cmd structural=gerbil-scheme-harness search structural --view seeds ."
   "|cmd structural-index-json=gerbil-scheme-harness search structural --json ."
   "|cmd evidence-graph=gerbil-scheme-harness evidence graph --json ."
   "|cmd evidence-analyze=gerbil-scheme-harness evidence analyze --json ."
   "|cmd info=gerbil-scheme-harness info --json ."
   "|cmd check=gerbil-scheme-harness check --changed ."
   "|cmd bench=gerbil-scheme-harness bench --json --iterations 1 --max-total-ms 60000 ."
   "|policy structural-json-boundary=use search structural --view seeds for bounded agent evidence; reserve --json for schema tests and artifact validation"
   "|policy configurable-interface=downstream gerbil.pkg policy may declare source-scope roots/runtime-roots/exclude-directories and agent-policy enabled-rules/disabled-rules; without explicit source-scope, build.ss defbuild-script targets provide runtime-root evidence"
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
   "|guideExemplar id=gerbil.higher-order-control.filter-map topic=higher-order-control intent=study rule=GERBIL-SCHEME-AGENT-R009 level=normal locator=parser-definition owner=src/checker/arity.ss symbols=call-arity-finding/known-signature,run-arity-checks comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control\" moreCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control --more\" advancedCommand=\"gerbil-scheme-harness guide --code --topic higher-order-control --level advanced\""
   "|guideExemplar id=gerbil.functional-data-transform.filter-map topic=functional-data-transform intent=repair rule=GERBIL-SCHEME-AGENT-R009 level=normal locator=parser-definition owner=src/checker/arity.ss symbols=call-arity-finding/known-signature,run-arity-checks comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair\""
   "|guideExemplar id=gerbil.typed-combinator-style.policy-coverage topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-R013 level=normal locator=parser-definition owner=src/policy/agent-style.ss symbols=typed-combinator-style-findings,typed-combinator-style-function-definitions,typed-combinator-style-evidence-callers comments=leading nextCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style\" moreCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style --more\""
   "|guideExemplar id=gerbil.typed-combinator-style.policy-filter-map topic=typed-combinator-style intent=style rule=GERBIL-SCHEME-AGENT-R013 level=more locator=parser-definition owner=src/policy/agent.ss symbols=functional-idiom-advice-findings comments=leading nextCommand=\"gerbil-scheme-harness guide --code --topic typed-combinator-style --intent style --more\""
   "|guideExemplar id=gerbil.poo-policy.parser-facts topic=poo-policy intent=repair rule=GERBIL-SCHEME-AGENT-R008 level=normal locator=parser-definition owner=src/parser/poo.ss symbols=poo-form-facts-from-form comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic poo-policy --intent repair\""
   "|guideExemplar id=gerbil.macro-runtime-source.witness topic=macro-runtime-source intent=witness rule=GERBIL-SCHEME-AGENT-R011 level=advanced locator=parser-definition owner=src/commands/search.ss symbols=matching-language-evidence-facts comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic macro-runtime-source --intent witness\""
   "|guideExemplar id=gerbil.controlled-branch-shape.bounded-selector topic=controlled-branch-shape intent=style rule=GERBIL-SCHEME-AGENT-R014 level=normal locator=parser-definition owner=src/commands/search-render.ss symbols=ranked-syntax-facts,select-ranked-syntax-facts comments=file-purpose+leading nextCommand=\"gerbil-scheme-harness guide --code --topic controlled-branch-shape --intent style\""
   "|guideExemplar id=gerbil.engineering-comment-quality.contract-boundary topic=engineering-comment-quality intent=style rule=GERBIL-SCHEME-AGENT-R015 level=normal locator=parser-definition owner=src/policy/agent-comment.ss symbols=comment-quality-details,comment-quality-fact-summary,weak-required-comment-quality-fact? comments=leading nextCommand=\"gerbil-scheme-harness guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style\""
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
  (emit-exemplar-source root
                         "src/commands/search.ss"
                         ["matching-language-evidence-facts"]
                         #t))
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
    (emit-higher-order-exemplar-source root)
    (when advanced?
      (newline)
      (emit-poo-policy-exemplar-source root)))
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
