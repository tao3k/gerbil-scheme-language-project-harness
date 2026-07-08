((target_total . 18ms)
 (max_total . 30ms)
 (observed_total . 4ms)
 (regression_budget . 26ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . policy-after) (durationMs . 1)))
 (targetRationale
  .
  "observed baseline 4ms for scoped match-extension-boundary; target keeps the match macro policy scenario in a small millisecond budget while max_total remains the hard regression ceiling")
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
 (purpose . "R013 match extension scenario keeps Gerbil core/match defsyntax-for-match and applicative destructuring guidance under the scenario-owned timing gate")
 (feature . "match-extension-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus . "Gerbil core/match match macro extension, syntax-local lookup, and applicative destructuring boundaries")
 (inputShape
  .
  "macro owner mixes match pattern parsing, syntax-local expansion, struct/class field accessors, applicative apply destructuring, pattern variables, and source-aware errors in one runtime dispatcher")
 (expectedOutcome
  .
  "defsyntax-for-match surface with pattern parsing isolated from runtime predicate helpers and source-aware errors kept at the match extension boundary")
 (learnedStyleSources
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro?"
  "gerbil://gerbil/core/match.ss#struct-field-accessors")
 (antiAiScaffoldIntent
  .
  "reject table-shaped match extension macros that reimplement Gerbil match macro lookup, applicative destructuring, and struct/class accessor extraction")
 (scenarioQualityAxes
  "match-extension-boundary"
  "match-macro-destructuring-boundary"
  "syntax-local-match-macro-boundary"
  "applicative-destructuring-boundary"
  "anti-ai-scaffold")
 (expectedReferencePattern . "gerbil-core-match-extension-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#match-macro"
  "gerbil://gerbil/core/match.ss#syntax-local-match-macro?"
  "gerbil://gerbil/core/match.ss#parse-match-pattern"
  "gerbil://gerbil/core/match.ss#struct-field-accessors"
  "gerbil://gerbil/core/match.ss#defsyntax-for-match"
  "gerbil://gerbil/core/match.ss#defrules-for-match")
 (expectedQualitySignals
  "match-extension-boundary"
  "match-macro-destructuring-boundary"
  "syntax-local-match-macro-boundary"
  "applicative-destructuring-boundary"
  "struct-class-accessor-boundary"
  "source-aware-pattern-error-boundary")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "macro" "match"))
