((max_total . 25ms)
 (observed_total . 7ms)
 (target_total . 15ms)
 (regression_budget . 18ms)
 (observedTimings
  ((name . collect-before) (durationMs . 4))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "observed baseline 7ms for poo-object-construction-loop-performance; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
(iterations . 3)
 (unit . "ms")
 (purpose . "R033 object construction repair scenario keeps policy analysis within the scenario-owned timing gate")
 (feature . "poo-loop-object-construction")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-033")
 (optimizationFocus . "loop-local object construction")
 (inputShape . "manual loop repeatedly constructing POO objects through object<-hash, object<-fun, and make-object")
 (expectedRepair . "use native .o for the stable profile shape, collapse repeated adapter construction into scalar loop state, and build one final native object at the boundary")
 (nativePooPrimary . #t)
 (adapterBoundary . "adapters are only for external data boundaries; native .o remains the optimized POO shape")
 (hotPathExemption . "object-construction-hot-loop")
 (hotPathEvidence
  "manual-loop"
  "native-poo-primary"
  "object-construction"
  "object<-hash"
  "object<-fun"
  "make-object"
  "single-boundary-object"
  "optimizer-visible-poo-hot-path"
  "benchmark-contract")
 (optimizerVisibility
  .
  "native .o names the stable shape once while the loop carries scalar state, so repeated adapter constructors do not obscure the hot path")
 (expectedQualitySignals
  "native-.o-declaration"
  "single-boundary-object"
  "scalar-loop-state"
  "no-loop-local-constructor")
 (learnedStyleSources
  "gerbil://object.ss#item/def/object<-fun"
  "gerbil://object.ss#item/def/object/init"
  "gerbil://gerbil/compiler/optimize-call.ss#apply-optimize-call")
 (styleRewriteBoundary
  .
  "do not construct stable POO objects inside a measured loop when scalar/list/hash accumulation can preserve one final boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "poo" "loop" "construction"))
