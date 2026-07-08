((max_total . 25ms)
 (observed_total . 5ms)
 (target_total . 15ms)
 (regression_budget . 20ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 5ms for poo-clone-override-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
(iterations . 3)
 (unit . "ms")
 (purpose . "R028 clone override repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-clone-override")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-028")
 (optimizationFocus . "loop-local clone override")
 (inputShape . "manual loop repeatedly cloning POO state")
 (expectedOutcome . "keep the stable profile as native .o, accumulate scalar loop state, and apply one final native clone override")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.cc remains the optimized POO shape")
 (optimizerVisibility
  .
  "loop-local .cc is collapsed into scalar accumulation plus one final native .cc boundary, keeping the loop free of repeated object shape cloning")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-.cc-boundary"
  "scalar-loop-state"
  "no-loop-local-clone")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.cc"
  "gerbil://object.ss#item/def/object/init"
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call")
 (hotPathExemption . "poo-loop-state-mutation")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "clone-override"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar loop accumulation with higher-order composition unless a benchmark proves it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "clone"))
