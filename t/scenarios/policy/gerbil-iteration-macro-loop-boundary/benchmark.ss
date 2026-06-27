((max_total . 20ms)
 (observed_total . 4ms)
 (target_total . 12ms)
 (regression_budget . 16ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed gerbil-iteration-macro-loop-boundary receipt is 4ms total; target keeps native iteration macro policy in the small millisecond budget while max_total remains the hard regression ceiling")
 (maxCollectMs . 8)
 (maxParseMs . 12)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 teaches agents to use Gerbil iteration macros when the loop contract is static and can be generated hygienically")
 (feature . "gerbil-iteration-macro-loop-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "macro-generated iteration with binding contracts and filter clauses")
 (inputShape
  .
  "agent-generated loops manually thread accumulators, predicates, and pattern checks through verbose generic recursion")
 (expectedRepair
  .
  "use Gerbil for/iteration macro forms when bindings, filters, contracts, or match patterns are static enough to generate a tight loop")
 (expectedReferencePattern . "gerbil-iteration-macro-contract-boundary")
 (expectedReferenceExamples
  "gerbil://std/iter/macros.ss#for"
  "gerbil://std/iter/macros.ss#for-binding?"
  "gerbil://std/iter/macros.ss#make-lambda-body")
 (expectedQualitySignals
  "macro-generated-loop"
  "binding-contract-preserved"
  "filter-clause-preserved"
  "manual-recursion-eliminated")
 (learnedStyleSources
  "gerbil://std/iter/macros.ss"
  "gerbil://gerbil/core/match.ss")
 (antiAiScaffoldIntent
  .
  "reject verbose hand-rolled loop scaffolding when Gerbil iteration macros can express the binding, filter, and match contract directly")
 (scenarioQualityAxes
  "gerbil-iteration-macros"
  "macro-generated-hot-loop"
  "contract-aware-binding"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "macro" "iteration" "for" "hot-loop"))
