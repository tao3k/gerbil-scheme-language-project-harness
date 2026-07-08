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
  "observed phase-aware-macro-boundary receipt is 6ms total; target keeps phase-aware macro contract checks in the small millisecond budget while max_total remains the hard regression ceiling")
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
 (purpose . "R013 separates Gerbil meta-syntactic tower, phase/context parsing, expansion, and runtime helper responsibilities")
 (feature . "phase-aware-macro-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "phase/context macro parsing split from runtime helper generation")
 (inputShape
  .
  "one macro owner mixes Phase, Macro, Context, Transformer, Expansion, and Runtime helper responsibilities")
 (expectedOutcome
  .
  "keep the syntax wrapper thin, document the expansion contract, and move reusable behavior into ordinary runtime helpers")
 (expectedReferencePattern . "gerbil-phase-aware-macro-boundary")
 (expectedReferenceExamples
  "gerbil://README.md#meta-syntactic-tower"
  "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one"
  "gerbil://gerbil/expander/core.ss#core-context-shift"
  "gerbil://gerbil/expander/module.ss#core-expand-module-begin")
 (expectedQualitySignals
  "meta-syntactic-tower-boundary"
  "phase-aware-macro-boundary"
  "phase-shift-context-boundary"
  "hygienic-transformer-boundary"
  "runtime-helper-boundary")
 (learnedStyleSources
  "gerbil://README.md"
  "gerbil://gerbil/expander/top.ss"
  "gerbil://gerbil/expander/core.ss")
 (antiAiScaffoldIntent
  .
  "reject one-owner macro DSL scaffolding that mixes phase/context parsing, expansion, and runtime behavior")
 (scenarioQualityAxes
  "meta-syntactic-tower"
  "phase-aware-macro-boundary"
  "controlled-macro-syntax")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "macro" "phase" "meta-syntactic-tower"))
