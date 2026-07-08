((max_total . 25ms)
 (observed_total . 9ms)
 (target_total . 15ms)
 (regression_budget . 16ms)
 (observedTimings
  ((name . collect-before) (durationMs . 2))
  ((name . collect-after) (durationMs . 3))
  ((name . policy-before) (durationMs . 2))
  ((name . policy-after) (durationMs . 2)))
 (targetRationale
  .
  "observed baseline 9ms for concurrency-control-boundary; target keeps optimization visible and max_total is the hard regression ceiling")
 (maxCollectMs . 10)
 (observedCollectMs . 0)
 (maxParseMs . 15)
 (observedParseMs . 0)
 (maxFileMs . 5)
 (observedFileMs . 0)
 (maxPhaseMs . 6)
 (observedPhaseMs . 0)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 1)
 (unit . "ms")
 (purpose . "R013 concurrency control scenario keeps learned dynamic-wind, spawn/join, and sequentialization repair within the scenario-owned timing gate")
 (feature . "concurrency-control-boundary")
 (rule . "GERBIL-SCHEME-AGENT-POLICY-013")
 (optimizationFocus
  .
  "local dynamic-wind reentry, spawn/join/mutex/race/thread-parameter boundary")
 (inputShape
  .
  "single exported function mixes Thread, Spawn, Join, Mutex, Race, and Parallel responsibilities")
 (expectedOutcome
  .
  "local concurrency helpers split scheduling responsibilities without adding gerbil-utils dependencies")
 (expectedReferencePattern . "concurrency-control-boundary")
 (expectedReferenceExamples
  "gerbil://gerbil/runtime/control.ss#make-atomic-promise"
  "gerbil://gerbil/runtime/control.ss#call-with-parameters"
  "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
  "gerbil-utils/concurrency.ss#sequentialize/mutex"
  "gerbil-utils/concurrency.ss#race/list"
  "gerbil-utils/concurrency.ss#parallel-map")
 (expectedQualitySignals
  "dynamic-wind-reentry-guard"
  "unwind-cleanup-boundary"
  "spawn-join-helper-boundary"
  "mutex-sequentialization-boundary"
  "parallel-map-join-boundary")
 (learnedStyleSources "gerbil://" "gerbil-utils")
 (antiAiScaffoldIntent
  .
  "reject all-in-one thread orchestration scaffolding when contracts expose concurrency responsibilities")
 (scenarioQualityAxes "concurrency-control-boundary" "anti-ai-scaffold")
 (measurementPhases
  "collect-before"
  "collect-after"
  "policy-before"
  "policy-after"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "style" "concurrency" "control-boundary"))
