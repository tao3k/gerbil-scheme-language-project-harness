((schemaId . "agent.semantic-protocols.gerbil-scheme-policy-scenario-benchmark")
 (schemaVersion . "2")
 (feature . "phase-aware-helper-split")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (purpose . "R013 separates public macro syntax, phase-owned parsing, and runtime POO construction")
 (inputShape . "one macro owner embeds a large begin-syntax parser and wildcard re-exports runtime helpers")
 (expectedOutcome . "thin public macro imports a compiled parser with for-syntax and exports only the macro")
 (optimizationFocus . "mixed syntax/runtime owner to explicit phase-adjusted helper module")
 (antiAiScaffoldIntent . "prevent generated macro modules from mixing parser state with runtime API ownership")
 (expectedReferencePattern . "phase-aware-helper-split")
 (expectedReferenceExamples
  "gerbil://gerbil/expander/module.ss#for-syntax"
  "gerbil://gerbil/expander/top.ss#begin-syntax-phi-plus-one")
 (learnedStyleSources
  "gerbil://gerbil/expander/module.ss"
  "gerbil://gerbil/expander/top.ss"
  "harness-self-apply")
 (expectedQualitySignals
  "phase-aware-helper-split"
  "phase-aware-macro-boundary"
  "generated-runtime-helper"
  "source-aware-syntax-error")
 (scenarioQualityAxes
  "phase-aware-helper-split"
  "phase-adjusted-import"
  "public-syntax-owner"
  "runtime-helper-owner")
 (tags "style" "macro" "phase" "module" "for-syntax")
 (targetRationale . "phase ownership is a structural macro fact and must remain inside the R013 millisecond gate")
 (unit . "ms")
 (iterations . 1)
 (target_total . 18ms)
 (regression_budget . 26ms)
 (expected_over_input_budget . 26ms)
 (expected_over_input_note . #f)
 (max_total . 30ms)
 (observed_total . 5ms)
 (maxCollectMs . 15)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 10)
 (observedCollectMs . 0)
 (observedParseMs . 0)
 (observedFileMs . 0)
 (observedPhaseMs . 0)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (measurementPhases
  "collect-before" "collect-after" "policy-before" "policy-after"
  "assert-time-gate" "assert-memory-gate")
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (maxRssMb . 512)
 (hotPathEvidence)
 (hotPathExemption . #f)
 (nativePooPrimary . #f)
 (adapterBoundary . #f)
 (styleRewriteBoundary . #f))
