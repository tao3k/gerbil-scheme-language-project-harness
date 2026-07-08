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
  "observed baseline 4ms for functional-idiom; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 functional idiom scenario keeps manual fold and local destructuring repair within the scenario-owned timing gate")
 (feature . "functional-idiom")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "manual recursion to fold/pipeline and lambda-match boundary")
 (inputShape
  .
  "single exported function uses named-let, cdr/car traversal, and an accumulator over a list")
 (expectedOutcome
  .
  "foldl total, !>/curry pipeline, and named lambda-match classifier with full typed documentation")
 (expectedReferencePattern . "loop-driver-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
  "gerbil-utils/list.ss#list-map"
  "gerbil-utils/base.ss#lambda-match")
 (expectedQualitySignals
  "list-combinator-boundary"
  "basic-syntax-scaffold"
  "gerbil-gambit-native-repair-contract"
  "manual-loop-drift"
  "pure-loop-driver-combinator-boundary"
  "fold-reducer-boundary"
  "cut-predicate-specialization"
  "map-fold-boundary"
  "lambda-match-destructuring")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject hand-written traversal and anonymous destructuring when fold, cut/curry pipeline, or lambda-match exposes the data flow")
 (scenarioQualityAxes
  "functional-idiom"
  "gerbil-gambit-native-idiom"
  "loop-driver-combinator-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style"
       "functional"
       "gerbil-idiom"
       "gambit-control"
       "fold"
       "pipeline"
       "lambda-match"
       "anti-scaffold"))
