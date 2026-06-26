((maxTotalMs . 25)
 (observedTotalMs . 7)
 (targetTotalMs . 15)
 (regressionBudgetMs . 18)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 7ms for list-combinator-boundary; target keeps optimization visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 6)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 list combinator scenario keeps anti-scaffold traversal repair within the scenario-owned timing gate")
 (feature . "list-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "manual list recursion to expression-level traversal boundary")
 (inputShape
  .
  "single exported function uses named-let, reverse accumulator, and inline selection/projection over a list")
 (expectedRepair
  .
  "local selector plus filter-map traversal with full typed documentation")
 (expectedReferencePattern . "list-combinator-boundary")
 (expectedReferenceExamples
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/list.ss#list<-monoid"
  "gerbil-utils/list.ss#with-deduplicated-list-builder"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "list-combinator-boundary"
  "map-fold-boundary"
  "filter-map-selection-projection"
  "lambda-match-list-destructuring"
  "list-builder-output-shape")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written list traversal scaffolding when a mapper, selector, reducer, filter-map, fold, or builder boundary expresses the data flow")
 (scenarioQualityAxes "list-combinator-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "list" "combinator" "anti-scaffold"))
