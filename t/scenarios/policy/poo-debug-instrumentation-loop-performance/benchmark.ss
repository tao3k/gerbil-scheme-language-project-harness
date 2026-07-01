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
  "observed baseline 3ms for poo-debug-instrumentation-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R035 debug instrumentation repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-debug-instrumentation")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-035")
 (optimizationFocus . "loop-local debug instrumentation")
 (inputShape . "manual loop repeatedly wrapping trace-poo instrumentation")
 (expectedRepair . "keep the stable profile as native .o and hoist trace-poo outside the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "debug-instrumentation-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "debug-wrapper"
  "hoisted-setup-boundary"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not introduce repeated debug wrappers inside a measured loop; keep instrumentation at one setup boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "debug"))
