;;; -*- Gerbil -*-
;;; Policy scenario runner shared by tests and future agent-facing fixtures.

(import :parser/facade
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
         (result
          (list (policy-scenario-id scenario)
                before-index
                after-index
                before-findings
                after-findings)))
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-policy-scenario-timing")
          (schemaVersion "1")
          (scenarioId (policy-scenario-id scenario))
          (totalMs (policy-scenario-timings-total-ms timings))
          (timings timings)
          (result result))))

;; : (-> String Thunk Pair )
(def (policy-scenario-timed-step name thunk)
  (let (start (monotonic-ms))
    (let (value (thunk))
      (cons value
            (hash (name name)
                  (durationMs (duration-ms start (monotonic-ms))))))))

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

;; : (-> PolicyScenarioResult String )
(def (policy-scenario-result-id result)
  (list-ref result 0))

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
