((max_total . 25ms)
 (observed_total . 6.5ms)
 (target_total . 15.5ms)
 (regression_budget . 18.5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2.25))
  ((name . collect-after) (durationMs . 2.75))
  ((name . policy-before) (durationMs . 1.0))
  ((name . policy-after) (durationMs . 0.5)))
 (targetRationale
  .
  "typed-combinator-style keeps the baseline under a subsecond millisecond budget while preserving fractional observed timing support")
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
 (purpose . "R013 typed-combinator-style scenario keeps core Gerbil expression idiom repair under the scenario timing gate")
 (feature . "typed-combinator-style")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "manual traversal and missing expression evidence to Gerbil-native combinator style")
 (inputShape . "small owner exposes hand-written named-let traversal and no adjacent typed-combinator contracts")
 (expectedRepair . "typed docs, lambda-match shape dispatch, curry/rcurry, compose, and map traversal")
 (expectedReferencePattern . "gerbil-upstream-idiom-performance")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#match/match*"
  "gerbil://gerbil/core/match.ss#with/with*"
  "gerbil://gerbil/compiler/optimize-spec.ss#cut-compile-e"
  "gerbil-utils/base.ss#lambda-match"
  "gerbil-utils/base.ss#compose/rcompose")
 (expectedQualitySignals
  "gerbil-upstream-idiom-boundary"
  "lambda-match-destructuring"
  "cut-helper-plumbing"
  "map-fold-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject missing typed contracts and hand-written traversal when Gerbil-native match, cut, compose, or map boundaries express the behavior")
 (scenarioQualityAxes
  "typed-combinator-style"
  "gerbil-upstream-idiom-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "typed-combinator" "gerbil-upstream" "subsecond"))
