((max_total . 20ms)
 (observed_total . 4ms)
 (target_total . 12ms)
 (regression_budget . 16ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed gambit-fixnum-flonum-arithmetic-boundary receipt is 4ms total; target keeps numeric primitive policy in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 8)
 (maxParseMs . 12)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 teaches agents to use Gambit numeric primitive families only behind explicit type/range boundaries")
 (feature . "gambit-fixnum-flonum-arithmetic-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "fixnum/flonum primitive arithmetic with checked boundary tests")
 (inputShape
  .
  "hot numeric loops use generic arithmetic even when values are already constrained to fixnum or flonum domains")
 (expectedRepair
  .
  "surface the numeric domain contract, use fx/fl primitive families in the hot lane, and keep overflow/type behavior covered by tests")
 (expectedReferencePattern . "gambit-numeric-primitive-domain-boundary")
 (expectedReferenceExamples
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fx+"
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm#fixnum-overflow-exception"
  "gambit://tests/unit-tests/02-flonum/fladd.scm#fl+")
 (expectedQualitySignals
  "numeric-domain-contract"
  "fixnum-overflow-covered"
  "flonum-type-covered"
  "hot-loop-primitive-family")
 (learnedStyleSources
  "gambit://tests/unit-tests/01-fixnum/fxadd.scm"
  "gambit://tests/unit-tests/02-flonum/fladd.scm")
 (antiAiScaffoldIntent
  .
  "reject generated hot numeric loops that default to generic arithmetic while omitting the fixnum/flonum domain and failure-mode tests")
 (scenarioQualityAxes
  "gambit-numeric-primitives"
  "typed-hot-loop-boundary"
  "overflow-and-type-tests"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gambit-native" "numeric" "fixnum" "flonum" "hot-loop"))
