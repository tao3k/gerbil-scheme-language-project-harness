;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent style policy.

(import :gerbil/gambit
        :std/test
        :std/misc/ports
        :std/misc/process
        :commands/check
        :parser/facade
        :policy/agent-style
        :policy/facade
        :policy/gxtest
        :scenario/policy
        :types/facade
        :unit/policy/poo-scenarios
        :policy/fixtures)
(export agent-style-policy-test)

;; Relpath
(def +agent-style-policy-scenario-fixtures-root+ "t/scenarios/policy")
(def +agent-style-policy-r013-rule-id+ "GERBIL-SCHEME-AGENT-R013")
(def +agent-style-policy-scenario-timing-schema-id+
  "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
(def +agent-style-policy-self-apply-r013-clean-owners+
  ["src/benchmark/gate.ss"])

;; : (-> Path Boolean )
(def (agent-style-policy-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean )
(def (agent-style-policy-scenario-entry? entry)
  (not (member entry '("." ".."))))

;; : (-> String Path )
(def (agent-style-policy-scenario-root entry)
  (path-expand entry +agent-style-policy-scenario-fixtures-root+))

;; : (-> Path Boolean )
(def (agent-style-policy-scenario-fixture-root? root)
  (and (agent-style-policy-directory? root)
       (agent-style-policy-directory? (path-expand "input" root))
       (agent-style-policy-directory? (path-expand "expected" root))))

;; : (-> (List Path) )
(def (agent-style-policy-scenario-roots)
  (filter agent-style-policy-scenario-fixture-root?
          (map agent-style-policy-scenario-root
               (filter agent-style-policy-scenario-entry?
                       (sort
                        (directory-files
                         +agent-style-policy-scenario-fixtures-root+)
                        string<?)))))

;; : (-> Path Path )
(def (agent-style-policy-scenario-benchmark-path root)
  (path-expand "benchmark.ss" root))

;; : (-> (List Path) )
(def (agent-style-policy-scenario-missing-benchmarks)
  (filter (lambda (path) (not (file-exists? path)))
          (map agent-style-policy-scenario-benchmark-path
               (agent-style-policy-scenario-roots))))

;; : (-> (List Timing) Boolean )
(def (agent-style-policy-scenario-timing-steps-measured? timings)
  (cond
   ((null? timings) #t)
   ((and (number? (hash-get (car timings) 'durationMs))
         (>= (hash-get (car timings) 'durationMs) 0))
    (agent-style-policy-scenario-timing-steps-measured? (cdr timings)))
   (else #f)))

;; : (-> ProjectIndex Relpath SourceFile )
(def (project-index-source-file-by-path index path)
  (let loop ((files (project-index-files index)))
    (cond
     ((null? files) #f)
     ((equal? (source-file-path (car files)) path) (car files))
     (else (loop (cdr files))))))

;; : (-> SourceFile (List Role) )
(def (source-file-higher-order-roles file)
  (map higher-order-fact-role
       (source-file-higher-order-forms file)))

;; : (-> String Path )
(def (agent-style-policy-scenario-path scenario-id)
  (path-expand scenario-id +agent-style-policy-scenario-fixtures-root+))

;; : (-> String HashTable )
(def (agent-style-policy-r013-scenario-context scenario-id)
  (let* ((scenario
          (make-policy-scenario
           scenario-id
           (agent-style-policy-scenario-path scenario-id)))
         (timing (policy-scenario-run/timed scenario))
         (result (hash-get timing 'result))
         (benchmark-contract (hash-get timing 'benchmarkContract))
         (before-matching
          (policy-scenario-findings
           result
           'before
           +agent-style-policy-r013-rule-id+))
         (after-matching
          (policy-scenario-findings
           result
           'after
           +agent-style-policy-r013-rule-id+))
         (finding (car before-matching))
         (details (type-finding-details finding)))
    (hash (timing timing)
          (result result)
          (timings (hash-get timing 'timings))
          (benchmarkContract benchmark-contract)
          (beforeMatching before-matching)
          (afterMatching after-matching)
          (finding finding)
          (details details)
          (qualityReference (hash-get details 'qualityReference))
          (expectedReferenceExamples
           (hash-get benchmark-contract 'expectedReferenceExamples))
          (expectedQualitySignals
           (hash-get benchmark-contract 'expectedQualitySignals)))))

;; : (-> ProjectIndex Relpath (List TypeFinding) )
(def (agent-style-policy-r013-findings-for-owner index path)
  (filter (lambda (finding)
            (equal? (type-finding-path finding) path))
          (typed-combinator-style-findings index)))

;; : (-> Any (List Any) Boolean )
(def (agent-style-member? item items)
  (if (member item items) #t #f))

;; : (-> (List Any) (List Any) Boolean )
(def (agent-style-all-members? items candidates)
  (cond
   ((null? items) #t)
   ((agent-style-member? (car items) candidates)
    (agent-style-all-members? (cdr items) candidates))
   (else #f)))

;; : (-> (List Any) (List Integer) (List Any) )
(def (agent-style-select-indexes items indexes)
  (map (lambda (index) (list-ref items index)) indexes))

;; : (-> HashTable String String Void )
(def (agent-style-check-r013-scenario! context scenario-id feature)
  (let ((timing (hash-get context 'timing))
        (timings (hash-get context 'timings))
        (benchmark-contract (hash-get context 'benchmarkContract))
        (before-matching (hash-get context 'beforeMatching))
        (after-matching (hash-get context 'afterMatching)))
    (check (hash-get timing 'schemaId)
           => +agent-style-policy-scenario-timing-schema-id+)
    (check (hash-get timing 'scenarioId) => scenario-id)
    (check (length timings) => 4)
    (check (agent-style-policy-scenario-timing-steps-measured? timings)
           => #t)
    (check (hash-get benchmark-contract 'feature) => feature)
    (check (hash-get benchmark-contract 'rule)
           => +agent-style-policy-r013-rule-id+)
    (check (hash-get timing 'performanceStatus) => "pass")
    (check (length before-matching) => 1)
    (check after-matching => [])))

;; : (-> HashTable (List Integer) (List Integer) Void )
(def (agent-style-check-r013-quality-reference! context example-indexes signal-indexes)
  (let* ((benchmark-contract (hash-get context 'benchmarkContract))
         (quality-reference (hash-get context 'qualityReference))
         (expected-reference-examples
          (hash-get context 'expectedReferenceExamples))
         (expected-quality-signals
          (hash-get context 'expectedQualitySignals)))
    (check (hash-get quality-reference 'referencePattern)
           => (hash-get benchmark-contract 'expectedReferencePattern))
    (check (agent-style-all-members?
            (agent-style-select-indexes expected-reference-examples example-indexes)
            (hash-get quality-reference 'referenceExamples))
           => #t)
    (check (agent-style-all-members?
            (agent-style-select-indexes expected-quality-signals signal-indexes)
            (hash-get quality-reference 'qualitySignals))
           => #t)))

;; : (-> HashTable (List String) (List String) Void )
(def (agent-style-check-r013-scenario-learning! context sources axes)
  (let (benchmark-contract (hash-get context 'benchmarkContract))
    (check (agent-style-all-members?
            sources
            (hash-get benchmark-contract 'learnedStyleSources))
           => #t)
    (check (string? (hash-get benchmark-contract 'antiAiScaffoldIntent))
           => #t)
    (check (agent-style-all-members?
            axes
            (hash-get benchmark-contract 'scenarioQualityAxes))
           => #t)))

;; PolicyTest
(def agent-style-typed-policy-test
  (test-suite "gerbil scheme harness typed style policy"
    (test-case "policy scenario fixtures declare benchmark contracts"
          (check (agent-style-policy-scenario-missing-benchmarks) => []))
    (test-case "typed-combinator-style self-apply keeps repaired owners clean"
          (let (index (collect-project "."))
            (for-each
             (lambda (path)
               (check (agent-style-policy-r013-findings-for-owner index path)
                      => []))
             +agent-style-policy-self-apply-r013-clean-owners+)))
    (test-case "typed-combinator-style warns on anonymous result index protocols"
          (let* ((root ".run/policy-result-index-scaffold")
                 (src (string-append root "/src"))
                 (owner (string-append src "/demo"))
                 (path "src/demo/core.ss"))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/demo)\n(export unpack)\n;; unpack\n;;   : (-> Result (List Any))\n;;   | type Result = Vector\n;;   | doc m%\n;;       `unpack result` projects an anonymous result vector.\n;;     %\n(def (unpack result)\n  (list (vector-ref result 0)\n        (vector-ref result 1)))\n")
            (let* ((index (collect-project root))
                   (findings
                    (agent-style-policy-r013-findings-for-owner index path))
                   (finding (car findings))
                   (details (type-finding-details finding)))
              (check (length findings) => 1)
              (check (agent-style-member?
                      "result-index-scaffold"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "anonymous-result-protocol"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "replace anonymous vector-ref result/index protocols with values binding, named records, or a small domain object boundary"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
    (test-case "agent policy validates controlled macro syntax scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "controlled-macro-syntax"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference
                  (hash-get details 'qualityReference)))
            (agent-style-check-r013-scenario!
             context
             "controlled-macro-syntax"
             "macro-hygiene")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["macro-hygiene-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "controlled macro syntax boundary")
            (check (agent-style-member?
                    "controlled-macro-syntax-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "syntax-case/with-syntax transformer shape"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (agent-style-member?
                    "hygienic macro boundary"
                    (hash-get details 'controlledMacroSyntaxSignals))
                   => #t)
            (check (hash-get details 'controlledMacroTargets)
                   => ["with-order-field"])
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-controlled-macro-helper")
            (check (agent-style-member?
                    "gerbil-utils/autocurry.ss#syntax-rules"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://gerbil/compiler/method.ss#ast-case-with-syntax-map-cut"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "macro-hygiene-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "with-syntax-reconstruction-boundary"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)))
    (test-case "agent policy validates generator control scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "generator-control-performance"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "generator-control-performance"
             "generator-control")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["generator-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "push/pull generator control inversion boundary")
            (check (agent-style-member?
                    "generator-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "generating-fold reducer"
                    (hash-get details 'generatorCombinatorSignals))
                   => #t)
            (check (hash-get details 'generatorContractTargets)
                   => ["sum-generated"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 1))))
    (test-case "agent policy validates list combinator boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "list-combinator-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "list-combinator-boundary"
             "list-combinator-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["list-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "manual list recursion to expression-level traversal boundary")
            (check (agent-style-member?
                    "list-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace hand-written list recursion scaffolding with map/filter/fold or a named reducer boundary"
                    (hash-get details 'listCombinatorBoundarySignals))
                   => #t)
            (check (hash-get details 'listCombinatorBoundaryTargets)
                   => ["render-active-orders"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3)
             (list 0 1 2))))
    (test-case "agent policy validates functional idiom scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "functional-idiom"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "functional-idiom"
             "functional-idiom")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["functional-idiom" "list-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "manual recursion to fold/pipeline and lambda-match boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "manual-loop-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "list-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness"
                    (hash-get details 'qualityFacetSteering))
                   => #t)
            (check (agent-style-member?
                    "replace hand-written list recursion scaffolding with map/filter/fold or a named reducer boundary"
                    (hash-get details 'listCombinatorBoundarySignals))
                   => #t)
            (check (hash-get details 'listCombinatorBoundaryTargets)
                   => ["total"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1 2 3)
             (list 0 1 2 3))))
    (test-case "agent policy validates destructuring combinator boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "destructuring-combinator-boundary"))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "destructuring-combinator-boundary"
             "destructuring-combinator-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils" "gerbil-poo"]
             ["destructuring-combinator-boundary" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "temporary destructuring scaffolding to native match, selector, or syntax-local boundary")
            (check (agent-style-member?
                    "destructuring-combinator-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace repeated car/cdr/assq scaffolding with a named selector or match boundary"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "prefer native match/apply destructuring when it removes runtime probing"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "use syntax-local metadata lookup when the shape is known at expansion time"
                    (hash-get details 'destructuringBoundarySignals))
                   => #t)
            (check (hash-get details 'destructuringBoundaryTargets)
                   => ["render-event"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 5 7)
             (list 0 1 2 4))))
    (test-case "agent policy validates protocol serialization boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "protocol-serialization-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "protocol-serialization-boundary"
             "protocol-serialization-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo" "gerbil-utils"]
             ["protocol-serialization-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "protocol-serialization-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split JSON/string/bytes/marshal representation layers"
                    (hash-get details 'serializationBoundarySignals))
                   => #t)
            (check (hash-get details 'serializationBoundaryTargets)
                   => ["encode-wire"])
            (check (agent-style-member?
                    "anti-ai-scaffold-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "replace one-owner protocol conversion scaffolding with local adapter boundaries"
                    (hash-get details 'antiAiScaffoldSignals))
                   => #t)
            (check (hash-get details 'antiAiScaffoldTargets)
                   => ["encode-wire"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 2))))
    (test-case "agent policy validates concurrency control boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "concurrency-control-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "concurrency-control-boundary"
             "concurrency-control-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["concurrency-control-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "concurrency-control-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "split spawn/join/mutex/race responsibilities"
                    (hash-get details 'concurrencyControlBoundarySignals))
                   => #t)
            (check (agent-style-member?
                    "preserve reentry guards and cleanup around dynamic-wind/unwind boundaries"
                    (hash-get details 'concurrencyControlBoundarySignals))
                   => #t)
            (check (hash-get details 'concurrencyControlBoundaryTargets)
                   => ["run-jobs"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2 3)
             (list 0 1 3))))
    (test-case "agent policy validates typeclass wrapper adapter scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "typeclass-wrapper-adapter"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "typeclass-wrapper-adapter"
             "typeclass-wrapper-adapter")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo"]
             ["poo-typeclass-algebra-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "poo-typeclass-algebra-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
                    (hash-get details 'typeclassAlgebraSignals))
                   => #t)
            (check (hash-get details 'typeclassAlgebraTargets)
                   => ["WrappedCodec."])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2)
             (list 0 2))))
    (test-case "agent policy validates slot lens boundary scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "slot-lens-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "slot-lens-boundary"
             "slot-lens-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-poo"]
             ["slot-lens-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "slot-lens-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "introduce local slot descriptor or lens helpers"
                    (hash-get details 'slotLensBoundarySignals))
                   => #t)
            (check (hash-get details 'slotLensBoundaryTargets)
                   => ["rename-widget"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 2)
             (list 0 2))))
    (test-case "agent policy validates exception continuation scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "exception-continuation-boundary"))
                 (details (hash-get context 'details)))
            (agent-style-check-r013-scenario!
             context
             "exception-continuation-boundary"
             "exception-continuation-boundary")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["exception-continuation-boundary" "anti-ai-scaffold"])
            (check (agent-style-member?
                    "exception-continuation-boundary"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "log exception context before re-raising"
                    (hash-get details 'exceptionContinuationBoundarySignals))
                   => #t)
            (check (hash-get details
                             'exceptionContinuationBoundaryTargets)
                   => ["run-checked"])
            (agent-style-check-r013-quality-reference!
             context
             (list 0 1)
             (list 0 2))))
    (test-case "agent policy validates higher-order composition scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "higher-order-composition-performance"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "higher-order-composition-performance"
             "higher-order-composition")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil://" "gerbil-utils"]
             ["higher-order-composition" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "wrapper lambda to composition boundary")
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#left-to-right"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "cut-prefix-predicate"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "thin-wrapper-elimination"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member? "function-composition" higher-order-roles)
                   => #t)))
    (test-case "agent policy validates case-lambda function factory scenario under performance gate"
          (let* ((context
                  (agent-style-policy-r013-scenario-context
                   "case-lambda-function-factory"))
                 (result (hash-get context 'result))
                 (benchmark-contract (hash-get context 'benchmarkContract))
                 (details (hash-get context 'details))
                 (quality-reference (hash-get context 'qualityReference))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (agent-style-check-r013-scenario!
             context
             "case-lambda-function-factory"
             "case-lambda-function-factory")
            (agent-style-check-r013-scenario-learning!
             context
             ["gerbil-utils"]
             ["case-lambda-function-factory" "anti-ai-scaffold"])
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "case-lambda arity-specialized function factory")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get benchmark-contract 'expectedReferenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get benchmark-contract 'expectedQualitySignals))
                   => #t)
            (check (agent-style-member?
                    "wrapper-lambda-drift"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (agent-style-member?
                    "function-specialization-opportunity"
                    (hash-get details 'qualityFacets))
                   => #t)
            (check (hash-get quality-reference 'referencePattern)
                   => "gerbil-utils-higher-order-expression")
            (check (agent-style-member?
                    "gerbil-utils/base.ss#case-lambda specializers"
                    (hash-get quality-reference 'referenceExamples))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-abstraction"
                    (hash-get quality-reference 'qualitySignals))
                   => #t)
            (check (agent-style-member?
                    "multi-arity-function"
                    higher-order-roles)
                   => #t)))
    (test-case "typed-combinator-style policy is enabled by default"
          (let* ((root ".run/policy-typed-combinator-style-default")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching)))
              (check (length matching) => 1)
              (check (type-finding-severity finding) => "warning")
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (type-finding-selector finding) => "src/orders/core.ss")
              (check (hash-get (type-finding-details finding) 'styleGuide)
                     => "typed-combinator-style")
              (check (hash-get (type-finding-details finding) 'expectedCommentShape)
                     => "adjacent Gerbil contract projection block such as ;; : (forall (a) (-> (-> a a Order) (List a) (List a) Order))")
              (check (hash-get (type-finding-details finding) 'signatureShape)
                     => "adjacent Gerbil contract/signature projection using ;; : (forall (a) (-> Input Output)), optional ;; | type aliases, U unions, Values, and Refine predicates")
              (check (hash-get (type-finding-details finding) 'contractLinePolicy)
                     => "multi-line typed-combinator-style contracts are allowed when needed to preserve precision")
              (check (hash-get (type-finding-details finding) 'compositionShape)
                     => "compact expression-level helper or combinator chain; prefer map/filter/fold/cut/curry/compose when behavior fits")
              (check (hash-get (type-finding-details finding) 'qualityReference)
                     => "gerbil-utils")
              (check (hash-get (type-finding-details finding) 'functionShape)
                     => "single-purpose expression-returning helper; one visible data-flow shape per function")
              (check (hash-get (type-finding-details finding) 'expressionLevelRewrite)
                     => "extract predicate/mapper/reducer helpers, then compose with filter-map/map/fold/andmap/ormap/cut/curry/compose when behavior fits")
              (check (hash-get (type-finding-details finding) 'optimizationBoundary)
                     => "when using case-lambda or a specialized branch, comment why that branch exists and keep the comment about the boundary, not the code mechanics")
              (check (agent-style-member?
                      "legacy contracts split at top-level <-, not nested arrows"
                      (hash-get (type-finding-details finding)
                                'gerbilContractProjectionSignals))
                     => #t))))
    (test-case "typed-combinator-style policy rejects partial definition coverage"
          (let* ((root ".run/policy-typed-combinator-style-partial")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Order <- Order\n(def (order-total order) order)\n(def (order-tax order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
            (check (hash-get details 'definitionCount) => 2)
            (check (hash-get details 'typedCommentCount) => 1)
            (check (hash-get details 'missingTypedCommentCount) => 1)
            (check (hash-get details 'qualityReference) => "gerbil-utils")
            (check (hash-get details 'agentRepairStandard)
                   => "rewrite toward gerbil-utils style: small algebraic helpers, dense but readable composition, minimal let*/mutation scaffolding"))))
    (test-case "typed-combinator-style policy accepts algebraic contracts"
          (let* ((root ".run/policy-typed-combinator-style-contract")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> Order Money)\n(def (order-total order) order)\n;; : (-> (List Order) (List Money))\n;; | type Money = Number\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))
    (test-case "typed-combinator-style policy reports boolean normalization scaffold"
          (let* ((root ".run/policy-typed-combinator-style-boolean-normalization")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (List Symbol) Boolean)\n(def (selected? choices)\n  (not (not (member 'ready choices))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (facets (hash-get details 'qualityFacets))
                   (steering (hash-get details 'qualityFacetSteering)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (hash-get details 'qualityRepairTriggered) => #t)
              (check (agent-style-member? "boolean-normalization-drift" facets)
                     => #t)
              (check (agent-style-member? "generated-scaffold-shape" facets)
                     => #t)
              (check (agent-style-member?
                      "replace double-negation scaffolding with the underlying boolean expression, or name the predicate boundary when truthiness normalization is intentional"
                      steering)
                     => #t))))
    (test-case "typed-combinator-style policy reports method-table lambda drift"
          (let* ((root ".run/policy-typed-combinator-style-method-table")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n\
(define-type (Box @ [Wrapper.] T .wrap .unwrap)\n\
  .map: (lambda (f x) (.wrap (f (.unwrap x))))\n\
  .unwrap*: (cut .unwrap <>))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (facets (hash-get details 'qualityFacets))
                   (steering (hash-get details 'qualityFacetSteering)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (hash-get details 'qualityRepairTriggered) => #t)
              (check (agent-style-member? "method-table-lambda-drift" facets)
                     => #t)
              (check (agent-style-member? "method-table-combinator-body" facets)
                     => #t)
              (check (agent-style-member?
                      "repair method-table lambdas by extracting slot-shaped helpers or using cut/curry/compose while preserving the receiver/protocol boundary"
                      steering)
                     => #t))))
    (test-case "typed-combinator-style policy rejects placeholder type variables"
          (let* ((root ".run/policy-typed-combinator-style-placeholder-token")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (List XX) NormalizeItems)\n(def (normalize-items xs) xs)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (examples (hash-get details 'invalidTypedContractExamples))
                   (example (car examples)))
              (check (length matching) => 1)
              (check (hash-get details 'invalidTypedContractCount) => 1)
              (check (agent-style-member?
                      "placeholder-type-variable-token"
                      (hash-get details 'invalidTypedContractReasons))
                     => #t)
              (check (hash-get example 'definition) => "normalize-items"))))
    (test-case "typed-combinator-style policy rejects structural pseudo types"
          (let* ((root ".run/policy-typed-combinator-style-structural-pseudo-type")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> (List) Boolean)\n(def (ready? orders) #t)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (examples (hash-get details 'invalidTypedContractExamples))
                   (example (car examples)))
              (check (length matching) => 1)
              (check (hash-get details 'invalidTypedContractCount) => 1)
              (check (agent-style-member?
                      "type-signature:List-requires-one-parameter"
                      (hash-get details 'invalidTypedContractReasons))
                     => #t)
              (check (hash-get example 'definition) => "ready?"))))
    (test-case "typed-combinator-style policy accepts keyword-aware contracts"
          (let* ((root ".run/policy-typed-combinator-style-keyword-contract")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> String SlotPrototype supers: (List SlotProfile) SlotProfile)\n(def (slot-profile name slots supers: (supers '())) slots)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))
    (test-case "typed-combinator-style policy rejects malformed runtime contract arrows"
          (let* ((root ".run/policy-typed-combinator-style-runtime-contract-arrow")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; : (-> Order Order)\n;; | contract Dyn -> (List) -> Dyn\n(def (normalize-order order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "runtime-contract[0]:function-parameter[1]:list-element:unknown-type"
                      (hash-get details 'invalidTypedContractReasons))
                     => #t))))
    (test-case "typed-combinator-style keeps legacy typed contract migration passive by default"
          (let* ((root ".run/policy-typed-combinator-style-legacy-migration")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Money <- Order\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))
    (test-case "typed-combinator-style policy rejects sparse implementation coverage"
          (let* ((root ".run/policy-typed-combinator-style-sparse-coverage")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Money <- Order\n(def (order-total order) order)\n;; Tax <- Order\n(def (order-tax order) order)\n;; (List Money) <- (List Order)\n(def (order-totals orders) (map order-total orders))\n;; Money <- Order\n(def (order-net order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'missingImplementationEvidence) => #f)
              (check (hash-get details 'implementationCoverageInsufficient) => #t)
              (check (hash-get details 'functionDefinitionCount) => 4)
              (check (hash-get details 'coveredDefinitionCount) => 1)
              (check (hash-get details 'minimumCoveredDefinitionCount) => 2)
              (check (hash-get details 'uncoveredDefinitionCount) => 3)
              (check (agent-style-member?
                      "order-net"
                      (hash-get details 'uncoveredDefinitions))
                     => #t)
              (check (agent-style-member?
                      "expression-level-composition"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "prefer map/filter/filter-map/fold pipelines; extract predicate, mapper, or reducer helpers before rewriting loops"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
    (test-case "typed-combinator-style policy triggers on native quality facets"
          (let* ((root ".run/policy-typed-combinator-style-native-facets")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Integer <- (List Number)\n(def (order-total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (fact (car (project-typed-contract-facts index)))
                   (quality-facets (typed-contract-fact-quality-facets fact))
                   (repair-evidence (typed-contract-fact-repair-evidence fact)))
              (check (length matching) => 1)
              (check (type-finding-severity finding) => "warning")
              (check (hash-get details 'qualityRepairTriggered) => #t)
              (check (agent-style-member? "manual-loop-drift" quality-facets)
                     => #t)
              (check (agent-style-member? "combinator-candidate" quality-facets)
                     => #t)
              (check (agent-style-member?
                      "replace manual loops with map/filter/filter-map/fold pipelines when parser facts show no IO/state/generator witness"
                      (hash-get details 'qualityFacetSteering))
                     => #t)
              (check (agent-style-member?
                      "λ/lambda-match local destructuring"
                      (hash-get details 'gerbilUtilsImplementationSignals))
                     => #t)
              (check (agent-style-member?
                      "fun named lambda abstraction"
                      (hash-get details 'gerbilUtilsImplementationSignals))
                     => #t)
              (check (hash-get repair-evidence 'factSource) => "native-parser")
              (check (agent-style-member?
                      "replace-manual-loop-with-higher-order-combinator-when-no-state-witness"
                      (hash-get repair-evidence 'allowedMoves))
                     => #t))))
    (test-case "typed-combinator-style exposes generator combinator steering"
          (let* ((root ".run/policy-typed-combinator-style-generator-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Number <- (Generating Number)\n(def (sum-generated source)\n  (let loop ((next source) (acc 0))\n    acc))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "generator-combinator-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "generating-fold reducer"
                      (hash-get details 'generatorCombinatorSignals))
                     => #t)
              (check (hash-get details 'generatorContractTargets)
                     => ["sum-generated"])
              (check (agent-style-member?
                      "when contracts mention Generating, prefer gerbil-utils/generator.ss combinators such as generating-map, generating-fold, generating-partition, and generating-merge before hand-written producer loops"
                      (hash-get details 'qualityFacetSteering))
                     => #t))))
    (test-case "typed-combinator-style exposes controlled macro syntax steering"
          (let* ((root ".run/policy-typed-combinator-style-controlled-macro-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/macros")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/macros)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order-field stx)\n  #'(void))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "controlled-macro-syntax-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "syntax-case/with-syntax transformer shape"
                      (hash-get details 'controlledMacroSyntaxSignals))
                     => #t)
              (check (hash-get details 'controlledMacroTargets)
                     => ["with-order-field"]))))
    (test-case "typed-combinator-style exposes POO typeclass algebra steering"
          (let* ((root ".run/policy-typed-combinator-style-typeclass-steering")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/object)\n(def (order-id value) value)\n(define-type (OrderFunctor. @ Functor.)\n  .map: map\n  .tap: tap\n  .ap: ap)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (agent-style-member?
                      "poo-typeclass-algebra-boundary"
                      (hash-get details 'qualityFacets))
                     => #t)
              (check (agent-style-member?
                      "Functor. map/tap/ap algebra"
                      (hash-get details 'typeclassAlgebraSignals))
                     => #t)
              (check (hash-get details 'typeclassAlgebraTargets)
                     => ["OrderFunctor."]))))))
;; PolicyTest
(def agent-style-comment-policy-test
  (test-suite "gerbil scheme harness comment style policy"
    (test-case "comment-quality policy rejects contract-only engineering comments"
          (let* ((root ".run/policy-comment-quality-contract-only")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n;;; Fixture has module intent so only definition comment quality is tested.\n(package: sample/orders)\n;; Money <- Order\n(def (order-total order) order)\n;; (List Money) <- (List Order)\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R015" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (example (car (hash-get details 'weakCommentExamples)))
                   (parser-evidence (hash-get example 'parserEvidence))
                   (matched-fact (car (hash-get parser-evidence 'matchedFacts)))
                   (repair (finding-agent-repair-json finding)))
              (check (length matching) => 1)
              (check (hash-get details 'weakCommentCount) => 1)
              (check (hash-get details 'evidenceSource)
                     => "parser-owned commentQualityFacts.evidence")
              (check (hash-get details 'repairInstruction)
                     => "write adjacent engineering comment lines when parserEvidence needs them; concise prose, bullets, or Boundary/Invariant/Intent labels are all valid")
              (check (hash-get example 'target) => "order-totals")
              (check (hash-get example 'quality) => "weak")
              (check (hash-get example 'commentKind) => "contract-only")
              (check (hash-get parser-evidence 'definition) => "order-totals")
              (check (hash-get parser-evidence 'context) => "higher-order")
              (check (hash-get parser-evidence 'matchedFactCount) => 1)
              (check (hash-get matched-fact 'factKind) => "higher-order")
              (check (hash-get matched-fact 'role) => "sequence-map")
              (check (hash-get details 'typedContractBoundary)
                     => "typed contract comments describe algebraic shape only and may use adjacent multi-line contract blocks when needed")
              (check (hash-get repair 'nextCommand)
                     => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style"))))
    (test-case "comment-quality policy rejects compressed engineering comments"
          (let* ((root ".run/policy-comment-quality-compressed")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Fixture owns the comment-quality compression scenario.\n(package: sample/orders)\n;;; Boundary: order-totals maps order-total across orders; keep higher-order data-flow visible.\n;; (List Money) <- (List Order)\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R015" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (example (car (hash-get details 'weakCommentExamples))))
              (check (length matching) => 1)
              (check (hash-get example 'target) => "order-totals")
              (check (hash-get example 'commentKind) => "compressed-engineering")
              (check (hash-get example 'quality) => "weak")
              (check (hash-get example 'reasons)
                     => ["compressed-engineering-comment-needs-adjacent-lines"])
              (check (hash-get details 'commentLinePolicy)
                     => "split multi-clause engineering rationale across adjacent comment lines when it improves confidence; do not squeeze rationale clauses into one semicolon-separated line"))))
    (test-case "typed-combinator-style policy rejects typed contracts without implementation evidence"
          (let* ((root ".run/policy-typed-combinator-style-no-implementation-evidence")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Money <- Order\n(def (order-total order) order)\n;; Tax <- Order\n(def (order-tax order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedCommentCount) => 2)
              (check (hash-get details 'missingTypedCommentCount) => 0)
              (check (hash-get details 'implementationEvidenceCount) => 0)
              (check (hash-get details 'missingImplementationEvidence) => #t)
              (check (hash-get details 'passiveRepairFlow)
                     => "policy-finding -> agentRepair -> guide-code -> bounded edit")
              (check (hash-get details 'implementationEvidenceSource)
                     => "parser-owned higherOrderFacts plus callFacts; do not use raw text heuristics"))))
    (test-case "typed-combinator-style policy rejects Any contracts"
          (let* ((root ".run/policy-typed-combinator-style-any")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Any <- Any\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'definitionCount) => 1)
              (check (hash-get details 'typedCommentCount) => 0)
              (check (hash-get details 'validTypedContractCount) => 0)
              (check (hash-get details 'invalidTypedContractCount) => 1)
              (check (hash-get details 'missingTypedCommentCount) => 1))))
    (test-case "typed-combinator-style policy rejects placeholder contracts"
          (let* ((root ".run/policy-typed-combinator-style-placeholder")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; (List XX) <- Fact Value\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedCommentCount) => 0)
              (check (hash-get details 'invalidTypedContractCount) => 1)
              (check (hash-get details 'missingTypedCommentCount) => 1)
              (check (hash-get details 'invalidReason)
                     => "typed-combinator-style comments must be parser-owned adjacent algebraic transform signatures; see invalidTypedContractReasons for exact parser reasons")
              (check (hash-get details 'invalidTypedContractReasons)
                     => ["placeholder-contract-without-domain-or-higher-order-shape"])
              (check (hash-get (car (hash-get details 'invalidTypedContractExamples))
                               'contract)
                     => "(List XX) <- Fact Value")
              (check (hash-get (car (hash-get details 'invalidTypedContractExamples))
                               'quality)
                     => "invalid"))))
    (test-case "typed-combinator-style policy rejects inline function names"
          (let* ((root ".run/policy-typed-combinator-style-inline-name")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n;; Money <- Order ; order-total\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedCommentCount) => 0)
              (check (hash-get details 'invalidTypedContractCount) => 1)
              (check (hash-get details 'missingTypedCommentCount) => 1))))
    (test-case "typed-combinator-style policy rejects detached ledger contracts"
          (let* ((root ".run/policy-typed-combinator-style-ledger")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (order-total order) order)\n\n;;; typed-combinator-style ledger\n;; Money <- Order\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedCommentCount) => 0)
              (check (hash-get details 'missingTypedCommentCount) => 1)
              (check (hash-get details 'adjacency) => "definition-leading-comment"))))
    (test-case "typed-combinator-style policy covers t scheme owners"
          (let* ((root ".run/policy-typed-combinator-style-test-owner")
                 (test-dir (string-append root "/t")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir test-dir)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append test-dir "/orders-test.ss")
                        ";;; -*- Gerbil -*-\n(import :std/test)\n(def (order-fixture order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "t/orders-test.ss")
              (check (hash-get (type-finding-details finding) 'scope)
                     => "source-or-test-owner"))))
    (test-case "typed-combinator-style policy requires exported helpers to use full typed doc blocks"
          (let* ((root ".run/policy-typed-combinator-style-exported-doc-missing")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Fixture keeps ordinary helper contracts short and exported API docs audited.\n(package: sample/orders)\n(export order-totals)\n;; : (-> Order Money)\n(def (order-total order) order)\n;; : (-> (List Order) (List Money))\n;; | type Money = Number\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedDocMissing) => #t)
              (check (hash-get details 'typedDocMissingCount) => 1)
              (check (hash-get details 'typedDocMissingTargets)
                     => ["order-totals"])
              (check (hash-get details 'expectedDocShape)
                     => "full form for exported helpers, macros, and policy-sensitive helpers: leading name matching the definition, ;;   : signature, optional ;;   | type/contract/requires/warning/rationale fields, and non-empty ;;   | doc m% block")
              (check (hash-get details 'typedDocRequiredWhen)
                     => "exported arity-bearing helper, macro, src/policy helper, or policy-sensitive helper"))))
    (test-case "typed-combinator-style policy accepts exported helpers with full typed doc blocks"
          (let* ((root ".run/policy-typed-combinator-style-exported-doc-present")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Fixture proves exported API helpers can satisfy full-form typed docs.\n(package: sample/orders)\n(export order-totals)\n;; : (-> Order Money)\n(def (order-total order) order)\n;; order-totals\n;;   : (-> (List Order) (List Money))\n;;   | type Money = Number\n;;   | doc m%\n;;       `order-totals orders` returns order totals for `orders`.\n;;     %\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))
    (test-case "typed-combinator-style policy rejects full typed doc blocks with mismatched leading names"
          (let* ((root ".run/policy-typed-combinator-style-exported-doc-name-mismatch")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Fixture proves full-form docs must name the attached definition.\n(package: sample/orders)\n(export order-totals)\n;; : (-> Order Money)\n(def (order-total order) order)\n;; wrong-order-totals\n;;   : (-> (List Order) (List Money))\n;;   | type Money = Number\n;;   | doc m%\n;;       `order-totals orders` returns order totals for `orders`.\n;;     %\n(def (order-totals orders) (map order-total orders))\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (hash-get details 'typedDocMissing) => #t)
              (check (hash-get details 'typedDocMissingTargets)
                     => ["order-totals"]))))
    (test-case "typed-combinator-style policy can be disabled by package config"
          (let* ((root ".run/policy-typed-combinator-style-disabled")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders\n  policy: ((agent-policy disabled-rules: (\"GERBIL-SCHEME-AGENT-R013\"))))\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (order-total order) order)\n")
            (let* ((index (collect-project root))
                   (findings (run-policy-checks index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))))
;; PolicyTest
(def agent-style-functional-policy-test
  (test-suite "gerbil scheme harness functional style policy"
    (test-case "agent policy warns on manual loops that should use functional idioms"
          (let* ((root ".run/policy-functional-idiom")
                 (_ (write-functional-idiom-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-severity finding) => "warning")
            (check (type-status matching) => "fail")
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-6")
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "redundant pure transform")))
                   => #t)
            (check (hash-get (type-finding-details finding) 'kind)
                   => "named-let")
            (check (hash-get (type-finding-details finding) 'namedLetPolicy)
                   => "warn-on-redundant-pure-transform-only")
            (check (hash-get (type-finding-details finding) 'detectionSignals)
                   => ["named-let"
                       "manual-loop-role"
                       "multi-binding-loop-state"
                       "no-functional-idiom-witness"
                       "no-reader-boundary"
                       "no-control-preservation-context"])
            (check (hash-get (type-finding-details finding) 'sequenceIdioms)
                   => ["map" "filter" "filter-map" "append-map" "fold/foldl/foldr" "for/fold"])
            (check (hash-get (type-finding-details finding) 'predicateIdioms)
                   => ["andmap/ormap" "every/any" "find/list-index"])
            (check (hash-get (type-finding-details finding) 'compositionIdioms)
                   => ["cut/cute" "curry/rcurry" "compose/compose1" "!>/!!>"])
            (check (hash-get (type-finding-details finding) 'nativeLambdaIdioms)
                   => ["fun" "lambda-match/λ-match" "λ" "case-lambda"])
            (check (hash-get (type-finding-details finding) 'typeclassIdioms)
                   => ["gerbil-poo/fun.ss Category." "Functor."
                       "ParametricFunctor." "Wrapper./Wrap."
                       "methods.table protocol slots"])
            (check (hash-get (type-finding-details finding) 'builderIdioms)
                   => ["with-list-builder"])
            (check (hash-get (type-finding-details finding) 'styleGuide)
                   => "typed-combinator-style")
            (check (hash-get (type-finding-details finding) 'styleCommand)
                   => "asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")
            (check (hash-get (type-finding-details finding) 'detectedControlContexts)
                   => [])
            (check (hash-get (type-finding-details finding) 'callerControlContexts)
                   => [])
            (check (hash-get (type-finding-details finding) 'keepNamedLetWhen)
                   => "IO/stateful control flow, C3-style fixpoint selection, or generator/continuation driver")
            (check (not (not (string-contains
                              (hash-get (type-finding-details finding)
                                        'learnedFrom)
                              ".data/gerbil-poo/fun.ss")))
                   => #t)
            (check (hash-get (type-finding-details finding) 'preserveNamedLetWhen)
                   => ["local recursion without accumulator boilerplate"
                       "reader or port EOF loops"
                       "stateful control flow"
                       "C3-style fixpoint selection"
                       "generator, coroutine, actor, or continuation driver"])))
    (test-case "agent policy preserves focused named-let recursion"
          (let* ((root ".run/policy-functional-idiom-focused-named-let")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append owner "/facade.ss")
                        ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export resolve)\n")
            (write-text (string-append owner "/core.ss")
                        ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export resolve)\n;; : (-> Node Node)\n(def (resolve node)\n  (let walk ((current node))\n    (if (node-final? current)\n      current\n      (walk (node-parent current)))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R009" findings)))
              (check matching => []))))
    (test-case "agent policy check output routes findings to guide code"
          (let* ((root ".run/policy-functional-idiom-check-output")
                 (_ (write-functional-idiom-project root)))
            (match (policy-check-output [root])
              ([exit-code . output]
               (check exit-code => 1)
            (check (not (not (string-contains
                              output
                              "|agent-repair-info status=active repairableFindings=3 repairableWarnings=3 repairableErrors=0 trigger=warning")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "|agent-repair rule=GERBIL-SCHEME-AGENT-R009 severity=warning repairable=true active=true trigger=warning")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "guideTopic=functional-data-transform")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "guideIntent=repair")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "nextCommand=asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "action=apply-policy-triggered-repair")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "guideCodeFlag=--code")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "nextCommand=asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "styleGuide=typed-combinator-style")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "styleCommand=asp gerbil-scheme guide --code --topic typed-combinator-style --intent style")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "qualityFacets=")))
                   => #t)
            (check (not (not (string-contains
                              output
                              "qualityFacetSteering=")))
                   => #t)))))
    (test-case "agent policy reports repeated match branch shape before style repair"
          (let* ((root ".run/policy-controlled-branch-shape")
                 (_ (write-controlled-branch-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-7")
            (check (hash-get (type-finding-details finding) 'styleGuide)
                   => "controlled-branch-shape")
            (check (hash-get (type-finding-details finding) 'rewriteScope)
                   => "same caller or extracted helper only")
            (check (hash-get (type-finding-details finding) 'qualityReference)
                   => "gerbil-utils")
            (check (hash-get (type-finding-details finding) 'functionShape)
                   => "source-backed Gerbil idioms first: lambda-match/lambda-ematch for unary match destructuring, fun for reusable local lambdas, cut/curry/rcurry for specialization, compose/rcompose/!>/!!> for pipelines")
            (check (hash-get (type-finding-details finding) 'expressionLevelRewrite)
                   => "turn repeated branch or dispatch shape into lambda-match/lambda-ematch, fun, cut/curry/rcurry, compose/rcompose/!>/!!>, fold/filter-map, generator combinator, or a named helper in that order of evidence")
            (check (hash-get (type-finding-details finding)
                             'sourceBackedRepairCandidates)
                   => ["lambda-match/lambda-ematch for unary match destructuring"
                       "fun for reusable local named lambda boundaries"
                       "cut/curry/rcurry for first-class argument specialization"
                       "compose/rcompose/!>/!!> for reusable expression pipelines"
                       "case-lambda only when there are real arity specializations"
                       "plain named helpers only when no higher-order Gerbil idiom fits"])
            (match (policy-check-output [root])
              ([exit-code . output]
               (check exit-code => 1)
               (check (not (not (string-contains output "guideTopic=controlled-branch-shape"))) => #t)
               (check (not (not (string-contains output "nextCommand=asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style"))) => #t)))))
    (test-case "agent policy reports nested conditional dispatch before launcher-style repair"
          (let* ((root ".run/policy-controlled-branch-conditional-dispatch")
                 (_ (write-controlled-branch-conditional-dispatch-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (hash-get (type-finding-details finding) 'shape)
                   => "nested-conditional-dispatch")
            (check (hash-get (type-finding-details finding) 'conditionalBranchCount)
                   => 4)
            (check (hash-get (type-finding-details finding) 'conditionalDispatchGate)
                   => 4)
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "source-backed Gerbil idioms such as fun, cut/curry/rcurry, compose/rcompose, or named fallback helpers")))
                   => #t)))
    (test-case "agent policy validates higher-order branch repair scenario under performance gate"
          (let* ((scenario
                  (make-policy-scenario
                   "controlled-branch-higher-order-performance"
                   "t/scenarios/policy/controlled-branch-higher-order-performance"))
                 (timing (policy-scenario-run/timed scenario))
                 (result (hash-get timing 'result))
                 (timings (hash-get timing 'timings))
                 (benchmark-contract
                  (hash-get timing 'benchmarkContract))
                 (max-total-ms (hash-get timing 'maxTotalMs))
                 (before-matching
                  (policy-scenario-findings
                   result
                   'before
                   "GERBIL-SCHEME-AGENT-R014"))
                 (after-matching
                  (policy-scenario-findings
                   result
                   'after
                   "GERBIL-SCHEME-AGENT-R014"))
                 (after-index (policy-scenario-index result 'after))
                 (after-file
                  (project-index-source-file-by-path
                   after-index
                   "src/orders/core.ss"))
                 (higher-order-roles
                  (source-file-higher-order-roles after-file)))
            (check (hash-get timing 'schemaId)
                   => "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
            (check (hash-get timing 'scenarioId)
                   => "controlled-branch-higher-order-performance")
            (check (length timings) => 4)
            (check (agent-style-policy-scenario-timing-steps-measured?
                    timings)
                   => #t)
            (check (hash-get benchmark-contract 'maxTotalMs) => 1000)
            (check (hash-get benchmark-contract 'feature)
                   => "typed-combinator-style")
            (check (hash-get benchmark-contract 'rule)
                   => "GERBIL-SCHEME-AGENT-R014")
            (check (hash-get benchmark-contract 'optimizationFocus)
                   => "higher-order branch repair")
            (check (hash-get timing 'benchmarkFeature)
                   => "typed-combinator-style")
            (check (hash-get timing 'benchmarkRule)
                   => "GERBIL-SCHEME-AGENT-R014")
            (check (hash-get timing 'optimizationFocus)
                   => "higher-order branch repair")
            (check max-total-ms => 1000)
            (check (hash-get timing 'performanceStatus) => "pass")
            (check (length before-matching) => 1)
            (check after-matching => [])
            (check (not (not (member "pattern-matching-function"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "named-lambda-abstraction"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "function-composition"
                                     higher-order-roles)))
                   => #t)
            (check (not (not (member "function-curry"
                                     higher-order-roles)))
                   => #t)))
    (test-case "agent policy reports match plus named-let selector shape before style repair"
          (let* ((root ".run/policy-controlled-branch-loop-shape")
                 (_ (write-controlled-branch-loop-shape-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R014" findings))
                 (finding (car matching)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-selector finding) => "src/orders/core.ss:5-12")
            (check (hash-get (type-finding-details finding) 'shape)
                   => "pattern-branch-with-manual-loop")
            (check (hash-get (type-finding-details finding) 'matchCount) => 1)
            (check (hash-get (type-finding-details finding) 'manualLoopCount) => 1)
            (check (not (not (string-contains
                              (type-finding-message finding)
                              "combines match state destructuring with a named-let loop")))
                   => #t)))))
;; PolicyTest
(def agent-style-predicate-policy-test
  (test-suite "gerbil scheme harness predicate style policy"
    (test-case "agent policy reports predicate family combinator repair"
          (let* ((root ".run/policy-predicate-family-combinator")
                 (_ (write-predicate-family-combinator-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R016" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-severity finding) => "warning")
            (check (hash-get details 'styleGuide) => "predicate-family-combinator")
            (check (hash-get details 'subject) => "fact")
            (check (hash-get details 'predicateCount) => 3)
            (check (hash-get (hash-get details 'qualityReference)
                             'referencePattern)
                   => "gerbil-utils-predicate-combinator")
            (check (not (not (member "gerbil-utils/base.ss#compose"
                                     (hash-get (hash-get details
                                                         'qualityReference)
                                               'referenceExamples))))
                   => #t)
            (check (not (not (member "role" (hash-get details 'fieldKeys)))) => #t)
            (check (not (not (member "hash-get" (hash-get details 'repeatedCallees)))) => #t)
            (check (hash-get repair 'active) => #t)
            (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style")))
    (test-case "agent policy keeps single-caller high-count field access advisory only"
          (let* ((root ".run/policy-field-access-single-caller-advisory")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (duration-summary row)\n  (+ (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R016" findings)))
              (check matching => []))))
    (test-case "agent policy reports combined field access selector repair"
          (let* ((root ".run/policy-field-access-selector-helper")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (duration-total row)\n  (+ (hash-get row 'durationMs)\n     (hash-get row 'durationMs)\n     (hash-get row 'durationMs)))\n(def (duration-max row)\n  (if (> (hash-get row 'durationMs) 0)\n    (hash-get row 'durationMs)\n    0))\n(def (duration-label row)\n  (string-append \"duration=\" (hash-get row 'durationMs)))\n(def (duration-warning? row)\n  (or (> (hash-get row 'durationMs) 100)\n      (< (hash-get row 'durationMs) 0)))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R016" findings))
                   (finding (car matching))
                   (details (type-finding-details finding))
                   (field-evidence (hash-get details 'fieldAccessPattern))
                   (repair (finding-agent-repair-json finding)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (type-finding-severity finding) => "warning")
              (check (hash-get details 'evidenceSource)
                     => "parser-owned fieldAccessPatternFacts")
              (check (hash-get details 'policySignals)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'detectionCombiner)
                     => "field-access-helper-all-of")
              (check [(hash-get details 'detectionPrototype)
                      (hash-get details 'detectionCombinerKind)]
                     => ["field-access-helper-all-of" "all-of"])
              (check (hash-get details 'detectionDescription)
                     => "field access helper repair requires high access count and cross-caller spread")
              (check (hash-get details 'detectionSourcePattern)
                     => "gerbil-utils-predicate-combinator")
              (check (not (not (member "gerbil-utils/base.ss#compose"
                                       (hash-get details 'detectionSourceOwners))))
                     => #t)
              (check (not (not (member "predicate-combinator"
                                       (hash-get details 'detectionQualitySignals))))
                     => #t)
              (check (hash-get details 'detectionWitness)
                     => "gerbil-utils study: compose/cut/curry helpers and generator map/fold are style witnesses for bounded predicate or selector helper repair")
              (check (hash-get details 'requiredGroups)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'evidenceGroups)
                     => ["high-field-access-count"
                         "cross-caller-field-access"])
              (check (hash-get details 'evidenceCounts) => [8 4])
              (check (hash-get field-evidence 'fieldKey) => "durationMs")
              (check (hash-get field-evidence 'accessCount) => 8)
              (check (length (hash-get field-evidence 'callers)) => 4)
              (check (hash-get details 'accessCountGate) => 8)
              (check (hash-get details 'callerCountGate) => 3)
              (check (hash-get repair 'active) => #t)
              (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
              (check (hash-get repair 'nextCommand)
                     => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style")))
    (test-case "agent policy reports emitter projection burst through multiple signals"
          (let* ((root ".run/policy-emitter-projection-burst")
                 (_ (write-projection-burst-project root))
                 (index (collect-project root))
                 (findings (run-agent-policy index))
                 (matching (filter-rule "GERBIL-SCHEME-AGENT-R016" findings))
                 (finding (car matching))
                 (details (type-finding-details finding))
                 (burst-evidence (hash-get details 'projectionBurst))
                 (repair (finding-agent-repair-json finding)))
            (check (length matching) => 1)
            (check (type-finding-path finding) => "src/orders/core.ss")
            (check (type-finding-severity finding) => "warning")
            (check (hash-get details 'evidenceSource)
                   => "parser-owned projectionBurstFacts")
            (check (hash-get details 'policySignals)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'detectionCombiner)
                   => "emitter-projection-burst-all-of")
            (check [(hash-get details 'detectionPrototype)
                    (hash-get details 'detectionCombinerKind)]
                   => ["emitter-projection-burst-all-of" "all-of"])
            (check (hash-get details 'detectionDescription)
                   => "emitter projection repair requires access density, field spread, and output boundary evidence")
            (check (hash-get details 'detectionSourcePattern)
                   => "gerbil-utils-projection-builder")
            (check (not (not (member "gerbil-utils/base.ss#compose"
                                     (hash-get details 'detectionSourceOwners))))
                   => #t)
            (check (not (not (member "list-builder-output-shape"
                                     (hash-get details 'detectionQualitySignals))))
                   => #t)
            (check (not (not (member "projection-builder"
                                     (hash-get details 'detectionProfilePrecedence))))
                   => #t)
            (check (hash-get details 'requiredGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceGroups)
                   => ["high-projection-access-count"
                       "multi-field-projection"
                       "emitter-output-boundary"])
            (check (hash-get details 'evidenceCounts) => [12 4 2])
            (check (hash-get burst-evidence 'caller) => "emit-order-line")
            (check (hash-get burst-evidence 'accessCount) => 12)
            (check (hash-get burst-evidence 'accessorCount) => 4)
            (check (hash-get burst-evidence 'emitterCount) => 2)
            (check (not (not (member "id"
                                     (hash-get burst-evidence 'fieldKeys))))
                   => #t)
            (check (hash-get repair 'active) => #t)
            (check (hash-get repair 'guideTopic) => "predicate-family-combinator")
            (check (hash-get repair 'nextCommand)
                   => "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style"))))))
;; PolicyTest
(def agent-style-policy-test
  (test-suite "gerbil scheme harness agent style policy"
    agent-style-typed-policy-test
    agent-style-comment-policy-test
    agent-style-functional-policy-test
    agent-style-predicate-policy-test))
