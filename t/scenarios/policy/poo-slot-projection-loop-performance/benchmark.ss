((max_total . 25ms)
 (observed_total . 5ms)
 (target_total . 15ms)
 (regression_budget . 20ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 5ms for poo-slot-projection-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R029 slot projection repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-slot-projection")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "with-slots fixed slot total")
 (inputShape . "manual loop repeatedly projecting POO slots")
 (expectedRepair . "keep the stable profile as native .o, bind fixed local slots with with-slots, and reduce scalar state once before the loop")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-slot-projection-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "slot-projection"
  "with-slots-fixed-slot-read"
  "scalar-slot-total"
  "optimizer-visible-poo-hot-path"
  "benchmark-contract")
 (optimizerVisibility
  .
  "with-slots turns a fixed slot set into lexical bindings, then the loop consumes one scalar total instead of dynamic slot projection")
 (expectedQualitySignals
  "fixed-slot-binding"
  "lexical-slot-access"
  "scalar-loop-state"
  "no-dynamic-projection-in-loop")
 (learnedStyleSources
  "gerbil://object.ss#item/def/%with-slots"
  "gerbil://object.ss#item/def/with-slots"
  "gerbil://gerbil/compiler/optimize-call.ss#using-class-slot-access")
 (styleRewriteBoundary
  .
  "do not materialize broad slot projections inside a measured loop; use with-slots for fixed local slot sets and reserve .refs/slots for dynamic or boundary batch projection")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "projection"))
