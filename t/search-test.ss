;;; -*- Gerbil -*-
(import :std/test
        :commands/search
        :support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        :unit/poo/runtime-witness
        :unit/search/structural-index)
(export search-test)

(def (json-get table key)
  (hash-get table (if (string? key) (string->symbol key) key)))

(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))

(def (contains? output fragment)
  (and (string-contains output fragment) #t))

(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))

(def search-test
  (test-suite "gerbil scheme harness search"
    (test-case "POO partial upgrades have runtime witnesses"
      (check-poo-runtime-witnesses))
    (test-case "owner item marker is not treated as project root"
      (check (project-root ["src/checker/types.ss"
                            "items"
                            "--query"
                            "type-compatible"
                            "--names-only"])
             => ".")
      (check (drop-project-root ["src/checker/types.ss"
                                 "items"
                                 "--query"
                                 "type-compatible"
                                 "--names-only"
                                 "."])
             => ["src/checker/types.ss"
                 "items"
                 "--query"
                 "type-compatible"
                 "--names-only"]))
    (test-case "project root removal preserves option values"
      (check (project-root ["src/checker/types.ss"
                            "."
                            "--names-only"])
             => ".")
      (check (drop-project-root ["src/checker/types.ss"
                                 "."
                                 "--names-only"])
             => ["src/checker/types.ss" "--names-only"])
      (check (drop-project-root ["src/checker/types.ss"
                                 "items"
                                 "--query"
                                 "."
                 "."])
             => ["src/checker/types.ss"
                 "items"
                 "--query"
                 "."]))
    (test-case "language evidence search namespaces are explicit"
      (check (language-evidence-view? "env") => #t)
      (check (language-evidence-view? "runtime-source") => #t)
      (check (language-evidence-view? "lang") => #t)
      (check (language-evidence-view? "std") => #t)
      (check (language-evidence-view? "extension") => #t)
      (check (language-evidence-view? "pattern") => #t)
      (check (language-evidence-view? "concept") => #f)
      (check (language-evidence-authority "extension")
             => "ecosystem-extension")
      (check (language-evidence-authority "env") => "active-runtime")
      (check (language-evidence-authority "runtime-source")
             => "runtime-version-source")
      (check (language-evidence-authority "lang") => "language-rules")
      (check (language-evidence-authority "std") => "standard-library")
      (check (language-evidence-authority "pattern") => "executable-pattern")
      (check (language-evidence-next "pattern" "hygienic-macro")
             => "search pattern hygienic-macro"))
    (test-case "search guide routes to provider guide"
      (let (output (search-output ["guide" "--view" "seeds" "."]))
        (check (string-prefix? "gerbil-scheme-harness guide" output) => #t)
        (check (contains? output "|cmd prime=gerbil-scheme-harness search prime --view seeds .") => #t)
        (check (contains? output "|cmd pipe=gerbil-scheme-harness search pipe '<term>' --view seeds .") => #t)
        (check (contains? output "|cmd query-code=gerbil-scheme-harness query --selector <path:start-end> --workspace . --code") => #t)
        (check (contains? output "|cmd env=gerbil-scheme-harness search env [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd runtime-source=gerbil-scheme-harness search runtime-source [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd lang=gerbil-scheme-harness search lang [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd std=gerbil-scheme-harness search std [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd extension=gerbil-scheme-harness search extension <extension> [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd pattern=gerbil-scheme-harness search pattern <feature-or-extension> [term ...] --view seeds .") => #t)
        (check (contains? output "|cmd compare=gerbil-scheme-harness search compare <axis> [left right] --view seeds .") => #t)
        (check (contains? output "|cmd structural-index=gerbil-scheme-harness search structural --json .") => #t)
        (check (contains? output "|policy namespace-receipt=macro/module/type/poo edits should cite search env/lang/std/pattern/runtime-source output before editing") => #t)
        (check (contains? output "|policy runtime-source-code-comments=runtime-source results should expose selectorResolver/sourceExample/sourceComment lines before selector code reads") => #t)
        (check (contains? output "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed") => #t)))
    (test-case "search pipe routes through compact fzf frontier"
      (let (output (search-output ["pipe" "guide" "."]))
        (check (contains? output "[gerbil-search-fzf] query=guide") => #t)
        (check (contains? output "recommendedNext=gerbil-scheme-harness search owner") => #t)))
    (test-case "structural search compact output exposes higher-order facts"
      (let (output (search-output ["structural" "--view" "seeds" "."]))
        (check-output-contains
         output
         ["[gerbil-search-structural]"
          "|syntaxFact kind=function languageKind=lambda name=lambda"
          "role=anonymous-function"
          "operandCount=1"
          "arities=1"
          "kind=call languageKind=map name=map"
          "role=sequence-map"
          "kind=call languageKind=cut name=cut"
          "role=partial-application"
          "caller="])))
    (test-case "env search exposes active runtime witness"
      (let (output (search-output ["env" "gxi" "."]))
        (check (contains? output "evidenceGrade=fact") => #t)
        (check (contains? output "|runtime gerbilHome=") => #t)
        (check (contains? output "gxiExists=#t") => #t)
        (check (contains? output "gscExists=#t") => #t)
        (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search exposes ASP acquisition plan"
      (let (output (search-output ["runtime-source" "macro" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-source"
          "evidenceGrade=fact"
          "runtime-version-source"
          "active-runtime-version-to-source-acquisition-plan"
          "|sourceRef kind=runtime-version-source"
          "repository=https://git.cons.io/mighty-gerbils/gerbil"
          "checkoutPolicy=exact-tag-from-active-runtime"
          "statePathPolicy=asp-state-managed"
          "|acquisition owner=asp"
          "operation=clone-or-fetch-checkout-index"
          "stateNamespace=runtime-source/gerbil-scheme"
          "indexOwner=asp-structural-index"
          "|selectorResolver scheme=gerbil-runtime-source owner=asp stateNamespace=runtime-source/gerbil-scheme"
          "selectorFormat=gerbil-runtime-source://<source-path>#<symbol> output=code-with-comments"
          "|sourceExample id=std-sugar-defrule role=macro-rule symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
          "head=defrule operands=(<name> arg ...),body ... keywords=-"
          "|sourceExample id=std-sugar-defsyntax-call role=procedural-macro-call symbol=defsyntax-call selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
          "|sourceExample id=module-sugar-only-in role=import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
          "|sourceComment id=std-sugar-comment-boundary selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
          "fallback=comment-missing-is-signal"
          "|selector role=std-sugar-source symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
          "|selector role=module-sugar-import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
          "clone-active-runtime-source-before-answering-language-or-macro-usage"
          "|failureCase id=memory-language-answer"
          "|failureCase id=wrong-runtime-version"
          "|failureCase id=unindexed-source-checkout"
          "|qualitySignal id=no-memory"
          "|qualitySignal id=version-matched-source"
          "|qualitySignal id=asp-state-managed-checkout"
          "|qualitySignal id=code-with-comments-output"
          "|qualitySignal id=selector-resolver-owned-by-asp"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (contains? output ".data")) => #t)
        (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes std sugar to versioned source"
      (let (output (search-output ["runtime-source" "sugar" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-source"
          "repository=https://git.cons.io/mighty-gerbils/gerbil"
          "|qualitySignal id=source-index-required"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes module sugar to versioned source"
      (let (output (search-output ["runtime-source" "module-sugar" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-source"
          "repository=https://git.cons.io/mighty-gerbils/gerbil"
          "stateNamespace=runtime-source/gerbil-scheme"
          "|qualitySignal id=source-index-required"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes writeenv printer hooks to versioned source"
      (let (output (search-output ["runtime-source" "writeenv" "printer" "hook" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-writeenv-source"
          "active-runtime-version-to-writeenv-source-acquisition-plan"
          "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims"
          "|selectorResolver scheme=gerbil-runtime-source owner=asp stateNamespace=runtime-source/gerbil-scheme"
          "|sourceExample id=runtime-writeenv-binding role=runtime-binding symbol=writeenv selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
          "head=system: operands=writeenv::t,(t::t) keywords=-"
          "|sourceExample id=runtime-write-object-owner role=runtime-printer-owner symbol=write-object selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
          "|sourceComment id=builtin-primitive-comment selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
          "|sourceComment id=write-object-comment-boundary selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
          "|failureCase id=memory-writeenv-answer"
          "|failureCase id=poo-writeenv-roundtrip-assumption"
          "|failureCase id=raw-runtime-source-search"
          "|qualitySignal id=writeenv-source-index-required"
          "|qualitySignal id=printer-hook-source-required"
          "next=search runtime-source writeenv printer hook"])
        (check (not (contains? output ".data")) => #t)
        (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source json uses schema-backed acquisition packet"
      (let* ((output (search-output ["runtime-source" "macro" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (runtime (json-get packet "runtime"))
             (source-ref (json-get packet "sourceRef"))
             (acquisition (json-get packet "acquisition"))
             (fact (car (json-get packet "facts")))
             (details (json-get fact "details"))
             (packet-resolver (json-get packet "selectorResolver"))
             (packet-examples (json-get packet "sourceExamples"))
             (packet-comments (json-get packet "sourceComments"))
             (resolver (json-get details "selectorResolver"))
             (examples (json-get details "sourceExamples"))
             (comments (json-get details "sourceComments")))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-runtime-source-acquisition")
        (check (json-get packet "namespace") => "runtime-source")
        (check (json-get packet "authority") => "runtime-version-source")
        (check (json-get packet "quality") => "version-matched-source-plan")
        (check (json-get source-ref "kind") => "runtime-version-source")
        (check (json-get source-ref "repository")
               => "https://git.cons.io/mighty-gerbils/gerbil")
        (check (json-get source-ref "checkoutPolicy")
               => "exact-tag-from-active-runtime")
        (check (json-get source-ref "statePathPolicy")
               => "asp-state-managed")
        (check (json-get acquisition "owner") => "asp")
        (check (json-get acquisition "operation")
               => "clone-or-fetch-checkout-index")
        (check (json-get acquisition "stateNamespace")
               => "runtime-source/gerbil-scheme")
        (check (json-get acquisition "indexOwner") => "asp-structural-index")
        (check (json-get packet-resolver "scheme") => "gerbil-runtime-source")
        (check (json-get (car packet-examples) "id") => "std-sugar-defrule")
        (check (json-get (car packet-comments) "fallback") => "comment-missing-is-signal")
        (check (json-get resolver "scheme") => "gerbil-runtime-source")
        (check (json-get resolver "output") => "code-with-comments")
        (check (json-get (car examples) "id") => "std-sugar-defrule")
        (check (json-get (car comments) "fallback") => "comment-missing-is-signal")
        (check (json-get packet "next")
               => "search runtime-source macro sugar module-sugar")
        (check (string-prefix? "Gerbil v" (json-get runtime "systemVersion")) => #t)
        (check (not (contains? output ".data")) => #t)))
    (test-case "runtime-source json exposes writeenv printer hook selectors"
      (let* ((output (search-output ["runtime-source" "writeenv" "printer" "hook" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (facts (json-get packet "facts"))
             (fact (car facts))
             (selectors (json-get fact "selectors"))
             (writeenv-selector (car selectors))
             (write-object-selector (list-ref selectors 2))
             (failures (json-get packet "failureCases"))
             (roundtrip-failure (list-ref failures 1)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-runtime-source-acquisition")
        (check (json-get packet "namespace") => "runtime-source")
        (check (json-get packet "quality") => "version-matched-source-plan")
        (check (json-get packet "missing") => [])
        (check (json-get packet "witness")
               => "active-runtime-version-to-writeenv-source-acquisition-plan")
        (check (json-get packet "next")
               => "search runtime-source writeenv printer hook")
        (check (json-get fact "id") => "gerbil-runtime-writeenv-source")
        (check (json-get writeenv-selector "role") => "writeenv-builtin")
        (check (json-get writeenv-selector "selector")
               => "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
        (check (json-get write-object-selector "role") => "runtime-write-object-owner")
        (check (json-get write-object-selector "selector")
               => "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
        (check (json-get roundtrip-failure "id")
               => "poo-writeenv-roundtrip-assumption")
        (check (not (contains? output ".data")) => #t)))
    (test-case "compare search prefers active runtime over documented claims"
      (let (output (search-output ["compare" "env" "active" "documented" "."]))
        (check-output-contains
         output
         ["[gerbil-search-compare]"
          "evidenceGrade=fact"
          "authority=active-runtime-vs-documented"
          "quality=verified"
          "|compare id=env-active-documented result=active-runtime-authoritative"
          "witness=active-runtime-beats-documented-memory"
          "|left kind=active-runtime"
          "gxiResolved=#t"
          "gscResolved=#t"
          "|right kind=documented-runtime source=documentation-or-model-memory status=non-authoritative"
          "|failureCase id=documented-version-wins"
          "|failureCase id=compare-leaks-local-path"
          "|qualitySignal id=active-runtime-fact"
          "|qualitySignal id=path-free-compare-output"
          "next=search env gxi load-path"])
        (check (not (contains? output ".data")) => #t)
        (check (not (contains? output "/Users/")) => #t)
        (check (not (contains? output "/opt/homebrew")) => #t)))
    (test-case "compare search routes compile target versions to runtime source"
      (let (output (search-output ["compare" "compile" "v0.18" "v0.19" "nightly" "."]))
        (check-output-contains
         output
         ["[gerbil-search-compare]"
          "evidenceGrade=fact"
          "quality=verified"
          "|compare id=compile-target-runtime-source result=active-runtime-source-checkout-required-before-version-guidance"
          "witness=active-runtime-selects-versioned-source-before-compile-guidance"
          "|left kind=active-runtime"
          "|right kind=requested-compile-target source=agent-request-or-user-claim status=non-authoritative-until-runtime-source-acquired"
          "|compareTargets versions=v0.18,v0.19,nightly compileMode=active-gxi-gsc-first stateNamespace=runtime-source/gerbil-scheme"
          "|agentScenario id=agent-needs-to-answer-gerbil-compile-or-syntax-question-for-a-requested-version"
          "|failureCase id=requested-version-wins-without-runtime"
          "|failureCase id=compile-source-mismatch"
          "|failureCase id=nightly-assumption"
          "|qualitySignal id=compile-version-query"
          "|qualitySignal id=version-matched-source"
          "|qualitySignal id=source-checkout-required"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (contains? output ".data")) => #t)
        (check (not (contains? output "/Users/")) => #t)
        (check (not (contains? output "/opt/homebrew")) => #t)))
    (test-case "compare json uses schema-backed packet"
      (let* ((output (search-output ["compare" "env" "active" "documented" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (comparison (car (json-get packet "comparisons")))
             (left (json-get comparison "left"))
             (right (json-get comparison "right")))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-compare-packet")
        (check (json-get packet "namespace") => "compare")
        (check (json-get packet "authority") => "active-runtime-vs-documented")
        (check (json-get packet "quality") => "verified")
        (check (json-get packet "missing") => [])
        (check (json-get comparison "id") => "env-active-documented")
        (check (json-get comparison "result") => "active-runtime-authoritative")
        (check (json-get left "kind") => "active-runtime")
        (check (json-get right "status") => "non-authoritative")
        (check (not (contains? output ".data")) => #t)
        (check (not (contains? output "/Users/")) => #t)))
    (test-case "lang and std searches expose fact witnesses"
      (let ((lang-output (search-output ["lang" "hygienic-macro" "."]))
            (style-output (search-output ["lang" "style" "."]))
            (module-output (search-output ["lang" "rename-in" "only-in" "."]))
            (std-output (search-output ["std" "srfi-13" "."]))
            (sugar-output (search-output ["std" "sugar" "defrule" "."]))
            (json-output (search-output ["std" "json" "."])))
        (check (contains? lang-output "|fact id=hygienic-macro") => #t)
        (check (contains? lang-output "selector=src/checker/forms.ss:13") => #t)
        (check (not (contains? lang-output "pending")) => #t)
        (check (contains? style-output "|fact id=scheme-style") => #t)
        (check (contains? style-output "gerbil-utils-style-audit-and-harness-policy") => #t)
        (check (contains? style-output "|failureCase id=legacy-test-directory") => #t)
        (check (contains? style-output "|failureCase id=vague-definition-name") => #t)
        (check (contains? style-output "|failureCase id=top-level-executable-call") => #t)
        (check (contains? style-output "selector=gerbil-utils://t/base-test.ss#base-test") => #t)
        (check (contains? style-output "|qualitySignal id=t-test-layout") => #t)
        (check (contains? style-output "|qualitySignal id=real-project-t-tests") => #t)
        (check (contains? style-output "|qualitySignal id=vague-definition-policy") => #t)
        (check (contains? style-output "|qualitySignal id=top-level-executable-policy") => #t)
        (check (not (contains? style-output "pending")) => #t)
        (check (contains? module-output "|fact id=module-import") => #t)
        (check (contains? module-output "runtime-source-module-sugar-import-export-sets") => #t)
        (check (contains? module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in") => #t)
        (check (contains? module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in") => #t)
        (check (contains? module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out") => #t)
        (check (contains? module-output "|failureCase id=racket-require-assumption") => #t)
        (check (contains? module-output "|failureCase id=unchecked-rename-in") => #t)
        (check (contains? module-output "|failureCase id=rename-out-confusion") => #t)
        (check (contains? module-output "|qualitySignal id=module-sugar-source") => #t)
        (check (contains? module-output "|qualitySignal id=import-set-witness") => #t)
        (check (contains? module-output "|qualitySignal id=export-set-witness") => #t)
        (check (not (contains? module-output "pending")) => #t)
        (check (contains? std-output "|fact id=std/srfi/13") => #t)
        (check (contains? std-output "provider-imports-:std/srfi/13") => #t)
        (check (not (contains? std-output "pending")) => #t)
        (check (contains? sugar-output "|fact id=std/sugar") => #t)
        (check (contains? sugar-output "runtime-source-std-sugar-defrule-and-defsyntax") => #t)
        (check (contains? sugar-output "selector=gerbil-runtime-source://src/std/sugar.ss#defrule") => #t)
        (check (contains? sugar-output "|qualitySignal id=runtime-source-backed-std-module") => #t)
        (check (not (contains? sugar-output "pending")) => #t)
        (check (contains? json-output "|fact id=std/text/json") => #t)
        (check (contains? json-output "provider-imports-:std/text/json") => #t)
        (check (contains? json-output "|failureCase id=foreign-json-parser") => #t)
        (check (contains? json-output "|qualitySignal id=read-json-capability") => #t)
        (check (not (contains? json-output "pending")) => #t)))
    (test-case "pattern search exposes verified runnable witnesses"
      (let ((macro-output (search-output ["pattern" "hygienic-macro" "."]))
            (poo-output (search-output ["pattern" "poo" "object" "."])))
        (check (contains? macro-output "quality=verified") => #t)
        (check (contains? macro-output "witness=parser-and-test-backed-hygienic-macro-pattern") => #t)
        (check (contains? macro-output "missing=-") => #t)
        (check (contains? poo-output "sourceRef=package-manager-download:gxpkg:git.cons.io/mighty-gerbils/gerbil-poo:runtime-resolved") => #t)
        (check (contains? poo-output "selector=gerbil-poo://object.ss#defclass") => #t)
        (check (contains? poo-output "witness=dependency-backed-poo-mapping") => #t)
        (check (contains? poo-output "missing=-") => #t)))
    (test-case "agent scenario routes unknown POO usage through extension then pattern guidance"
      (let ((extension-output (search-output ["extension" "poo" "syntax" "."]))
            (pattern-output (search-output ["pattern" "how" "do" "I" "write" "poo" "class" "method" "protocol" "."])))
        (check-output-contains
         extension-output
         ["[gerbil-search-extension]"
          "|extension name=poo"
          "next=search pattern poo syntax"])
        (check (not (contains? extension-output "|form role=")) => #t)
        (check-output-contains
         pattern-output
         ["quality=verified"
          "|agentScenario id=agent-does-not-know-gerbil-poo-object-system"
          "intent=write-gerbil-poo-object-system-without-racket-or-generic-scheme-guessing"
          "sourceRef=package-manager-download:gxpkg:git.cons.io/mighty-gerbils/gerbil-poo:runtime-resolved"
          "|selector role=class-definition symbol=defclass selector=gerbil-poo://object.ss#defclass"
          "|selector role=generic-definition symbol=.defgeneric selector=gerbil-poo://mop.ss#.defgeneric"
          "|selector role=method-dispatch symbol=defmethod selector=gerbil-poo://mop.ss#defmethod"
          "|selector role=prototype-composition symbol=compose-proto selector=gerbil-poo://proto.ss#compose-proto"
          "|selector role=method-resolution-order symbol=class-precedence-list selector=gerbil-runtime://c3.ss#class-precedence-list"
          "|selector role=real-project-semantic-test symbol=c3-test selector=gerbil-runtime-test://src/gerbil/test/c3-test.ss#c3-test"
          "|form role=class-definition symbol=defclass head=defclass operands=(<Class> <Base>),(<slot> ...) keywords=transparent: #t"
          "|form role=mro-regression-test symbol=class-precedence-list head=check"
          "|form role=slot-order-regression-test symbol=class-type-slot-vector head=check"
          "|failureCase id=racket-class-syntax"
          "|failureCase id=method-without-generic"
          "|failureCase id=unchecked-mro-assumption"
          "|qualitySignal id=dependency-backed-mapping"
          "|qualitySignal id=real-project-c3-test"
          "|qualitySignal id=mro-linearization-witness"
          "|qualitySignal id=slot-order-witness"
          "selectorCount=7 formCount=6 failureCaseCount=4"
          "missing=-"])
        (check (not (contains? pattern-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? pattern-output "pending")) => #t)))
    (test-case "agent scenario exposes POO source gaps as partial pattern evidence"
      (let ((proto-output (search-output ["pattern" "poo" "prototype" "compose-proto" "."]))
            (trace-output (search-output ["pattern" "poo" "trace" "debug" "."]))
            (slot-output (search-output ["pattern" "poo" "slot" "cache" "computed" "."]))
            (io-output (search-output ["pattern" "poo" "json" "fallback" "."]))
            (lens-output (search-output ["pattern" "poo" "lens" "slot-lens" "."]))
            (type-output (search-output ["pattern" "poo" "sealed" "validate" "."])))
        (check-output-contains
         proto-output
         ["quality=verified"
          "|pattern id=poo-prototype-composition"
          "|agentScenario id=agent-composes-poo-prototypes-without-knowing-proto-order"
          "intent=query-proto-composition-source-before-composing-object-prototypes"
          "|selector role=prototype-instantiation symbol=instantiate-proto selector=gerbil-poo://proto.ss#instantiate-proto"
          "|selector role=prototype-composition symbol=compose-proto selector=gerbil-poo://proto.ss#compose-proto"
          "|selector role=prototype-composition-list symbol=compose-proto* selector=gerbil-poo://proto.ss#compose-proto*"
          "|form role=prototype-composition-list symbol=compose-proto* head=compose-proto*"
          "|failureCase id=proto-order-confusion"
          "|failureCase id=missing-prototype-runtime-witness"
          "|qualitySignal id=composition-order"
          "|qualitySignal id=runtime-prototype-composition-witness"
          "|quality verified missing=- selectorCount=3 formCount=3 failureCaseCount=2"
          "next=search pattern poo prototype composition witness"])
        (check-output-contains
         trace-output
         ["quality=verified"
          "|pattern id=poo-trace-debug"
          "|agentScenario id=agent-traces-poo-methods-without-preserving-computed-slot-superfun"
          "intent=query-trace-poo-and-computed-slot-wrapper-before-adding-debug-tracing"
          "|selector role=trace-function-wrapper symbol=traced-function selector=gerbil-poo://debug.ss#traced-function"
          "|selector role=trace-inherited-slot symbol=trace-inherited-slot selector=gerbil-poo://debug.ss#trace-inherited-slot"
          "|selector role=trace-poo-wrapper symbol=trace-poo selector=gerbil-poo://debug.ss#trace-poo"
          "|selector role=computed-slot-wrapper symbol=$computed-slot-spec selector=gerbil-poo://debug.ss#trace-inherited-slot"
          "|form role=computed-slot-trace symbol=$computed-slot-spec head=$computed-slot-spec"
          "|form role=trace-poo-wrapper symbol=trace-poo head=trace-poo"
          "|failureCase id=trace-without-superfun"
          "|failureCase id=eager-trace-wrapper"
          "|failureCase id=trace-mutates-source-poo"
          "|qualitySignal id=debug-source"
          "|qualitySignal id=superfun-chain-source"
          "|qualitySignal id=runtime-trace-poo-witness"
          "|quality verified missing=- selectorCount=4 formCount=4 failureCaseCount=3"
          "next=search pattern poo trace runtime witness"])
        (check-output-contains
         slot-output
         ["quality=verified"
          "|pattern id=poo-slot-cache-computed"
          "|agentScenario id=agent-adds-computed-poo-slot-without-cache-or-superfun-semantics"
          "intent=query-slot-cache-and-apply-slot-spec-before-adding-computed-slots"
          "|selector role=slot-spec-application symbol=apply-slot-spec selector=gerbil-poo://object.ss#apply-slot-spec"
          "|selector role=slot-cache-read symbol=.ref selector=gerbil-poo://object.ss#.ref"
          "|selector role=slot-cache-read-existing symbol=.ref/cached selector=gerbil-poo://object.ss#.ref/cached"
          "|selector role=real-project-slot-cache-test symbol=putslot-test selector=gerbil-poo-test://t/object-test.ss#testing-putslot"
          "|form role=computed-slot symbol=computed-slot-spec head=computed-slot-spec"
          "|form role=slot-cache-regression-test symbol=putslot-test head=check"
          "|failureCase id=uncached-slot-side-effect"
          "|failureCase id=missing-superfun-chain"
          "|qualitySignal id=ref-cache-source"
          "|qualitySignal id=real-project-slot-cache-test"
          "|qualitySignal id=superfun-witness"
          "|quality verified missing=- selectorCount=5 formCount=4 failureCaseCount=2"
          "next=search pattern poo slot cache computed"])
        (check-output-contains
         io-output
         ["quality=partial"
          "|pattern id=poo-io-json-fallback"
          "|agentScenario id=agent-customizes-poo-serialization-without-json-or-print-fallbacks"
          "intent=query-poo-io-fallbacks-before-overriding-json-or-print-behavior"
          "|selector role=print-fallback symbol=@method :pr selector=gerbil-poo://io.ss#@method:pr"
          "|selector role=writeenv-fallback symbol=@method :wr selector=gerbil-poo://io.ss#@method:wr-object"
          "|selector role=json-fallback symbol=@method :json selector=gerbil-poo://io.ss#@method:json"
          "|selector role=typed-value-writer symbol=TV selector=gerbil-poo://io.ss#@method:wr-TV"
          "|selector role=writeenv-runtime-boundary symbol=writeenv selector=gerbil-runtime://builtin#writeenv"
          "|selector role=writeenv-method-dispatch-witness symbol=method-ref selector=gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch"
          "|selector role=object-value-mapping symbol=map-object-values selector=gerbil-poo://mop.ss#map-object-values"
          "|form role=writeenv-fallback symbol=@method :wr head=defmethod"
          "|form role=typed-value-writer symbol=TV head=defmethod"
          "|form role=writeenv-method-dispatch-witness symbol=method-ref head=method-ref"
          "|failureCase id=json-fallback-bypass"
          "|failureCase id=print-representation-bypass"
          "|failureCase id=typed-value-writer-bypass"
          "|failureCase id=direct-writeenv-construction"
          "|failureCase id=write-printer-hook-assumption"
          "|qualitySignal id=json-fallback-source"
          "|qualitySignal id=writeenv-fallback-source"
          "|qualitySignal id=typed-value-writer-source"
          "|qualitySignal id=json-roundtrip-witness"
          "|qualitySignal id=print-fallback-witness"
          "|qualitySignal id=writeenv-method-dispatch-witness"
          "|qualitySignal id=writeenv-roundtrip-witness-required"
          "|quality partial missing=writeenv-roundtrip-witness selectorCount=8 formCount=6 failureCaseCount=5"
          "next=search runtime-source writeenv printer hook"])
        (check-output-contains
         lens-output
         ["quality=verified"
          "|pattern id=poo-lens-slot"
          "|agentScenario id=agent-updates-poo-slots-without-lens-composition-semantics"
          "intent=query-slot-lens-and-lens-compose-before-writing-functional-slot-updates"
          "|selector role=lens-class symbol=Lens selector=gerbil-poo://mop.ss#Lens"
          "|selector role=lens-slot symbol=slot-lens selector=gerbil-poo://mop.ss#slot-lens"
          "|selector role=lens-compose symbol=.compose selector=gerbil-poo://mop.ss#Lens.compose"
          "|selector role=real-project-lens-test symbol=Lenses selector=gerbil-poo-test://t/mop-test.ss#Lenses"
          "|form role=lens-regression-test symbol=Lenses head=check-equal?"
          "|failureCase id=imperative-slot-update"
          "|qualitySignal id=lens-source"
          "|qualitySignal id=real-project-lens-test"
          "|qualitySignal id=functional-update-witness"
          "|quality verified missing=- selectorCount=4 formCount=3 failureCaseCount=1"
          "next=search pattern poo lens slot-lens"])
        (check-output-contains
         type-output
         ["quality=verified"
          "|pattern id=poo-type-validation-sealed"
          "|agentScenario id=agent-defines-poo-class-without-sealed-type-validation"
          "intent=query-sealed-class-and-validate-witness-before-writing-type-checked-poo-classes"
          "|selector role=class-descriptor symbol=Class. selector=gerbil-poo://mop.ss#Class."
          "|selector role=function-validator symbol=Function. selector=gerbil-poo://mop.ss#Function."
          "|selector role=generic-slot-validator symbol=slot-checker selector=gerbil-poo://mop.ss#slot-checker"
          "|selector role=real-project-validation-test symbol=mop-test selector=gerbil-poo-test://t/mop-test.ss#sealed-type-validation"
          "|form role=sealed-class-definition symbol=define-type head=define-type"
          "|form role=validation-regression-test symbol=validate head=validate"
          "|failureCase id=missing-required-typed-slot"
          "|failureCase id=sealed-extra-slot-assumption"
          "|failureCase id=unchecked-function-arity"
          "|qualitySignal id=real-project-mop-test"
          "|qualitySignal id=sealed-type-witness"
          "|qualitySignal id=validation-negative-witness"
          "|quality verified missing=- selectorCount=4 formCount=3 failureCaseCount=3"
          "next=search pattern poo sealed validate"])
        (check (not (contains? proto-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? trace-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? slot-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? io-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? lens-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? type-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (contains? proto-output "pending")) => #t)
        (check (not (contains? trace-output "pending")) => #t)
        (check (not (contains? slot-output "pending")) => #t)
        (check (not (contains? io-output "pending")) => #t)
        (check (not (contains? lens-output "pending")) => #t)
        (check (not (contains? type-output "pending")) => #t)))
    (test-case "agent scenario warns when macro syntax would violate generated-code policy"
      (let ((lang-output (search-output ["lang" "how" "macro" "syntax-case" "defsyntax" "."]))
            (pattern-output (search-output ["pattern" "I" "need" "macro" "syntax-case" "."])))
        (check-output-contains
         lang-output
         ["|fact id=hygienic-macro"
          "|agentScenario id=agent-does-not-know-gerbil-macro-phase-rules"
          "|selector role=macro-form-parser symbol=defsyntax selector=src/checker/forms.ss:13"
          "|failureCase id=generated-code-forbidden-form"
          "|qualitySignal id=forbidden-form-policy"])
        (check-output-contains
         pattern-output
         ["|pattern id=hygienic-macro"
          "|agentScenario id=agent-does-not-know-gerbil-macro-syntax-or-generated-code-policy"
          "|selector role=std-sugar-rule-macro symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
          "|selector role=std-sugar-phase-import symbol=for-syntax selector=gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"
          "|form role=macro-policy symbol=syntax-case"
          "|form role=std-sugar-rule-macro symbol=defrule head=defrule"
          "|form role=std-sugar-procedural-macro symbol=defsyntax-call head=defsyntax-call"
          "|failureCase id=generated-code-forbidden-form"
          "|qualitySignal id=runtime-source-std-sugar"
          "|qualitySignal id=for-syntax-import-witness"
          "|qualitySignal id=generated-code-policy"
          "quality verified missing=-"])
        (check (not (contains? pattern-output "pending")) => #t)))
    (test-case "agent scenario validates env and std quality before dialect guessing"
      (let ((env-output (search-output ["env" "which" "gxi" "load" "path" "."]))
            (std-output (search-output ["std" "how" "string" "prefix" "contains" "."]))
            (json-output (search-output ["std" "how" "parse" "json" "read-json" "."])))
        (check-output-contains
         env-output
         ["|fact id=active-gerbil-runtime"
          "|agentScenario id=agent-needs-active-gerbil-runtime-before-import-or-macro-claims"
          "|runtime gerbilHome="
          "gxiExists=#t"
          "gscExists=#t"
          "|failureCase id=stale-doc-runtime"
          "|qualitySignal id=active-gxi"
          "|qualitySignal id=runtime-load-path"])
        (check-output-contains
         std-output
         ["|fact id=std/srfi/13"
          "|agentScenario id=agent-does-not-know-gerbil-standard-string-module"
          "provider-imports-:std/srfi/13"
          "|failureCase id=guessed-racket-string-api"
          "|qualitySignal id=string-prefix-capability"
          "|qualitySignal id=string-contains-capability"])
        (check-output-contains
         json-output
         ["|fact id=std/text/json"
          "|agentScenario id=agent-needs-json-packet-validation-without-python-parser"
          "provider-imports-:std/text/json"
          "|failureCase id=foreign-json-parser"
          "|failureCase id=broad-json-import"
          "|qualitySignal id=read-json-capability"
          "|qualitySignal id=only-in-minimal-import"])
        (check (not (contains? std-output "pending")) => #t)))
    (test-case "std json machine packet exposes minimal Gerbil import mapping"
      (let* ((output (search-output ["std" "json" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (facts (json-get packet "facts"))
             (fact (car facts))
             (details (json-get fact "details")))
        (check (json-get packet "namespace") => "std")
        (check (json-get packet "evidenceGrade") => "fact")
        (check (json-get fact "id") => "std/text/json")
        (check (json-get details "module") => ":std/text/json")
        (check (json-get details "capabilities") => ["read-json"])
        (check (json-get details "minimalImport")
               => "(import (only-in :std/text/json read-json))")))
    (test-case "pattern json uses schema-backed extension mapping packet"
      (let* ((output (search-output ["pattern" "poo" "class" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (json-get packet "patternMapping"))
             (source-ref (json-get mapping "sourceRef"))
             (forms (json-get mapping "minimalForms"))
             (first-form (car forms))
             (template (json-get first-form "template"))
             (selectors (json-get mapping "selectors"))
             (mro-selector (list-ref selectors 5))
             (mro-form (list-ref forms 4))
             (failures (json-get mapping "failureCases"))
             (first-failure (car failures))
             (mro-failure (list-ref failures 3)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (json-get packet "namespace") => "pattern")
        (check (json-get packet "quality") => "verified")
        (check (json-get mapping "id") => "poo-object-system")
        (check (json-get mapping "extension") => "poo")
        (check (hash-key? mapping "sourceWorkspace") => #f)
        (check (json-get source-ref "kind") => "package-manager-download")
        (check (json-get source-ref "manager") => "gxpkg")
        (check (json-get source-ref "dependency")
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (json-get source-ref "pathPolicy") => "runtime-resolved")
        (check (json-get first-form "role") => "class-definition")
        (check (json-get first-form "selector")
               => "gerbil-poo://object.ss#defclass")
        (check (json-get mro-selector "role") => "method-resolution-order")
        (check (json-get mro-selector "selector")
               => "gerbil-runtime://c3.ss#class-precedence-list")
        (check (json-get mro-form "role") => "mro-regression-test")
        (check (json-get mro-form "selector")
               => "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance")
        (check (json-get template "head") => "defclass")
        (check (json-get template "operands")
               => ["(<Class> <Base>)" "(<slot> ...)"])
        (check (json-get template "keywords") => ["transparent: #t"])
        (check (json-get first-failure "riskKind") => "dialect-confusion")
        (check (json-get first-failure "badPattern")
               => "racket-class-or-generic-scheme-object")
        (check (json-get first-failure "selectors")
               => ["gerbil-poo://object.ss#defclass"
                   "gerbil-poo://mop.ss#.defgeneric"
                   "gerbil-poo://mop.ss#defmethod"])
        (check (json-get mro-failure "riskKind") => "semantic-regression-gap")
        (check (json-get mro-failure "correctiveAction")
               => "add-c3-linearization-and-slot-vector-witnesses")))
    (test-case "pattern json reports runtime witness quality for POO trace debug"
      (let* ((output (search-output ["pattern" "poo" "trace" "debug" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (json-get packet "patternMapping"))
             (source-ref (json-get mapping "sourceRef"))
             (selectors (json-get mapping "selectors"))
             (computed-selector (list-ref selectors 3))
             (forms (json-get mapping "minimalForms"))
             (computed-form (list-ref forms 2))
             (failures (json-get mapping "failureCases"))
             (first-failure (car failures)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (json-get packet "namespace") => "pattern")
        (check (json-get packet "quality") => "verified")
        (check (json-get packet "missing") => [])
        (check (json-get packet "witness") => "runtime-trace-poo-witness")
        (check (json-get packet "next") => "search pattern poo trace runtime witness")
        (check (json-get mapping "id") => "poo-trace-debug")
        (check (json-get mapping "sourceWorkspace") => #f)
        (check (json-get source-ref "pathPolicy") => "runtime-resolved")
        (check (json-get source-ref "dependency")
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (json-get computed-selector "role") => "computed-slot-wrapper")
        (check (json-get computed-selector "selector")
               => "gerbil-poo://debug.ss#trace-inherited-slot")
        (check (json-get computed-form "role") => "computed-slot-trace")
        (check (json-get (json-get computed-form "template") "keywords")
               => ["call-superfun-before-wrapping"])
        (check (json-get first-failure "riskKind") => "computed-slot-contract")
        (check (json-get first-failure "badPattern")
               => "trace-wrapper-that-never-calls-inherited-superfun")))
    (test-case "pattern json reports runtime boundary gaps for POO IO fallback"
      (let* ((output (search-output ["pattern" "poo" "json" "fallback" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (json-get packet "patternMapping"))
             (selectors (json-get mapping "selectors"))
             (writeenv-selector (list-ref selectors 5))
             (method-selector (list-ref selectors 6))
             (forms (json-get mapping "minimalForms"))
             (method-form (list-ref forms 5))
             (failures (json-get mapping "failureCases"))
             (direct-failure (list-ref failures 3))
             (printer-failure (list-ref failures 4)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (json-get packet "namespace") => "pattern")
        (check (json-get packet "quality") => "partial")
        (check (json-get packet "missing") => ["writeenv-roundtrip-witness"])
        (check (json-get packet "witness")
               => "runtime-json-print-writeenv-method-source-backed-io-fallback")
        (check (json-get packet "next")
               => "search runtime-source writeenv printer hook")
        (check (json-get mapping "id") => "poo-io-json-fallback")
        (check (json-get mapping "agentScenario")
               => "agent-customizes-poo-serialization-without-json-or-print-fallbacks")
        (check (json-get writeenv-selector "role") => "writeenv-runtime-boundary")
        (check (json-get writeenv-selector "selector")
               => "gerbil-runtime://builtin#writeenv")
        (check (json-get method-selector "role") => "writeenv-method-dispatch-witness")
        (check (json-get method-selector "selector")
               => "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch")
        (check (json-get method-form "role") => "writeenv-method-dispatch-witness")
        (check (json-get (json-get method-form "template") "head") => "method-ref")
        (check (json-get direct-failure "riskKind") => "runtime-internal-boundary")
        (check (json-get direct-failure "correctiveAction")
               => "use-write-json-pr-or-method-ref-dispatch-witness-until-writeenv-roundtrip-is-owned")
        (check (json-get printer-failure "riskKind") => "printer-hook-contract")
        (check (json-get printer-failure "badPattern")
               => "agent-assumes-write-output-roundtrips-through-poo-:wr")
        (check (not (contains? output ".data")) => #t)))
    (test-case "pattern json reports insufficient mapping without inventing extension facts"
      (let* ((output (search-output ["pattern" "unknown-extension" "--json" "."]))
             (packet (call-with-input-string output read-json)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (json-get packet "evidenceGrade") => "unknown")
        (check (json-get packet "quality") => "insufficient")
        (check (json-get packet "patternMapping") => #f)
        (check (json-get packet "missing")
               => ["extension-fact" "pattern-registry" "runnable-witness"])
        (check (json-get packet "witness") => "pending")
        (check (json-get packet "next") => "search extension <extension>")))
    (test-case "structural index packet satisfies IFC envelope"
      (check-structural-index-required-envelope))
    (test-case "structural index exposes queryable owner symbol dependency facts"
      (check-structural-index-queryable-facts))
    (test-case "structural index compact output exposes native POO facts"
      (let (output (search-output ["structural" "."]))
        (check-output-contains
         output
         ["|syntaxFact kind=class languageKind=defclass name=<Widget>"
          "role=class generic=- receiver=- receiverType=- supers=:object slots=name,count options=transparent: specializers=- dispatchArity=0"
          "|syntaxFact kind=method languageKind=defmethod name=:render"
          "role=method generic=:render receiver=widget receiverType=<Widget>"
          "specializers=widget:<Widget> dispatchArity=1"])))))
