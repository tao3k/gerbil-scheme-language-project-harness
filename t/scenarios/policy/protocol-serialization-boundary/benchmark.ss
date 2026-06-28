((max_total . 25ms)
 (observed_total . 9ms)
 (target_total . 15ms)
 (regression_budget . 16ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 9ms for protocol-serialization-boundary; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 serialization protocol scenario keeps learned representation-layer repair within the scenario-owned timing gate")
 (feature . "protocol-serialization-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "local JSON/string/bytes/marshal adapter boundary")
 (inputShape
  .
  "single exported function mixes JSON, String, Bytes, and Marshal representation layers")
 (expectedRepair
  .
  "local protocol helpers split representation layers without adding gerbil-poo or gerbil-utils dependencies")
 (expectedReferencePattern . "protocol-serialization-boundary")
 (expectedReferenceExamples
  "gerbil-poo/io.ss#marshal"
  "gerbil-poo/io.ss#bytes<-"
  "gerbil-poo/io.ss#methods.marshal<-bytes")
 (expectedQualitySignals
  "self-delimited-marshal-boundary"
  "bytes-non-self-delimited-boundary"
  "local-protocol-adapter"
  "protocol-layer-scaffold-collapse")
 (learnedStyleSources "gerbil-poo" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject one-owner serialization scaffolding that collapses JSON, string, bytes, and marshal layers")
 (scenarioQualityAxes "protocol-serialization-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "serialization" "protocol-boundary"))
