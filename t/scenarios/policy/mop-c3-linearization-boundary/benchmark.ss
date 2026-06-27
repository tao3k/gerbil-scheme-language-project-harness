((max_total . 28ms)
 (observed_total . 6ms)
 (target_total . 16ms)
 (regression_budget . 22ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "mop-c3-linearization-boundary is a small source-mined scenario from gerbil/runtime/c3.ss and gerbil/runtime/interface.ss; target keeps C3/MOP guidance in the low millisecond policy lane")
 (maxCollectMs . 12)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 8)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 MOP/C3 linearization scenario routes ad hoc superclass ordering toward local precedence descriptors and merge helpers")
 (feature . "mop-c3-linearization-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "C3 precedence-list boundary and MOP descriptor helpers")
 (inputShape
  .
  "single exported owner reconstructs precedence order while mixing superclass shape checks, duplicate filtering, and merge policy")
 (expectedRepair
  .
  "introduce local precedence node descriptors, split tail merge/select helpers, and keep the exported linearizer as a small orchestration boundary")
 (expectedReferencePattern . "gerbil-runtime-c3-linearization-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/runtime/c3.ss#c4-linearize"
  "gerbil://gerbil/runtime/c3.ss#merge-sis!"
  "gerbil://gerbil/runtime/c3.ss#precedence-list"
  "gerbil://gerbil/runtime/interface.ss#interface-descriptor")
 (expectedQualitySignals
  "c3-precedence-boundary"
  "mop-descriptor-boundary"
  "linearization-tail-merge-helper"
  "single-export-orchestration")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "teach agents to isolate class precedence and MOP descriptor reasoning instead of writing broad list-mutation superclass walkers")
 (scenarioQualityAxes
  "mop-c3-linearization-boundary"
  "gerbil-runtime-mop"
  "c3-precedence-list"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style"
       "gerbil-native"
       "mop"
       "c3"
       "linearization"
       "precedence"
       "descriptor-boundary"))
