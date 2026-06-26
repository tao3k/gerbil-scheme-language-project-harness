((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for pair-tuple-projection-boundary; target keeps values/call-with-values repair visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 pair tuple projection scenario keeps cons-built Pair result protocols under the scenario-owned timing gate while preferring Gerbil values when the pair is not the domain interface")
 (feature . "pair-tuple-projection-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "cons-built Pair result protocol to values/call-with-values tuple projection")
 (inputShape . "one helper returns a Pair with cons and a public config helper immediately splits it with car/cdr")
 (expectedRepair . "producer returns multiple values and consumer destructures with call-with-values while preserving the public config API")
 (expectedReferencePattern . "pair-tuple-projection-boundary")
 (expectedReferenceExamples
  "gerbil-utils/base.ss#values/call-with-values"
  "gerbil://gerbil/core/match.ss#applicative-destructuring")
 (expectedQualitySignals
  "pair-tuple-projection-boundary"
  "anonymous-result-protocol"
  "values/call-with-values tuple projection"
  "temporary-binding-collapse")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject cons-built Pair tuple protocols when values/call-with-values exposes the producer and consumer boundary without inventing a domain pair")
 (scenarioQualityAxes
  "pair-tuple-projection-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "destructuring" "values" "tuple" "anti-scaffold"))
