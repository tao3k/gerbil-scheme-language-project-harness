((maxTotalMs . 1000)
 (maxCollectMs . 1000)
 (maxParseMs . 750)
 (maxFileMs . 250)
 (maxPhaseMs . 100)
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 exception continuation scenario keeps learned exception-control repair within the scenario-owned timing gate")
 (feature . "exception-continuation-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "local exception continuation and contextual logging boundary")
 (inputShape . "single exported function mixes Exception, Continuation, Handler, Context, and Raise responsibilities")
 (expectedRepair . "local exception helpers split printable diagnostics, contextual logging, and re-raise behavior without adding gerbil-utils dependencies")
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
 (antiAiScaffoldIntent . "reject catch-all exception scaffolding when contracts expose continuation and handler responsibilities")
 (scenarioQualityAxes "exception-continuation-boundary" "anti-ai-scaffold")
 (measurementPhases "collect-before" "collect-after" "policy-before" "policy-after")
 (tags "style" "exception" "continuation" "context-boundary"))
