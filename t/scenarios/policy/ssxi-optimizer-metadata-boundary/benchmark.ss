((max_total . 25ms)
 (observed_total . 6ms)
 (target_total . 15ms)
 (regression_budget . 19ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed ssxi-optimizer-metadata-boundary receipt is 6ms total; target keeps optimizer metadata checks in the small millisecond budget while max_total remains the hard regression ceiling")
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
 (purpose . "R013 keeps SSXI optimizer metadata adjacent to compiler-visible primitive call shape")
 (feature . "ssxi-optimizer-metadata-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "SSXI metadata and inline-rule visibility for direct primitive calls")
 (inputShape
  .
  "one helper mixes SSXI, inline rule, optimizer metadata, primitive dispatch, and dynamic apply")
 (expectedRepair
  .
  "name the optimizer boundary and keep the primitive call lexical and direct instead of routing through a dynamic table")
 (expectedReferencePattern . "gerbil-ssxi-optimizer-metadata-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/ssxi.ss#declare-inline-rule!"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss#declare-inline-rules!"
  "gerbil://gerbil/compiler/optimize-call.ss#call-unchecked"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "ssxi-metadata-boundary"
  "declare-inline-rule-boundary"
  "lexical-primitive-call"
  "direct-call-shape"
  "unchecked-call-visibility")
 (learnedStyleSources
  "gerbil://gerbil/compiler/ssxi.ss"
  "gerbil://gerbil/builtin-inline-rules.ssxi.ss"
  "gerbil://gerbil/compiler/optimize-call.ss")
 (antiAiScaffoldIntent
  .
  "reject dynamic primitive tables that hide compiler-known call shapes from SSXI inline metadata")
 (scenarioQualityAxes
  "ssxi-optimizer-metadata-boundary"
  "direct-call-shape"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "ssxi" "optimizer" "inline" "direct-call"))
