((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-lens-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 5)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
(iterations . 3)
 (unit . "ms")
 (purpose . "R032 lens modify repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-lens")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-032")
 (optimizationFocus . "loop-local lens modification")
 (inputShape . "manual loop repeatedly applying lens-style POO updates")
 (expectedRepair
  .
  "keep the stable profile as native .o, accumulate scalar lens target state, and apply one final native update")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.cc remains the optimized POO shape")
 (optimizerVisibility
  .
  "lens-style object updates are reduced to scalar target accumulation and one final native update boundary, keeping repeated slot mutation out of the loop")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-lens-update-boundary"
  "scalar-loop-state"
  "no-loop-local-lens-update")
 (learnedStyleSources
  "gerbil://mop.ss#item/def/slot-lens"
  "gerbil://mop.ss#item/def/Lens"
  "gerbil://object.ss#item/def/.cc")
 (hotPathExemption . "poo-lens-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "lens-update"
  "scalar-state-accumulation"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not replace measured scalar lens accumulation with repeated object lens updates")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "lens"))
