((max_total . 25ms)
 (observed_total . 6ms)
 (target_total . 15ms)
 (regression_budget . 19ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 6ms for case-lambda-function-factory; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 case-lambda function factory scenario keeps arity-specialized repair within the scenario-owned timing gate")
 (feature . "case-lambda-function-factory")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "case-lambda arity-specialized function factory")
 (inputShape . "single wrapper-lambda factory hiding distinct arity variants")
 (expectedRepair
  .
  "case-lambda factory with explicit arity branches and typed documentation")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples "gerbil-utils/base.ss#case-lambda specializers")
 (expectedQualitySignals
  "function-specialization-abstraction"
  "multi-arity-abstraction"
  "thin-wrapper-elimination")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject one-size wrapper-lambda factories when case-lambda expresses real arity variants")
 (scenarioQualityAxes "case-lambda-function-factory" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "higher-order" "case-lambda" "arity"))
