((max_total . 25ms)
 (observed_total . 4ms)
 (target_total . 15ms)
 (regression_budget . 21ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 4ms for poo-composition-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R030 POO composition repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-composition")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-030")
 (optimizationFocus . "loop-local POO composition")
 (inputShape . "manual loop repeatedly composing POO objects")
 (expectedOutcome . "keep the stable profile as native .o, accumulate scalar state, and apply one final native .o overlay composition")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o/.mix remains the optimized POO shape")
 (optimizerVisibility
  .
  "loop-local composition is collapsed into scalar accumulation plus one final native .o/.mix composition boundary, preserving stable supers and direct loop state")
 (expectedQualitySignals
  "native-.o-source-shape"
  "single-composition-boundary"
  "scalar-loop-state"
  "no-loop-local-composition")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.mix"
  "gerbil://object.ss#item/def/.extend"
  "gerbil://object.ss#item/def/object/init")
 (hotPathExemption . "poo-composition-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "optimizer-visible-poo-hot-path"
  "poo-composition"
  "single-boundary-object"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite measured loop-local composition into a generic pipeline without preserving the one-boundary object construction")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "composition"))
