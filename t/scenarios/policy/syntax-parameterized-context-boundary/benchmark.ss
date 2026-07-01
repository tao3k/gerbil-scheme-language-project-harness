((max_total . 30ms)
 (observed_total . 4ms)
 (target_total . 18ms)
 (regression_budget . 26ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 0)))
 (targetRationale
  .
  "syntax-parameterized context is a small macro owner; collection and policy must stay inside a millisecond-scale gate")
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
 (purpose . "R013 teaches Gerbil syntax parameters for scoped compile-time macro context")
 (feature . "syntax-parameterized-context-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "mutable compile-time macro globals to defsyntax-parameter* plus syntax-parameterize")
 (inputShape
  .
  "macro owner mutates a compile-time global to simulate contextual macro state")
 (expectedRepair
  .
  "defsyntax-parameter* declares the contextual macro and syntax-parameterize binds it at the call boundary")
 (expectedReferencePattern . "gerbil-syntax-parameterized-context-boundary")
 (expectedReferenceExamples
  "gerbil://std/stxparam.ss#defsyntax-parameter"
  "gerbil://std/stxparam.ss#syntax-parameterize"
  "gerbil://std/text/csv.ss#ambient-csv-options"
  "gerbil://std/actor-v18/message.ss#@envelope")
 (expectedQualitySignals
  "syntax-parameterized-context-boundary"
  "syntax-parameter-definition"
  "syntax-parameterized-context"
  "global-macro-state-mutation"
  "manual-phase-context-threading"
  "source-aware-syntax-error")
 (learnedStyleSources
  "gerbil://std/stxparam.ss"
  "gerbil://std/text/csv.ss"
  "gerbil://std/actor-v18/message.ss"
  "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "prevent agents from storing contextual macro state in mutable compile-time globals when Gerbil syntax parameters provide a scoped phase-safe boundary")
 (scenarioQualityAxes
  "syntax-parameterized-context-boundary"
  "syntax-parameter-definition"
  "syntax-parameterized-context"
  "global-macro-state-mutation"
  "manual-phase-context-threading"
  "source-aware-syntax-error")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "metaprogramming" "syntax-parameter" "phase-context"))
