((max_total . 35ms)
 (observed_total . 8.5ms)
 (target_total . 18.5ms)
 (regression_budget . 26.5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 3.25))
  ((name . collect-after) (durationMs . 3.75))
  ((name . policy-before) (durationMs . 1.0))
  ((name . policy-after) (durationMs . 0.5)))
 (targetRationale
  .
  "gerbil-upstream-idiom-performance is a subsecond scenario benchmark with fractional millisecond observed timings; max_total remains the hard gate")
 (maxCollectMs . 12)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 8)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 upstream idiom scenario connects gerbil:// match, compiler eq-hash indexing, and cut-style helper plumbing to agent-facing policy repair")
 (feature . "gerbil-upstream-idiom-performance")
 (rule . "GERBIL-SCHEME-AGENT-R013")
 (optimizationFocus
  .
  "basic Scheme route scaffolding to match dispatch, one eq-hash index, and cut-specialized traversal")
 (inputShape
  .
  "agent-authored owner repeats assq route lookup, named-let traversal, reverse accumulator, and branch-local defaulting")
 (expectedRepair
  .
  "event shape helpers, core match dispatch, route-index make-hash-table-eq precomputation, cut-specialized map traversal, and filter-map label projection")
 (expectedReferencePattern . "gerbil-upstream-idiom-performance")
 (expectedReferenceExamples
  "gerbil://gerbil/core/match.ss#match/match*"
  "gerbil://gerbil/core/match.ss#with/with*"
  "gerbil://gerbil/compiler/optimize-spec.ss#make-hash-table-eq-method-calls"
  "gerbil://gerbil/compiler/optimize-spec.ss#cut-compile-e"
  "gerbil://gerbil/compiler/optimize-top.ss#optimizer-cache-facts")
 (expectedQualitySignals
  "gerbil-upstream-idiom-boundary"
  "match-shape-dispatch"
  "with-destructuring-boundary"
  "eq-hash-index-hot-path"
  "cut-helper-plumbing"
  "hash-index-outside-traversal")
 (learnedStyleSources "gerbil://" "harness-self-apply")
 (antiAiScaffoldIntent
  .
  "reject broad agent-authored Scheme scaffolding when Gerbil core/compiler idioms expose data shape and move repeated symbolic lookup out of hot traversal")
 (scenarioQualityAxes
  "gerbil-upstream-idiom-boundary"
  "match-shape-dispatch"
  "eq-hash-index-hot-path"
  "cut-helper-plumbing"
  "anti-ai-scaffold")
 (hotPathExemption . "symbol-route-index")
 (hotPathEvidence
  "repeated-assq-route-lookup"
  "symbol-key-route-table"
  "single-index-build-before-map"
  "benchmark-contract")
 (styleRewriteBoundary
  .
  "build the eq hash route index once before traversal; do not reintroduce route-table scans inside route-event without a benchmark proving it is no slower")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style"
       "gerbil-upstream"
       "match"
       "with"
       "eq-hash"
       "cut"
       "hot-path"
       "subsecond"))
