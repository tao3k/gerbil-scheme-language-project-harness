((max_total . 12ms)
 (observed_total . 4ms)
 (target_total . 10ms)
 (regression_budget . 8ms)
 (expected_over_input_budget . 2ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "real Marlin config-interface large-object repair must stay near 10ms and hard-fail above 12ms")
 (maxCollectMs . 6)
 (observedCollectMs . 0)
 (maxParseMs . 8)
 (observedParseMs . 0)
 (maxFileMs . 3)
 (observedFileMs . 0)
 (maxPhaseMs . 4)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "real Marlin config-interface large POO objects stay native, idiomatic, and performance-gated")
 (feature . "poo-marlin-config-interface-large-object")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-027")
 (optimizationFocus . "native .o config-interface declarations with .o match-pattern projection and compact spec destructuring")
 (inputShape
  .
  "Marlin config-interface profile projection descriptors built through adapter alists plus repeated .get governor projections")
 (expectedOutcome
  .
  "represent large POO declarations with native .o, use lambda-match over compact specs, map specs to descriptors, project repeated object reads with .o match patterns, and keep adapters at external boundaries only")
 (nativePooPrimary . #t)
 (adapterBoundary . "marlin-policy-object<-alist is only valid for external alist ingestion; stable config-interface declarations stay native .o")
 (hotPathExemption . "marlin-config-interface-large-native-poo-object")
 (hotPathEvidence
  "real-marlin-config-interface"
  "native-poo-primary"
  "large-object"
  "lambda-match-spec-destructuring"
  "higher-order-map"
  ".o-match-pattern-projection"
  "batch-slot-projection"
  "match-projection-destructuring"
  "optimizer-visible-poo-hot-path"
  "adapter-boundary"
  "single-digit-ms-target"
  "benchmark-contract")
 (optimizerVisibility
  .
  "compact native .o specs, lambda-match destructuring, and .o match projection keep the hot projection path lexically visible instead of hiding it behind adapter alists")
 (expectedQualitySignals
  "native-.o-declaration"
  "lambda-match-spec-destructuring"
  ".o-match-pattern-projection"
  "lexical-direct-projection")
 (learnedStyleSources
  "gerbil://gerbil/compiler/optimize-call.ss#%#call-unchecked"
  "gerbil://object.ss#item/def/with-slots"
  "gerbil://object.ss#item/def/.refs/slots")
 (styleRewriteBoundary
  .
  "do not replace native .o config-interface declarations with object<-alist/list/cons; optimize by naming compact specs, destructuring them with lambda-match, and using .o match patterns before building boundary metadata")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "marlin" "config-interface" "large-object" "lambda-match" "performance"))
