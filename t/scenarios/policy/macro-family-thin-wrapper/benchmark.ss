((maxTotalMs . 25)
 (observedTotalMs . 4)
 (targetTotalMs . 15)
 (regressionBudgetMs . 21)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for macro-family-thin-wrapper; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 macro-family scenario catches repeated same-prefix thin macro wrappers")
 (feature . "macro-family-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "collapse repeated same-prefix macro wrappers into one hygienic family helper")
 (inputShape
  .
  "poo-flow-shaped defrules wrappers repeated across the same macro prefix")
 (expectedRepair
  .
  "one macro family helper with typed documentation and runtime semantics left in ordinary helpers")
 (expectedReferencePattern . "gerbil://macro-family-thin-wrapper")
 (expectedReferenceExamples
  "gerbil://syntax-rules-family"
  "gerbil-utils"
  "poo-flow")
 (expectedQualitySignals
  "macro-family-boundary"
  "controlled-macro-syntax-boundary"
  "anti-ai-scaffold")
 (learnedStyleSources "gerbil://" "gerbil-utils" "poo-flow")
 (antiAiScaffoldIntent
  .
  "use poo-flow as an experiment fixture while keeping the policy signal generic and parser-owned")
 (scenarioQualityAxes "macro-family-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro-family" "poo-flow-shape"))
