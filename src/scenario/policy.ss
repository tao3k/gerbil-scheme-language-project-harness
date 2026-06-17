;;; -*- Gerbil -*-
;;; Policy scenario runner shared by tests and future agent-facing fixtures.

(import :parser/facade
        :policy/facade
        (only-in :std/srfi/1 find)
        :types/facade)

(export make-policy-scenario
        policy-scenario-id
        policy-scenario-root
        policy-scenario-input-root
        policy-scenario-expected-root
        policy-scenario-run
        policy-scenario-result-id
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

;; PolicyScenario <- Id ScenarioRoot
(def (make-policy-scenario id root)
  (list id root))

;; String <- PolicyScenario
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; String <- PolicyScenario
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; String <- PolicyScenario
(def (policy-scenario-input-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-input-dir+))

;; String <- PolicyScenario
(def (policy-scenario-expected-root scenario)
  (string-append (policy-scenario-root scenario)
                 "/"
                 +policy-scenario-expected-dir+))

;;; Runner:
;;; - input/ is the failing project shape.
;;; - expected/ is the repaired project shape.
;;; - Callers can snapshot either findings or parser facts without duplicating
;;;   collect/run/filter boilerplate.
;; PolicyScenarioResult <- PolicyScenario
(def (policy-scenario-run scenario)
  (let* ((before-index (collect-project (policy-scenario-input-root scenario)))
         (after-index (collect-project (policy-scenario-expected-root scenario))))
    (list (policy-scenario-id scenario)
          before-index
          after-index
          (run-agent-policy before-index)
          (run-agent-policy after-index))))

;; String <- PolicyScenarioResult
(def (policy-scenario-result-id result)
  (list-ref result 0))

;; ProjectIndex <- PolicyScenarioResult Phase
(def (policy-scenario-index result phase)
  (case phase
    ((before) (list-ref result 1))
    ((after) (list-ref result 2))
    (else (error "unknown policy scenario phase" phase))))

;;; Finding query boundary:
;;; - Scenario phases are explicit so tests cannot mix before/after policy state.
;;; - Rule filtering stays here instead of duplicated across snapshot tests.
;; (List TypeFinding) <- PolicyScenarioResult ScenarioPhase RuleId
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
;; TypeFinding <- PolicyScenarioResult ScenarioPhase RuleId
(def (policy-scenario-required-finding result phase rule-id)
  (or (find (lambda (finding)
              (policy-finding-rule? finding rule-id))
            (policy-scenario-findings result phase rule-id))
      (error "missing policy scenario finding" phase rule-id)))

;; Boolean <- TypeFinding RuleId
(def (policy-finding-rule? finding rule-id)
  (equal? (type-finding-rule-id finding) rule-id))

;;; Macro witness boundary:
;;; - Macro facts are collected from the selected project phase.
;;; - The helper fails loudly when a scenario stops exercising macro evidence.
;; MacroFact <- PolicyScenarioResult ScenarioPhase
(def (policy-scenario-required-first-macro-fact result phase)
  (let (macros
        (apply append
               (map source-file-macros
                    (project-index-files
                     (policy-scenario-index result phase)))))
    (if (pair? macros)
      (car macros)
      (error "missing policy scenario macro fact" phase))))
