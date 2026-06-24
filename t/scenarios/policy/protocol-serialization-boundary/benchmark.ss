((maxTotalMs . 1000)
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 serialization protocol scenario keeps learned representation-layer repair within the scenario-owned timing gate")
 (feature . "protocol-serialization-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "local JSON/string/bytes/marshal adapter boundary")
 (inputShape . "single exported function mixes JSON, String, Bytes, and Marshal representation layers")
 (expectedRepair . "local protocol helpers split representation layers without adding gerbil-poo or gerbil-utils dependencies")
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
 (antiAiScaffoldIntent . "reject one-owner serialization scaffolding that collapses JSON, string, bytes, and marshal layers")
 (scenarioQualityAxes "protocol-serialization-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after" "assert-time-gate" "assert-memory-gate")
 (tags "style" "serialization" "protocol-boundary"))
