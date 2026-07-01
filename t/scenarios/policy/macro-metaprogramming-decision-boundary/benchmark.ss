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
  "macro metaprogramming decision scenario is a small source owner; collection and policy must stay inside a millisecond-scale gate")
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
 (purpose . "R013 teaches when to use declarative macros and when to upgrade to procedural metaprogramming")
 (feature . "macro-metaprogramming-decision-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "AI repeated macro wrappers to one defrules family plus syntax-case only at the validation/source-error boundary")
 (inputShape
  .
  "same-prefix defrules wrappers plus a procedural transformer without a documented decision boundary")
 (expectedRepair
  .
  "declarative defrules family for fixed rewrites, procedural syntax-case/with-syntax only for identifier validation and source-aware errors")
 (expectedReferencePattern . "gerbil-macro-metaprogramming-decision-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/sugar.ss#defrules"
  "gerbil://std/sugar.ss#let-hash"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match")
 (expectedQualitySignals
  "macro-metaprogramming-decision-boundary"
  "declarative-macro-pattern"
  "procedural-macro-transformer"
  "syntax-object-validation"
  "identifier-reconstruction"
  "with-syntax-reconstruction"
  "source-aware-syntax-error")
 (learnedStyleSources "gerbil://" "gerbil-utils" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "prevent agents from writing basic repeated Scheme wrappers or procedural macro scaffolding when Gerbil has a clearer declarative/procedural split")
 (scenarioQualityAxes
  "macro-metaprogramming-decision-boundary"
  "declarative-macro-pattern"
  "procedural-macro-transformer"
  "syntax-object-validation"
  "identifier-reconstruction"
  "with-syntax-reconstruction"
  "source-aware-syntax-error")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "metaprogramming" "declarative" "procedural"))
