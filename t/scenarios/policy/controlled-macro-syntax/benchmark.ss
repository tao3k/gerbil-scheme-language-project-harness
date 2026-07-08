((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 3ms for scoped controlled-macro-syntax; target keeps the hot macro-policy scenario in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 15)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 10)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 controlled macro syntax scenario keeps macro guidance within the scenario-owned timing gate")
 (feature . "macro-hygiene")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "scoped expander state and controlled macro syntax boundary")
 (inputShape
  .
  "macro transformer with global mutable phase/context state, datum dispatcher, no source-aware syntax error, and no expansion documentation")
 (expectedOutcome
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
