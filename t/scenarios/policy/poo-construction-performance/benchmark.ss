((max_total . 25ms)
 (observed_total . 3ms)
 (target_total . 15ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 3ms for poo-construction-performance; target keeps native POO shape reuse visible and max_total is the hard regression ceiling")
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
 (iterations . 1)
 (unit . "ms")
 (purpose . "R027 native POO construction guard keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-native-object-shape-reuse")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-027")
 (optimizationFocus . "native large .o object shape reuse")
 (inputShape . "large native POO profile projection shape with one dynamic overlay")
 (expectedRepair . "preserve native .o shape, compose a small boundary overlay, and keep loop state scalar")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the optimized POO declaration shape")
 (hotPathExemption . "native-poo-declaration")
 (hotPathEvidence
  "native-poo-primary"
  "slot-spec-count"
  "native-.o-construction"
  "stable-shape-reuse"
  "boundary-overlay"
  "loop-slot-capture"
  "scalar-loop-state"
  "boundary-declaration"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not rewrite native .o profile/config declarations to object<-alist; optimize by naming stable native shapes, composing only small boundary overlays, and keeping loops in scalar state")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "construction" "native-object-shape-reuse"))
