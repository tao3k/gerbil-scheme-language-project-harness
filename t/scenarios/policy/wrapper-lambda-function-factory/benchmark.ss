((max_total . 25ms)
 (observed_total . 7ms)
 (target_total . 15ms)
 (regression_budget . 18ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 7ms for wrapper-lambda-function-factory; target keeps wrapper drift repair visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 6)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 wrapper lambda scenario keeps function-factory repair within the scenario-owned timing gate")
 (feature . "wrapper-lambda-function-factory")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "repeated wrapper lambdas to named specializer and factory boundaries")
 (inputShape
  .
  "single exported function allocates repeated same-formal lambdas inside one let before returning another wrapper")
 (expectedRepair
  .
  "prefix/suffix specializers plus a named normalization helper, preserving the public function factory")
 (expectedReferencePattern . "gerbil-utils-higher-order-expression")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#lambda-match/lambda-ematch"
  "gerbil-utils/base.ss#fun"
  "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
  "gerbil-utils/base.ss#cut/curry/rcurry"
  "gerbil-utils/base.ss#case-lambda specializers")
 (expectedQualitySignals
  "function-specialization-abstraction"
  "function-pipeline-abstraction"
  "thin-wrapper-elimination"
  "multi-arity-abstraction")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject repeated anonymous wrapper lambdas when a named function factory, specializer, or pipeline boundary exposes the data flow")
 (scenarioQualityAxes
  "wrapper-lambda-drift"
  "function-specialization-opportunity"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "higher-order" "function-factory" "anti-scaffold"))
