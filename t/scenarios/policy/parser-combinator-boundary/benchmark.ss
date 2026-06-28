((max_total . 24ms)
 (observed_total . 6ms)
 (target_total . 14ms)
 (regression_budget . 18ms)
 (expected_over_input_budget . 0ns)
 (observedTimings
  ((name . collect-before) (durationMs . 2) (durationNs . 2000000))
  ((name . collect-after) (durationMs . 2) (durationNs . 2000000))
  ((name . policy-before) (durationMs . 1) (durationNs . 1000000))
  ((name . policy-after) (durationMs . 1) (durationNs . 1000000)))
 (targetRationale
  .
  "parser-combinator-boundary keeps manual parser-state detection parser-owned and verifies expected repair is no slower than input")
 (maxCollectMs . 10)
 (observedCollectMs . 4)
 (maxParseMs . 14)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 2)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 parser combinator scenario rejects hand-written string cursor parsers when std/parser grammar boundaries are available")
 (feature . "parser-combinator-boundary")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "manual string cursor parser state machine to std/parser defparser grammar boundary")
 (inputShape
  .
  "single exported parser uses named-let cursor state, string-ref, substring, and inline parse errors")
 (expectedRepair
  .
  "defparser grammar with parser-fail/parser-rewind and source-aware parse-error boundary")
 (expectedReferencePattern . "gerbil-std-parser-combinator-boundary")
 (expectedReferenceExamples
  "gerbil://std/parser/defparser.ss#defparser"
  "gerbil://std/parser/defparser.ss#parser-fail"
  "gerbil://std/parser/defparser.ss#parser-rewind"
  "gerbil://std/parser/rx-parser.ss#raise-parse-error")
 (expectedQualitySignals
  "parser-combinator-boundary"
  "manual-parser-state-machine"
  "defparser-grammar-boundary"
  "source-aware-parse-error"
  "token-construction-boundary")
 (learnedStyleSources
  "gerbil://std/parser/defparser.ss"
  "gerbil://std/parser/rx-parser.ss")
 (antiAiScaffoldIntent
  .
  "reject ad hoc string parsing state machines when a grammar-owned parser combinator boundary can express parse, rewind, failure, and token construction")
 (scenarioQualityAxes
  "parser-combinator-boundary"
  "anti-ai-parser-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "parser" "defparser" "anti-scaffold"))
