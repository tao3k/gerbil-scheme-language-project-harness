((maxTotalMs . 35)
 (observedTotalMs . 6)
 (targetTotalMs . 20)
 (regressionBudgetMs . 24)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed compiler-method-pass-boundary receipt is 6ms total with 2/3/1/1ms phase timings; target leaves runner variance while maxTotalMs keeps the scenario under a millisecond-scale hard ceiling")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 compiler method-pass scenario routes method-table drift toward local AST pass handlers")
 (feature . "compiler-method-pass-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "method-table lambda drift to compiler-style pass handlers")
 (inputShape
  .
  "method table slots are anonymous lambdas that hide dispatch and pass boundaries")
 (expectedRepair
  .
  "extract local pass handlers and keep the method table as a dispatch surface")
 (expectedReferencePattern . "gerbil-compiler-method-pass-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/compiler/method.ss#defcompile-method"
  "gerbil://gerbil/compiler/method.ss#xform-wrap-source"
  "gerbil://gerbil/compiler/optimize-top.ss#dispatch-lambda-form?")
 (expectedQualitySignals
  "method-table-pass-boundary"
  "ast-case-shape-dispatch"
  "source-preserving-transform"
  "typed-pass-pipeline")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "teach agents to replace method-table lambda sinks with local pass handlers and shape predicates")
 (scenarioQualityAxes
  "compiler-method-pass-boundary"
  "method-table-pass-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "gerbil-native" "compiler" "method-table" "ast-case" "pass-boundary"))
