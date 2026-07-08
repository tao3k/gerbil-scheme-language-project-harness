((max_total . 29ms)
 (observed_total . 9ms)
 (target_total . 16ms)
 (regression_budget . 20ms)
 (expected_over_input_budget . 0ns)
 (observedTimings
  ((name . collect-before) (durationMs . 4) (durationNs . 4000000))
  ((name . collect-after) (durationMs . 3) (durationNs . 3000000))
  ((name . policy-before) (durationMs . 1) (durationNs . 1000000))
  ((name . policy-after) (durationMs . 0) (durationNs . 0)))
 (targetRationale
  .
  "source-form-reader-boundary keeps reader collection detection parser-owned while preserving the low-level reader helper; multi-sample timing avoids single GC/allocator spikes while preserving the hard 28ms gate")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 16)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 5)
 (unit . "ms")
 (purpose . "R013 source/form reader scenario rejects mixed reader, accumulator, and projection loops while preserving the reader boundary helper")
 (feature . "source-form-reader-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "inline source reader and mixed selection loops to read-forms port helper, source-forms file boundary, and filter-map projection")
 (inputShape
  .
  "one file helper embeds a port EOF loop, and one exported function opens a source file, reads forms, extracts def symbols, and accumulates results in the same named-let loop")
 (expectedOutcome
  .
  "read-forms owns port/read state; source-forms passes that helper to call-with-input-file; local-def-symbols composes filter-map with def-symbol")
 (expectedReferencePattern . "source-form-reader-boundary")
 (expectedReferenceExamples
  "gerbil://src/testing/gxtest-runner.ss#gxtest-file-forms"
  "gerbil://src/testing/gxtest-runner.ss#gxtest-file-local-def-symbols")
 (expectedQualitySignals
  "inline-file-reader-boundary"
  "reader-collection-boundary"
  "source-form-reader-boundary"
  "filter-map-selection-projection"
  "preserve-reader-state-helper")
 (learnedStyleSources
  "gerbil://src/testing/gxtest-runner.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject hand-written file reader loops and reader loops that also perform selection or projection; keep the port reader state helper explicit and compose callers with list combinators")
 (scenarioQualityAxes
  "inline-file-reader-boundary"
  "reader-collection-boundary"
  "source-form-reader-boundary"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "reader" "filter-map" "anti-scaffold"))
