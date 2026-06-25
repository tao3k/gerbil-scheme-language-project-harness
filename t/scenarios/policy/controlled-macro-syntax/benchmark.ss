((maxTotalMs . 100)
 (observedTotalMs . 15)
 (targetTotalMs . 50)
 (regressionBudgetMs . 85)
 (observedTimings
  ((name . collect-before) (durationMs . 5))
  ((name . collect-after) (durationMs . 5))
  ((name . policy-before) (durationMs . 3))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "observed baseline 15ms for scoped controlled-macro-syntax; target leaves room for runner variance while maxTotalMs keeps the scenario under a millisecond-scale hard ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 controlled macro syntax scenario keeps macro guidance within the scenario-owned timing gate")
 (feature . "macro-hygiene")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "scoped expander state and controlled macro syntax boundary")
 (inputShape
  .
  "macro transformer with global mutable phase/context state, datum dispatcher, no source-aware syntax error, and no expansion documentation")
 (expectedRepair
  .
  "thin hygienic syntax-case/with-syntax transformer with typed expansion context, parameterized macro state, source-aware syntax errors, and full typed documentation")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject generated macro scaffolding that hides hygiene and phase/context state behind global mutation or verbose dispatcher code")
 (scenarioQualityAxes
  "macro-hygiene-boundary"
  "scoped-expander-state-boundary"
  "source-aware-syntax-error"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "hygiene"))
