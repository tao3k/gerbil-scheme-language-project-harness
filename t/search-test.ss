;;; -*- Gerbil -*-
(import :std/test
        :commands/search
        :support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        :unit/poo/runtime-witness
        :unit/search/structural-index)
(export search-test)

(def (search-output args)
  (call-with-output-string
    (lambda (out)
      (parameterize ((current-output-port out))
        (check (search-main args) => 0)))))

(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (string-contains output fragment) => #t))
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
      (let (output (call-with-output-string
                     (lambda (out)
                       (parameterize ((current-output-port out))
                         (check (search-main ["guide" "--view" "seeds" "."]) => 0)))))
        (check (string-prefix? "gerbil-scheme-harness guide" output) => #t)
        (check (string-contains output "|cmd prime=gerbil-scheme-harness search prime --view seeds .") => #t)
        (check (string-contains output "|cmd pipe=gerbil-scheme-harness search pipe '<term>' --view seeds .") => #t)
        (check (string-contains output "|cmd query-code=gerbil-scheme-harness query --selector <path:start-end> --workspace . --code") => #t)
        (check (string-contains output "|cmd env=gerbil-scheme-harness search env [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd runtime-source=gerbil-scheme-harness search runtime-source [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd lang=gerbil-scheme-harness search lang [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd std=gerbil-scheme-harness search std [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd extension=gerbil-scheme-harness search extension <extension> [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd pattern=gerbil-scheme-harness search pattern <feature-or-extension> [term ...] --view seeds .") => #t)
        (check (string-contains output "|cmd compare=gerbil-scheme-harness search compare <axis> [left right] --view seeds .") => #t)
        (check (string-contains output "|cmd structural-index=gerbil-scheme-harness search structural --json .") => #t)
        (check (string-contains output "|policy namespace-receipt=macro/module/type/poo edits should cite search env/lang/std/pattern/runtime-source output before editing") => #t)
        (check (string-contains output "|policy poo-io-runtime-source=POO :wr/writeenv changes should cite search runtime-source writeenv printer hook; hook guidance remains soft until real-project noise is reviewed") => #t)))
    (test-case "search pipe routes through compact fzf frontier"
      (let (output (search-output ["pipe" "guide" "."]))
        (check (string-contains output "[gerbil-search-fzf] query=guide") => #t)
        (check (string-contains output "recommendedNext=gerbil-scheme-harness search owner") => #t)))
    (test-case "env search exposes active runtime witness"
      (let (output (call-with-output-string
                     (lambda (out)
                       (parameterize ((current-output-port out))
                         (check (search-main ["env" "gxi" "."]) => 0)))))
        (check (string-contains output "evidenceGrade=fact") => #t)
        (check (string-contains output "|runtime gerbilHome=") => #t)
        (check (string-contains output "gxiExists=#t") => #t)
        (check (string-contains output "gscExists=#t") => #t)
        (check (not (string-contains output "pending")) => #t)))
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
          "clone-active-runtime-source-before-answering-language-or-macro-usage"
          "|failureCase id=memory-language-answer"
          "|failureCase id=wrong-runtime-version"
          "|failureCase id=unindexed-source-checkout"
          "|qualitySignal id=no-memory"
          "|qualitySignal id=version-matched-source"
          "|qualitySignal id=asp-state-managed-checkout"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (string-contains output ".data")) => #t)
        (check (not (string-contains output "pending")) => #t)))
    (test-case "runtime-source search routes std sugar to versioned source"
      (let (output (search-output ["runtime-source" "sugar" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-source"
          "repository=https://git.cons.io/mighty-gerbils/gerbil"
          "|qualitySignal id=source-index-required"
          "next=search runtime-source macro sugar module-sugar"])
        (check (not (string-contains output "pending")) => #t)))
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
        (check (not (string-contains output "pending")) => #t)))
    (test-case "runtime-source search routes writeenv printer hooks to versioned source"
      (let (output (search-output ["runtime-source" "writeenv" "printer" "hook" "."]))
        (check-output-contains
         output
         ["[gerbil-search-runtime-source]"
          "|fact id=gerbil-runtime-writeenv-source"
          "active-runtime-version-to-writeenv-source-acquisition-plan"
          "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"
          "selector=gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"
          "|failureCase id=memory-writeenv-answer"
          "|failureCase id=poo-writeenv-roundtrip-assumption"
          "|failureCase id=raw-runtime-source-search"
          "|qualitySignal id=writeenv-source-index-required"
          "|qualitySignal id=printer-hook-source-required"
          "next=search runtime-source writeenv printer hook"])
        (check (not (string-contains output ".data")) => #t)
        (check (not (string-contains output "pending")) => #t)))
    (test-case "runtime-source json uses schema-backed acquisition packet"
      (let* ((output (search-output ["runtime-source" "macro" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (runtime (hash-get packet "runtime"))
             (source-ref (hash-get packet "sourceRef"))
             (acquisition (hash-get packet "acquisition")))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-runtime-source-acquisition")
        (check (hash-get packet "namespace") => "runtime-source")
        (check (hash-get packet "authority") => "runtime-version-source")
        (check (hash-get packet "quality") => "version-matched-source-plan")
        (check (hash-get source-ref "kind") => "runtime-version-source")
        (check (hash-get source-ref "repository")
               => "https://git.cons.io/mighty-gerbils/gerbil")
        (check (hash-get source-ref "checkoutPolicy")
               => "exact-tag-from-active-runtime")
        (check (hash-get source-ref "statePathPolicy")
               => "asp-state-managed")
        (check (hash-get acquisition "owner") => "asp")
        (check (hash-get acquisition "operation")
               => "clone-or-fetch-checkout-index")
        (check (hash-get acquisition "stateNamespace")
               => "runtime-source/gerbil-scheme")
        (check (hash-get acquisition "indexOwner") => "asp-structural-index")
        (check (hash-get packet "next")
               => "search runtime-source macro sugar module-sugar")
        (check (string-prefix? "Gerbil v" (hash-get runtime "systemVersion")) => #t)
        (check (not (string-contains output ".data")) => #t)))
    (test-case "runtime-source json exposes writeenv printer hook selectors"
      (let* ((output (search-output ["runtime-source" "writeenv" "printer" "hook" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (facts (hash-get packet "facts"))
             (fact (car facts))
             (selectors (hash-get fact "selectors"))
             (writeenv-selector (car selectors))
             (write-object-selector (list-ref selectors 2))
             (failures (hash-get packet "failureCases"))
             (roundtrip-failure (list-ref failures 1)))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-runtime-source-acquisition")
        (check (hash-get packet "namespace") => "runtime-source")
        (check (hash-get packet "quality") => "version-matched-source-plan")
        (check (hash-get packet "missing") => [])
        (check (hash-get packet "witness")
               => "active-runtime-version-to-writeenv-source-acquisition-plan")
        (check (hash-get packet "next")
               => "search runtime-source writeenv printer hook")
        (check (hash-get fact "id") => "gerbil-runtime-writeenv-source")
        (check (hash-get writeenv-selector "role") => "writeenv-builtin")
        (check (hash-get writeenv-selector "selector")
               => "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv")
        (check (hash-get write-object-selector "role") => "runtime-write-object-owner")
        (check (hash-get write-object-selector "selector")
               => "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object")
        (check (hash-get roundtrip-failure "id")
               => "poo-writeenv-roundtrip-assumption")
        (check (not (string-contains output ".data")) => #t)))
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
        (check (not (string-contains output ".data")) => #t)
        (check (not (string-contains output "/Users/")) => #t)
        (check (not (string-contains output "/opt/homebrew")) => #t)))
    (test-case "compare json uses schema-backed packet"
      (let* ((output (search-output ["compare" "env" "active" "documented" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (comparison (car (hash-get packet "comparisons")))
             (left (hash-get comparison "left"))
             (right (hash-get comparison "right")))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-compare-packet")
        (check (hash-get packet "namespace") => "compare")
        (check (hash-get packet "authority") => "active-runtime-vs-documented")
        (check (hash-get packet "quality") => "verified")
        (check (hash-get packet "missing") => [])
        (check (hash-get comparison "id") => "env-active-documented")
        (check (hash-get comparison "result") => "active-runtime-authoritative")
        (check (hash-get left "kind") => "active-runtime")
        (check (hash-get right "status") => "non-authoritative")
        (check (not (string-contains output ".data")) => #t)
        (check (not (string-contains output "/Users/")) => #t)))
    (test-case "lang and std searches expose fact witnesses"
      (let ((lang-output (call-with-output-string
                           (lambda (out)
                             (parameterize ((current-output-port out))
                               (check (search-main ["lang" "hygienic-macro" "."]) => 0)))))
            (style-output (call-with-output-string
                            (lambda (out)
                              (parameterize ((current-output-port out))
                                (check (search-main ["lang" "style" "."]) => 0)))))
            (module-output (call-with-output-string
                             (lambda (out)
                               (parameterize ((current-output-port out))
                                 (check (search-main ["lang" "rename-in" "only-in" "."]) => 0)))))
            (std-output (call-with-output-string
                          (lambda (out)
                            (parameterize ((current-output-port out))
                              (check (search-main ["std" "srfi-13" "."]) => 0)))))
            (sugar-output (call-with-output-string
                            (lambda (out)
                              (parameterize ((current-output-port out))
                                (check (search-main ["std" "sugar" "defrule" "."]) => 0)))))
            (json-output (call-with-output-string
                           (lambda (out)
                             (parameterize ((current-output-port out))
                               (check (search-main ["std" "json" "."]) => 0))))))
        (check (string-contains lang-output "|fact id=hygienic-macro") => #t)
        (check (string-contains lang-output "selector=src/checker/forms.ss:13") => #t)
        (check (not (string-contains lang-output "pending")) => #t)
        (check (string-contains style-output "|fact id=scheme-style") => #t)
        (check (string-contains style-output "gerbil-utils-style-audit-and-harness-policy") => #t)
        (check (string-contains style-output "|failureCase id=legacy-test-directory") => #t)
        (check (string-contains style-output "|failureCase id=vague-definition-name") => #t)
        (check (string-contains style-output "|failureCase id=top-level-executable-call") => #t)
        (check (string-contains style-output "selector=gerbil-utils://t/base-test.ss#base-test") => #t)
        (check (string-contains style-output "|qualitySignal id=t-test-layout") => #t)
        (check (string-contains style-output "|qualitySignal id=real-project-t-tests") => #t)
        (check (string-contains style-output "|qualitySignal id=vague-definition-policy") => #t)
        (check (string-contains style-output "|qualitySignal id=top-level-executable-policy") => #t)
        (check (not (string-contains style-output "pending")) => #t)
        (check (string-contains module-output "|fact id=module-import") => #t)
        (check (string-contains module-output "runtime-source-module-sugar-import-export-sets") => #t)
        (check (string-contains module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in") => #t)
        (check (string-contains module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in") => #t)
        (check (string-contains module-output "selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out") => #t)
        (check (string-contains module-output "|failureCase id=racket-require-assumption") => #t)
        (check (string-contains module-output "|failureCase id=unchecked-rename-in") => #t)
        (check (string-contains module-output "|failureCase id=rename-out-confusion") => #t)
        (check (string-contains module-output "|qualitySignal id=module-sugar-source") => #t)
        (check (string-contains module-output "|qualitySignal id=import-set-witness") => #t)
        (check (string-contains module-output "|qualitySignal id=export-set-witness") => #t)
        (check (not (string-contains module-output "pending")) => #t)
        (check (string-contains std-output "|fact id=std/srfi/13") => #t)
        (check (string-contains std-output "provider-imports-:std/srfi/13") => #t)
        (check (not (string-contains std-output "pending")) => #t)
        (check (string-contains sugar-output "|fact id=std/sugar") => #t)
        (check (string-contains sugar-output "runtime-source-std-sugar-defrule-and-defsyntax") => #t)
        (check (string-contains sugar-output "selector=gerbil-runtime-source://src/std/sugar.ss#defrule") => #t)
        (check (string-contains sugar-output "|qualitySignal id=runtime-source-backed-std-module") => #t)
        (check (not (string-contains sugar-output "pending")) => #t)
        (check (string-contains json-output "|fact id=std/text/json") => #t)
        (check (string-contains json-output "provider-imports-:std/text/json") => #t)
        (check (string-contains json-output "|failureCase id=foreign-json-parser") => #t)
        (check (string-contains json-output "|qualitySignal id=read-json-capability") => #t)
        (check (not (string-contains json-output "pending")) => #t)))
    (test-case "pattern search exposes verified runnable witnesses"
      (let ((macro-output (call-with-output-string
                            (lambda (out)
                              (parameterize ((current-output-port out))
                                (check (search-main ["pattern" "hygienic-macro" "."]) => 0)))))
            (poo-output (call-with-output-string
                          (lambda (out)
                            (parameterize ((current-output-port out))
                              (check (search-main ["pattern" "poo" "object" "."]) => 0))))))
        (check (string-contains macro-output "quality=verified") => #t)
        (check (string-contains macro-output "witness=parser-and-test-backed-hygienic-macro-pattern") => #t)
        (check (string-contains macro-output "missing=-") => #t)
        (check (string-contains poo-output "sourceRef=package-manager-download:gxpkg:git.cons.io/mighty-gerbils/gerbil-poo:runtime-resolved") => #t)
        (check (string-contains poo-output "selector=gerbil-poo://object.ss#defclass") => #t)
        (check (string-contains poo-output "witness=dependency-backed-poo-mapping") => #t)
        (check (string-contains poo-output "missing=-") => #t)))
    (test-case "agent scenario routes unknown POO usage through extension then pattern guidance"
      (let ((extension-output (search-output ["extension" "poo" "syntax" "."]))
            (pattern-output (search-output ["pattern" "how" "do" "I" "write" "poo" "class" "method" "protocol" "."])))
        (check-output-contains
         extension-output
         ["[gerbil-search-extension]"
          "|extension name=poo"
          "next=search pattern poo syntax"])
        (check (not (string-contains extension-output "|form role=")) => #t)
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
        (check (not (string-contains pattern-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains pattern-output "pending")) => #t)))
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
        (check (not (string-contains proto-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains trace-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains slot-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains io-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains lens-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains type-output (string-append ".data" "/gerbil-poo"))) => #t)
        (check (not (string-contains proto-output "pending")) => #t)
        (check (not (string-contains trace-output "pending")) => #t)
        (check (not (string-contains slot-output "pending")) => #t)
        (check (not (string-contains io-output "pending")) => #t)
        (check (not (string-contains lens-output "pending")) => #t)
        (check (not (string-contains type-output "pending")) => #t)))
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
        (check (not (string-contains pattern-output "pending")) => #t)))
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
        (check (not (string-contains std-output "pending")) => #t)))
    (test-case "std json machine packet exposes minimal Gerbil import mapping"
      (let* ((output (search-output ["std" "json" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (facts (hash-get packet "facts"))
             (fact (car facts))
             (details (hash-get fact "details")))
        (check (hash-get packet "namespace") => "std")
        (check (hash-get packet "evidenceGrade") => "fact")
        (check (hash-get fact "id") => "std/text/json")
        (check (hash-get details "module") => ":std/text/json")
        (check (hash-get details "capabilities") => ["read-json"])
        (check (hash-get details "minimalImport")
               => "(import (only-in :std/text/json read-json))")))
    (test-case "pattern json uses schema-backed extension mapping packet"
      (let* ((output (search-output ["pattern" "poo" "class" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (hash-get packet "patternMapping"))
             (source-ref (hash-get mapping "sourceRef"))
             (forms (hash-get mapping "minimalForms"))
             (first-form (car forms))
             (template (hash-get first-form "template"))
             (selectors (hash-get mapping "selectors"))
             (mro-selector (list-ref selectors 5))
             (mro-form (list-ref forms 4))
             (failures (hash-get mapping "failureCases"))
             (first-failure (car failures))
             (mro-failure (list-ref failures 3)))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (hash-get packet "namespace") => "pattern")
        (check (hash-get packet "quality") => "verified")
        (check (hash-get mapping "id") => "poo-object-system")
        (check (hash-get mapping "extension") => "poo")
        (check (hash-key? mapping "sourceWorkspace") => #f)
        (check (hash-get source-ref "kind") => "package-manager-download")
        (check (hash-get source-ref "manager") => "gxpkg")
        (check (hash-get source-ref "dependency")
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get source-ref "pathPolicy") => "runtime-resolved")
        (check (hash-get first-form "role") => "class-definition")
        (check (hash-get first-form "selector")
               => "gerbil-poo://object.ss#defclass")
        (check (hash-get mro-selector "role") => "method-resolution-order")
        (check (hash-get mro-selector "selector")
               => "gerbil-runtime://c3.ss#class-precedence-list")
        (check (hash-get mro-form "role") => "mro-regression-test")
        (check (hash-get mro-form "selector")
               => "gerbil-runtime-test://src/gerbil/test/c3-test.ss#class-inheritance")
        (check (hash-get template "head") => "defclass")
        (check (hash-get template "operands")
               => ["(<Class> <Base>)" "(<slot> ...)"])
        (check (hash-get template "keywords") => ["transparent: #t"])
        (check (hash-get first-failure "riskKind") => "dialect-confusion")
        (check (hash-get first-failure "badPattern")
               => "racket-class-or-generic-scheme-object")
        (check (hash-get first-failure "selectors")
               => ["gerbil-poo://object.ss#defclass"
                   "gerbil-poo://mop.ss#.defgeneric"
                   "gerbil-poo://mop.ss#defmethod"])
        (check (hash-get mro-failure "riskKind") => "semantic-regression-gap")
        (check (hash-get mro-failure "correctiveAction")
               => "add-c3-linearization-and-slot-vector-witnesses")))
    (test-case "pattern json reports runtime witness quality for POO trace debug"
      (let* ((output (search-output ["pattern" "poo" "trace" "debug" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (hash-get packet "patternMapping"))
             (source-ref (hash-get mapping "sourceRef"))
             (selectors (hash-get mapping "selectors"))
             (computed-selector (list-ref selectors 3))
             (forms (hash-get mapping "minimalForms"))
             (computed-form (list-ref forms 2))
             (failures (hash-get mapping "failureCases"))
             (first-failure (car failures)))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (hash-get packet "namespace") => "pattern")
        (check (hash-get packet "quality") => "verified")
        (check (hash-get packet "missing") => [])
        (check (hash-get packet "witness") => "runtime-trace-poo-witness")
        (check (hash-get packet "next") => "search pattern poo trace runtime witness")
        (check (hash-get mapping "id") => "poo-trace-debug")
        (check (hash-get mapping "sourceWorkspace") => #f)
        (check (hash-get source-ref "pathPolicy") => "runtime-resolved")
        (check (hash-get source-ref "dependency")
               => "git.cons.io/mighty-gerbils/gerbil-poo")
        (check (hash-get computed-selector "role") => "computed-slot-wrapper")
        (check (hash-get computed-selector "selector")
               => "gerbil-poo://debug.ss#trace-inherited-slot")
        (check (hash-get computed-form "role") => "computed-slot-trace")
        (check (hash-get (hash-get computed-form "template") "keywords")
               => ["call-superfun-before-wrapping"])
        (check (hash-get first-failure "riskKind") => "computed-slot-contract")
        (check (hash-get first-failure "badPattern")
               => "trace-wrapper-that-never-calls-inherited-superfun")))
    (test-case "pattern json reports runtime boundary gaps for POO IO fallback"
      (let* ((output (search-output ["pattern" "poo" "json" "fallback" "--json" "."]))
             (packet (call-with-input-string output read-json))
             (mapping (hash-get packet "patternMapping"))
             (selectors (hash-get mapping "selectors"))
             (writeenv-selector (list-ref selectors 5))
             (method-selector (list-ref selectors 6))
             (forms (hash-get mapping "minimalForms"))
             (method-form (list-ref forms 5))
             (failures (hash-get mapping "failureCases"))
             (direct-failure (list-ref failures 3))
             (printer-failure (list-ref failures 4)))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (hash-get packet "namespace") => "pattern")
        (check (hash-get packet "quality") => "partial")
        (check (hash-get packet "missing") => ["writeenv-roundtrip-witness"])
        (check (hash-get packet "witness")
               => "runtime-json-print-writeenv-method-source-backed-io-fallback")
        (check (hash-get packet "next")
               => "search runtime-source writeenv printer hook")
        (check (hash-get mapping "id") => "poo-io-json-fallback")
        (check (hash-get mapping "agentScenario")
               => "agent-customizes-poo-serialization-without-json-or-print-fallbacks")
        (check (hash-get writeenv-selector "role") => "writeenv-runtime-boundary")
        (check (hash-get writeenv-selector "selector")
               => "gerbil-runtime://builtin#writeenv")
        (check (hash-get method-selector "role") => "writeenv-method-dispatch-witness")
        (check (hash-get method-selector "selector")
               => "gerbil-poo-witness://t/unit/poo/runtime-witness.ss#writeenv-method-dispatch")
        (check (hash-get method-form "role") => "writeenv-method-dispatch-witness")
        (check (hash-get (hash-get method-form "template") "head") => "method-ref")
        (check (hash-get direct-failure "riskKind") => "runtime-internal-boundary")
        (check (hash-get direct-failure "correctiveAction")
               => "use-write-json-pr-or-method-ref-dispatch-witness-until-writeenv-roundtrip-is-owned")
        (check (hash-get printer-failure "riskKind") => "printer-hook-contract")
        (check (hash-get printer-failure "badPattern")
               => "agent-assumes-write-output-roundtrips-through-poo-:wr")
        (check (not (string-contains output ".data")) => #t)))
    (test-case "pattern json reports insufficient mapping without inventing extension facts"
      (let* ((output (search-output ["pattern" "unknown-extension" "--json" "."]))
             (packet (call-with-input-string output read-json)))
        (check (hash-get packet "schemaId")
               => "agent.semantic-protocols.semantic-extension-pattern-mapping")
        (check (hash-get packet "evidenceGrade") => "unknown")
        (check (hash-get packet "quality") => "insufficient")
        (check (hash-get packet "patternMapping") => #f)
        (check (hash-get packet "missing")
               => ["extension-fact" "pattern-registry" "runnable-witness"])
        (check (hash-get packet "witness") => "pending")
        (check (hash-get packet "next") => "search extension <extension>")))
    (test-case "structural index packet satisfies IFC envelope"
      (check-structural-index-required-envelope))
    (test-case "structural index exposes queryable owner symbol dependency facts"
      (check-structural-index-queryable-facts))))
