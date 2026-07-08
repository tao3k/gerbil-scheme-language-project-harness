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
  "observed baseline 4ms for poo-materialization-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
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
 (purpose . "R029 materialization repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-materialization")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-029")
 (optimizationFocus . "loop-local materialization")
 (inputShape . "manual loop repeatedly materializing POO object data through .alist/sort, .all-slots, .all-slots/sort, hash<-object, and force-object")
 (expectedOutcome . "keep the stable profile as native .o, materialize each required boundary snapshot once, and keep loop state scalar")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the profile/config source shape")
 (hotPathExemption . "poo-materialization-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-materialization"
  ".alist/sort"
  ".all-slots"
  ".all-slots/sort"
  "hash<-object"
  "force-object"
  "single-boundary-snapshot"
  "optimizer-visible-poo-hot-path"
  "benchmark-contract")
 (optimizerVisibility
  .
  "full-object materialization stays as one named boundary snapshot and the loop consumes precomputed list/hash/scalar state")
 (expectedQualitySignals
  "single-boundary-snapshot"
  "scalar-loop-state"
  "no-loop-local-materialization"
  "native-.o-source-shape")
 (learnedStyleSources
  "gerbil://object.ss#item/def/.all-slots"
  "gerbil://object.ss#item/def/hash<-object"
  "gerbil://object.ss#item/def/force-object")
 (styleRewriteBoundary
  .
  "do not introduce repeated materialization inside a measured loop; keep one boundary snapshot")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "materialization"))
