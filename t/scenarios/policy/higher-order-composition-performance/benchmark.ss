((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 4ms for higher-order-composition-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 higher-order composition scenario keeps wrapper-lambda repair within the scenario-owned timing gate")
 (feature . "higher-order-composition")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "wrapper lambda to composition boundary")
 (inputShape . "repeated wrapper lambdas around a reusable string transform")
 (expectedRepair . "compose/cut pipeline with full typed documentation")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#left-to-right"
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate")
 (expectedQualitySignals
  "function-pipeline-abstraction"
  "cut-prefix-predicate"
  "thin-wrapper-elimination")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject repeated wrapper-lambda scaffolding when compose/cut expresses the data flow")
 (scenarioQualityAxes "higher-order-composition" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "higher-order" "composition"))
