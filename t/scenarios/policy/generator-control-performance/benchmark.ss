((maxTotalMs . 25)
 (observedTotalMs . 6)
 (targetTotalMs . 15)
 (regressionBudgetMs . 19)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 6ms for generator-control-performance; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 generator control scenario keeps learned generator-boundary repair within the scenario-owned timing gate")
 (feature . "generator-control")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "push/pull generator control inversion boundary")
 (inputShape . "manual pull generator loop behind a Generating contract")
 (expectedRepair
  .
  "local generator reducer boundary with full typed documentation")
 (expectedReferencePattern . "gerbil-utils-generator-control")
 (expectedReferenceExamples
  "gerbil-utils/generator.ss#generating<-for-each"
  "gerbil-utils/generator.ss#yield-continuation-boundary")
 (expectedQualitySignals
  "push-pull-control-inversion"
  "call/cc-yield-boundary")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written producer-loop scaffolding when generator contracts prove a combinator boundary")
 (scenarioQualityAxes "generator-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "generator" "control-inversion"))
