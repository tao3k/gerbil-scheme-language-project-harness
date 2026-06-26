((maxTotalMs . 25)
 (observedTotalMs . 4)
 (targetTotalMs . 15)
 (regressionBudgetMs . 21)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 2))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for std-sugar-flow-boundary; target keeps chain and if-let repair visible and maxTotalMs is the hard regression ceiling")
 (maxCollectMs . 10)
 (maxParseMs . 15)
 (maxFileMs . 5)
 (maxPhaseMs . 5)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 std sugar flow scenario keeps nested let/if agent scaffolding under the scenario-owned timing gate while preferring std/sugar chain and if-let for local expression flow")
 (feature . "std-sugar-flow-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus . "nested let/if flow scaffolding to std/sugar chain and if-let")
 (inputShape . "workflow helpers combine nested conditional branches, required field lookups, optional retry state, and a resource-scoped audit writer")
 (expectedRepair . "use if-let for required bindings and chain for the linear status projection while preserving resource-scoped output flow")
 (misuseGuard . "do not rewrite call-with-output-file or other resource/control boundaries into std/sugar expression flow")
 (expectedReferencePattern . "std-sugar-flow-boundary")
 (expectedReferenceExamples
  "gerbil://std/sugar.ss#chain"
  "gerbil://std/sugar.ss#if-let"
  "gerbil://std/sugar.ss#when-let")
 (expectedQualitySignals
  "std-sugar-flow-boundary"
  "basic-syntax-scaffold"
  "chain-expression-flow"
  "early-failure-conditional")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject nested let/if scaffolding when the owner is a local workflow expression and std/sugar chain or if-let exposes the data path, but preserve resource/control boundaries")
 (scenarioQualityAxes
  "std-sugar-flow-boundary"
  "gerbil-gambit-native-idiom"
  "anti-ai-scaffold"
  "misuse-resistant-resource-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "std-sugar" "chain" "if-let" "conditional" "anti-scaffold"))
