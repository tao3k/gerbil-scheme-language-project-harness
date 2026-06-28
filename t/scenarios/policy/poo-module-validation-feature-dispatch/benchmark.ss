((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed poo-module-validation-feature-dispatch receipt is 4ms total; target keeps POO validation policy in the small millisecond budget while max_total remains the hard regression ceiling")
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
 (purpose . "R013 routes POO module validation drift toward compiler-style feature dispatch and local cache handlers")
 (feature . "poo-module-validation-feature-dispatch")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "resolved-field and cache receipt drift to compiler-style feature dispatch")
 (inputShape
  .
  "POO module validation repeats resolved-field traversal, harness field extraction, and cache receipt construction across object and field validators")
 (expectedRepair
  .
  "extract feature-specific validation handlers and keep the validation surface as a dispatch table with shared cache key construction")
 (expectedReferencePattern . "gerbil-compiler-feature-dispatch")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/compile.ss#defcompile-method"
  "gerbil://gerbil/compiler/compile.ss#apply-lift-modules"
  "gerbil://gerbil/compiler/compile.ss#generate-meta-module")
 (expectedDownstreamOwners
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-object-harness-validation"
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-field-contract-validation-cache-receipt"
  "poo-flow://src/module-system/object-validation-support/harness.ss#poo-flow-module-validation-hash-fields")
 (expectedQualitySignals
  "feature-dispatch-surface"
  "shared-cache-key-boundary"
  "resolved-field-single-pass"
  "provider-independent-source-query")
 (learnedStyleSources
  "gerbil://gerbil/compiler/compile.ss"
  "poo-flow://src/module-system/object-validation-support/harness.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject agent-generated validation scaffolding that clones resolved-field and cache logic instead of extracting local feature handlers")
 (scenarioQualityAxes
  "compiler-feature-dispatch"
  "poo-validation-cache-boundary"
  "resolved-field-single-pass"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "compiler" "poo" "validation" "feature-dispatch" "cache"))
