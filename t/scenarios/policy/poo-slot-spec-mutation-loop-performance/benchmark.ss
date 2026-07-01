((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 3ms for poo-slot-spec-mutation-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R036 slot spec mutation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-spec-mutation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-036")
 (optimizationFocus . "loop-local slot spec mutation")
 (inputShape . "manual loop repeatedly mutating POO slot definitions")
 (expectedRepair . "construct the mutable profile with native .o, define slots once, and mutate values intentionally")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the mutable POO source shape")
 (hotPathExemption . "slot-spec-mutation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "slot-spec-mutation"
  "value-mutation-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not perform structural slot-spec mutation inside a measured loop; keep structure setup outside and value mutation explicit")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "slot-spec"))
