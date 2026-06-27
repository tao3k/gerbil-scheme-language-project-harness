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
  "observed gerbil-inline-rule-call-shape receipt is 4ms total; target keeps builtin inline-rule call-shape policy in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 8)
 (maxParseMs . 12)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 routes hot primitive call drift toward Gerbil builtin inline-rule and dispatch-lambda shapes")
 (feature . "gerbil-inline-rule-call-shape")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "compiler-recognizable inline primitive call shape")
 (inputShape
  .
  "hot code hides primitive operations behind dynamic tables and apply, preventing Gerbil builtin inline rules from seeing the call shape")
 (expectedRepair
  .
  "keep the hot primitive call target lexical and direct, using fixnum primitives when the value boundary is already known")
 (expectedReferencePattern . "gerbil-builtin-inline-rule-call-shape")
 (expectedReferenceExamples
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#ast-rules"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "lexical-primitive-call"
  "direct-call-shape"
  "fixnum-boundary"
  "no-dynamic-apply")
 (learnedStyleSources
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss"
  "gerbil://gerbil/compiler/optimize-top.ss")
 (antiAiScaffoldIntent
  .
  "reject generated primitive dispatch tables that hide hot arithmetic and predicates from compiler-recognizable inline rules")
 (scenarioQualityAxes
  "builtin-inline-rule-shape"
  "dispatch-lambda-form"
  "fixnum-hot-path"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "compiler" "optimizer" "inline-rule" "fixnum"))
