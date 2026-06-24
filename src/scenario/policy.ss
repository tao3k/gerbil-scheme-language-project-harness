;;; -*- Gerbil -*-
;;; Policy scenario runner shared by tests and future agent-facing fixtures.

(import :gerbil/gambit
        :parser/facade
        :policy/facade
        (only-in :std/srfi/1 find)
        (only-in :std/sugar hash)
        :support/time
        :types/facade)

(export make-policy-scenario
        policy-scenario-id
        policy-scenario-root
        policy-scenario-input-root
        policy-scenario-expected-root
        policy-scenario-benchmark-contract
        policy-scenario-benchmark-max-total-ms
        policy-scenario-run
        policy-scenario-run/timed
        policy-scenario-run/checks
        policy-scenario-result-id
        policy-scenario-index
        policy-scenario-findings
        policy-scenario-required-finding
        policy-scenario-required-first-macro-fact
        policy-finding-rule?)

;;; Directory-backed policy scenarios follow the Codex-style fixture protocol:
;;; each scenario is a folder with an `input/` project tree and an `expected/`
;;; project tree. src owns execution and fact lookup; t owns only fixture data.
;; RelativePath
(def +policy-scenario-input-dir+ "input")
;; RelativePath
(def +policy-scenario-expected-dir+ "expected")
;; RelativePath
(def +policy-scenario-benchmark-file+ "benchmark.ss")

;; : (List BenchmarkContractKey)
(def +policy-scenario-benchmark-required-fields+
  '(maxTotalMs
    observedTotalMs
    targetTotalMs
    regressionBudgetMs
    observedTimings
    targetRationale))

;; : (-> Id ScenarioRoot PolicyScenario )
(def (make-policy-scenario id root)
  (list id root))

;; : (-> PolicyScenario String )
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; : (-> PolicyScenario String )
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; : (-> PolicyScenario String )
(def (policy-scenario-input-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-input-dir+))

;; : (-> PolicyScenario String )
(def (policy-scenario-expected-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-expected-dir+))

;; : (-> PolicyScenario Relpath )
(def (policy-scenario-benchmark-path scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-benchmark-file+))

;;; Fixture benchmark contract:
;;; - A scenario must carry benchmark.ss beside input/ and expected/.
;;; - The file is data, not code: an alist such as ((maxTotalMs . 1000)).
;;; - Feature metadata stays fixture-owned so later optimization passes can
;;;   group receipts by policy rule, input shape, and repair family.
;; : (-> PolicyScenario BenchmarkContract )
(def (policy-scenario-benchmark-contract scenario)
  (let ((path (policy-scenario-benchmark-path scenario)))
    (if (file-exists? path)
      (policy-scenario-benchmark-datum->contract
       (call-with-input-file path read))
      (error "policy scenario requires benchmark.ss"
             (policy-scenario-id scenario)
             path))))

;;; Contract normalization boundary:
;;; - Keep fixture syntax small and stable.
;;; - Timed runners receive hash data so tests and future JSON packets do not
;;;   depend on alist shape.
;;; - Baseline, target, and regression budget are required so performance
;;;   guidance exposes optimization headroom instead of only a loose timeout.
;; : (-> BenchmarkContractDatum BenchmarkContract )
(def (policy-scenario-benchmark-datum->contract datum)
  (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
        (schemaVersion "1")
        (maxTotalMs
         (policy-scenario-benchmark-required-value datum 'maxTotalMs))
        (observedTotalMs
         (policy-scenario-benchmark-required-value datum 'observedTotalMs))
        (targetTotalMs
         (policy-scenario-benchmark-required-value datum 'targetTotalMs))
        (regressionBudgetMs
         (policy-scenario-benchmark-required-value datum 'regressionBudgetMs))
        (observedTimings
         (policy-scenario-benchmark-required-value datum 'observedTimings))
        (targetRationale
         (policy-scenario-benchmark-required-value datum 'targetRationale))
        (iterations
         (policy-scenario-benchmark-value datum 'iterations 1))
        (unit
         (policy-scenario-benchmark-value datum 'unit "ms"))
        (purpose
         (policy-scenario-benchmark-value datum 'purpose "scenario timing"))
        (feature
         (policy-scenario-benchmark-value datum 'feature "policy-scenario"))
        (rule
         (policy-scenario-benchmark-value datum 'rule #f))
        (optimizationFocus
         (policy-scenario-benchmark-value datum 'optimizationFocus #f))
        (inputShape
         (policy-scenario-benchmark-value datum 'inputShape #f))
        (expectedRepair
         (policy-scenario-benchmark-value datum 'expectedRepair #f))
        (expectedReferencePattern
         (policy-scenario-benchmark-value datum 'expectedReferencePattern #f))
        (expectedReferenceExamples
         (policy-scenario-benchmark-value datum 'expectedReferenceExamples '()))
        (expectedQualitySignals
         (policy-scenario-benchmark-value datum 'expectedQualitySignals '()))
        (learnedStyleSources
         (policy-scenario-benchmark-value datum 'learnedStyleSources '()))
        (antiAiScaffoldIntent
         (policy-scenario-benchmark-value datum 'antiAiScaffoldIntent #f))
        (scenarioQualityAxes
         (policy-scenario-benchmark-value datum 'scenarioQualityAxes '()))
        (hotPathExemption
         (policy-scenario-benchmark-value datum 'hotPathExemption #f))
        (hotPathEvidence
         (policy-scenario-benchmark-value datum 'hotPathEvidence '()))
        (styleRewriteBoundary
         (policy-scenario-benchmark-value datum 'styleRewriteBoundary #f))
        (measurementPhases
         (policy-scenario-benchmark-value
          datum
          'measurementPhases
          '("collect-before" "collect-after" "policy-before" "policy-after")))
        (tags
         (policy-scenario-benchmark-value datum 'tags '()))))

;;; Required benchmark field lookup:
;;; - Missing baseline/target fields are contract errors, not optional legacy
;;;   defaults; otherwise new scenarios silently fall back to unhelpful gates.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue )
(def (policy-scenario-benchmark-required-value datum key)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry
      (cdr entry)
      (error "policy scenario benchmark missing required field" key))))

;;; Datum lookup boundary:
;;; - Missing benchmark fields fall back to contract defaults.
;;; - This keeps older scenarios readable while new fields become testable.
;; : (-> BenchmarkContractDatum BenchmarkContractKey BenchmarkContractValue BenchmarkContractValue )
(def (policy-scenario-benchmark-value datum key default)
  (let (entry (and (list? datum) (assoc key datum)))
    (if entry (cdr entry) default)))

;;; Performance gate boundary:
;;; - #f means the scenario records timing without enforcing a ceiling.
;;; - benchmark.ss remains the owner for configured time budgets.
;; : (-> BenchmarkContract (U Integer False) )
(def (policy-scenario-benchmark-max-total-ms contract)
  (hash-get contract 'maxTotalMs))

;;; Runner:
;;; - input/ is the failing project shape.
;;; - expected/ is the repaired project shape.
;;; - Callers can snapshot either findings or parser facts without duplicating
;;;   collect/run/filter boilerplate.
;; : (-> PolicyScenario PolicyScenarioResult )
(def (policy-scenario-run scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-agent-policy before-index)
          (run-agent-policy after-index))))

;;; Timed runner:
;;; - Tests use this when policy guidance is explicitly performance-motivated.
;;; - The result keeps the normal policy-scenario-run shape and adds a compact
;;;   timing receipt so regressions fail with measured phase evidence.
;; : (-> PolicyScenario TimedPolicyScenarioResult )
(def (policy-scenario-run/timed scenario)
  (let* ((before-index-step
          (policy-scenario-timed-step
           "collect-before"
           (lambda ()
             (collect-project (policy-scenario-input-root scenario)))))
         (before-index (car before-index-step))
         (before-index-timing (cdr before-index-step))
         (after-index-step
          (policy-scenario-timed-step
           "collect-after"
           (lambda ()
             (collect-project (policy-scenario-expected-root scenario)))))
         (after-index (car after-index-step))
         (after-index-timing (cdr after-index-step))
         (before-policy-step
          (policy-scenario-timed-step
           "policy-before"
           (lambda ()
             (run-agent-policy before-index))))
         (before-findings (car before-policy-step))
         (before-policy-timing (cdr before-policy-step))
         (after-policy-step
          (policy-scenario-timed-step
           "policy-after"
           (lambda ()
             (run-agent-policy after-index))))
         (after-findings (car after-policy-step))
         (after-policy-timing (cdr after-policy-step))
         (timings [before-index-timing
                   after-index-timing
                   before-policy-timing
                   after-policy-timing])
         (total-ms (policy-scenario-timings-total-ms timings))
         (benchmark-contract
          (policy-scenario-benchmark-contract scenario))
         (max-total-ms
          (policy-scenario-benchmark-max-total-ms benchmark-contract))
         (result
          (list (policy-scenario-id scenario)
                before-index
                after-index
                before-findings
                after-findings)))
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
          (schemaVersion "1")
          (scenarioId (policy-scenario-id scenario))
          (totalMs total-ms)
          (timings timings)
          (benchmarkContract benchmark-contract)
          (benchmarkFeature (hash-get benchmark-contract 'feature))
          (benchmarkRule (hash-get benchmark-contract 'rule))
          (optimizationFocus (hash-get benchmark-contract 'optimizationFocus))
          (hotPathExemption (hash-get benchmark-contract 'hotPathExemption))
          (hotPathEvidence (hash-get benchmark-contract 'hotPathEvidence))
          (styleRewriteBoundary (hash-get benchmark-contract 'styleRewriteBoundary))
          (maxTotalMs max-total-ms)
          (observedTotalMs (hash-get benchmark-contract 'observedTotalMs))
          (targetTotalMs (hash-get benchmark-contract 'targetTotalMs))
          (regressionBudgetMs (hash-get benchmark-contract 'regressionBudgetMs))
          (observedTimings (hash-get benchmark-contract 'observedTimings))
          (targetRationale (hash-get benchmark-contract 'targetRationale))
          (targetStatus
           (policy-scenario-performance-status
            total-ms
            (hash-get benchmark-contract 'targetTotalMs)))
          (performanceStatus
           (policy-scenario-performance-status total-ms max-total-ms))
          (result result))))

;;; Status boundary:
;;; - Unbounded scenarios still return timing receipts.
;;; - Bounded scenarios pass when measured time does not exceed the configured
;;;   value, and fail with both measured and configured values otherwise.
;; : (-> Milliseconds (U Milliseconds False) String )
(def (policy-scenario-performance-status total-ms max-total-ms)
  (cond
   ((not max-total-ms) "unbounded")
   ((<= total-ms max-total-ms) "pass")
   (else
    (string-append
     "fail durationMs="
     (number->string total-ms)
     " maxMs="
     (number->string max-total-ms)))))

;;; Step timing boundary:
;;; - Each phase returns its value and a compact duration receipt.
;;; - Callers decide phase order; this helper only measures one thunk.
;; : (-> String Thunk Pair )
(def (policy-scenario-timed-step name thunk)
  (let (start (monotonic-ms))
    (let (value (thunk))
      (cons value
            (hash (name name)
                  (durationMs (duration-ms start (monotonic-ms))))))))

;;; Total timing boundary:
;;; - Sum phase receipts without re-running scenario work.
;;; - Empty timing lists stay valid for degenerate fixtures.
;; : (-> (List Timing) Integer )
(def (policy-scenario-timings-total-ms timings)
  (if (null? timings)
    0
    (+ (hash-get (car timings) 'durationMs)
       (policy-scenario-timings-total-ms (cdr timings)))))

;;; Full policy runner:
;;; - Use this when a scenario validates user-facing package policy controls.
;;; - run-policy-checks applies gerbil.pkg rule filters; run-agent-policy does not.
;; : (-> PolicyScenario PolicyScenarioResult )
(def (policy-scenario-run/checks scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-policy-checks before-index)
          (run-policy-checks after-index))))

;;; Result tuple boundary:
;;; - Scenario result slots stay positional for lightweight fixtures.
;;; - Accessors keep tests from depending on raw list indexes.
;; : (-> PolicyScenarioResult String )
(def (policy-scenario-result-id result)
  (list-ref result 0))

;;; Phase index boundary:
;;; - Only before/after are valid parser fact phases.
;;; - Unknown phases fail early instead of returning a misleading index.
;; : (-> PolicyScenarioResult Phase ProjectIndex )
(def (policy-scenario-index result phase)
  (case phase
    ((before) (list-ref result 1))
    ((after) (list-ref result 2))
    (else (error "unknown policy scenario phase" phase))))

;;; Finding query boundary:
;;; - Scenario phases are explicit so tests cannot mix before/after policy state.
;;; - Rule filtering stays here instead of duplicated across snapshot tests.
;; : (-> PolicyScenarioResult ScenarioPhase RuleId (List TypeFinding) )
(def (policy-scenario-findings result phase rule-id)
  (filter (lambda (finding)
            (policy-finding-rule? finding rule-id))
          (case phase
            ((before) (list-ref result 3))
            ((after) (list-ref result 4))
            (else (error "unknown policy scenario phase" phase)))))

;;; Required finding boundary:
;;; - Missing evidence is a scenario failure, not an empty test assertion.
;;; - The returned finding remains the real policy object for detail checks.
;; : (-> PolicyScenarioResult ScenarioPhase RuleId TypeFinding )
(def (policy-scenario-required-finding result phase rule-id)
  (or (find (lambda (finding)
              (policy-finding-rule? finding rule-id))
            (policy-scenario-findings result phase rule-id))
      (error "missing policy scenario finding" phase rule-id)))

;;; Rule predicate boundary:
;;; - Keep rule-id matching in one helper so scenario queries stay uniform.
;;; - The predicate compares public finding rule ids only.
;; : (-> TypeFinding RuleId Boolean )
(def (policy-finding-rule? finding rule-id)
  (equal? (type-finding-rule-id finding) rule-id))

;;; Macro witness boundary:
;;; - Macro facts are collected from the selected project phase.
;;; - The helper fails loudly when a scenario stops exercising macro evidence.
;; : (-> PolicyScenarioResult ScenarioPhase MacroFact )
(def (policy-scenario-required-first-macro-fact result phase)
  (let (macros
        (apply append
               (map source-file-macros
                    (project-index-files
                     (policy-scenario-index result phase)))))
    (if (pair? macros)
      (car macros)
      (error "missing policy scenario macro fact" phase))))
