((max_total . 35ms)
 (observed_total . 6ms)
 (target_total . 20ms)
 (regression_budget . 29ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 0))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "complex real-agent-basic-syntax scenario measured through policy-scenario-run/timed after full compile; keep total under 35ms and target under 20ms")
 (maxCollectMs . 15)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 10)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "realistic agent-authored Scheme scenario combines POO hot-loop mutation, manual event traversal, conditional dispatch, tuple projection, and threshold specialization")
 (feature . "real-agent-basic-syntax")
   (rule . "GERBIL-SCHEME-AGENT-REAL-BASIC-SYNTAX-028")
 (optimizationFocus
  .
  "replace basic Scheme scaffolding with Gerbil/Gambit idioms while preserving POO hot-path boundaries")
 (inputShape
  .
  "agent-style dashboard workflow mixes rest/accumulator named-let, car/cdr tuple projection, nested conditional dispatch, and loop-local POO clone override")
 (expectedRepair
  .
  "use fold and lambda-match for event scoring, case for closed symbolic dispatch, case-lambda for arity specialization, values/call-with-values for tuple protocol, dynamic-wind for explicit control boundary, and one final POO clone")
 (expectedReferencePattern . "gerbil-gambit-native-idiom-real-agent-workflow")
 (expectedReferenceExamples
  "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
  "gerbil://gerbil/core/sugar.ss#case-dispatch"
  "gerbil://gerbil/core/match.ss#with-match-boundary"
  "gerbil://gerbil/compiler/optimize-call.ss#alet-dependent-chain"
  "gerbil://gerbil/compiler/base.ss#ast-case-syntax-object-boundary"
  "gerbil-utils/base.ss#lambda-match"
  "gerbil-utils/list.ss#fold-map"
  "poo-flow/src/module-system/object-core.ss#poo-object-boundary")
 (expectedQualitySignals
  "basic-syntax-scaffold"
  "manual-loop-drift"
  "destructuring-combinator-boundary"
  "controlled-branch-conditional-dispatch"
  "poo-loop-state-mutation"
  "gerbil-native-pattern-boundary"
  "match-with-destructuring-boundary"
  "native-case-dispatch-boundary"
  "alet-dependent-chain-boundary"
  "syntax-object-ast-case-boundary"
  "values-tuple-protocol"
  "case-lambda-arity-specialization"
  "dynamic-wind-control-boundary")
 (learnedStyleSources
  "gerbil://"
  "gerbil-utils"
  "poo-flow"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject agent-authored procedural scaffolding that hides data shape, tuple protocol, and POO mutation boundary in one owner")
 (scenarioQualityAxes
  "real-agent-basic-syntax"
  "gerbil-gambit-native-idiom"
  "gerbil-core-sugar-dispatch"
  "gerbil-core-match-destructuring"
  "poo-hot-path-boundary"
  "anti-ai-scaffold")
 (hotPathExemption . "poo-boundary-api-workflow")
 (hotPathEvidence
  "manual-loop"
  "poo-api-boundary"
  "scalar-state-accumulation"
  "multi-rule-performance"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "do not move POO object construction or clone override back into the event traversal; apply POO mutation once at the boundary unless a benchmark proves it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "real-agent"
       "poo-flow"
       "harness"
       "gerbil-idiom"
       "gambit-control"
       "lambda-match"
       "case"
       "match"
       "with"
       "alet"
       "ast-case"
       "case-lambda"
       "values"
       "dynamic-wind"))
