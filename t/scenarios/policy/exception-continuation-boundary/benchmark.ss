((maxTotalMs . 75)
 (observedTotalMs . 38)
 (targetTotalMs . 43)
 (regressionBudgetMs . 37)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 32)))
 (targetRationale
  .
  "observed baseline 38ms for exception-continuation-boundary; target keeps optimization visible and maxTotalMs covers observed full-suite timing variance without returning to a broad timeout")
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 exception continuation scenario keeps learned exception-control repair within the scenario-owned timing gate")
 (feature . "exception-continuation-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "local exception continuation and contextual logging boundary")
 (inputShape
  .
  "single exported function mixes Exception, Continuation, Handler, Context, and Raise responsibilities")
 (expectedRepair
  .
  "local exception helpers split printable diagnostics, contextual logging, and re-raise behavior without adding gerbil-utils dependencies")
 (expectedReferencePattern . "exception-continuation-boundary")
 (expectedReferenceExamples
  "gerbil-utils/exception.ss#with-catch/cont"
  "gerbil-utils/exception.ss#call-with-logged-exceptions"
  "gerbil-utils/exception.ss#with-logged-exceptions")
 (expectedQualitySignals
  "handler-restoration-boundary"
  "contextual-exception-logging"
  "re-raise-after-logging")
 (learnedStyleSources "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject catch-all exception scaffolding when contracts expose continuation and handler responsibilities")
 (scenarioQualityAxes "exception-continuation-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "exception" "continuation" "context-boundary"))
