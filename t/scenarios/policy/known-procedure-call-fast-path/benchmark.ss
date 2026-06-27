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
  "observed known-procedure-call-fast-path receipt is 4ms total; target keeps type-resolved call optimization policy in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 8)
 (maxParseMs . 12)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 routes hot call-site drift toward Gerbil optimizer-style known-procedure fast paths")
 (feature . "known-procedure-call-fast-path")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "type-resolved procedure calls and source-preserving unchecked call lowering")
 (inputShape
  .
  "hot code repeatedly calls a known procedure through generic wrappers or dynamic dispatch after the callable boundary is already known")
 (expectedRepair
  .
  "make the callable boundary explicit, preserve the checked public edge, and keep the hot internal path eligible for known-procedure lowering")
 (expectedReferencePattern . "gerbil-optimizer-known-call-fast-path")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call"
  "gerbil://gerbil/compiler/optimize-call.ss#optimize-call%"
  "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked")
 (expectedQualitySignals
  "known-call-boundary"
  "checked-public-edge"
  "unchecked-internal-fast-path"
  "source-preserving-transform")
 (learnedStyleSources
  "gerbil://gerbil/compiler/optimize-call.ss"
  "gerbil://gerbil/compiler/method.ss")
 (antiAiScaffoldIntent
  .
  "reject generated wrapper stacks that hide known procedure boundaries and force every hot call through generic runtime dispatch")
 (scenarioQualityAxes
  "known-procedure-call-fast-path"
  "checked-vs-unchecked-boundary"
  "gerbil-optimizer-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "compiler" "optimizer" "call-fast-path" "unchecked-call"))
