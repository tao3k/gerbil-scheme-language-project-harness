((max_total . 100ms)
 (observed_total . 1ms)
 (target_total . 25ms)
 (regression_budget . 75ms)
 (expected_over_input_budget . 5ms)
 (observedTimings
  ((name . collect-before) (durationMs . 1))
  ((name . policy-before) (durationMs . 1))
  ((name . collect-after) (durationMs . 1))
  ((name . policy-after) (durationMs . 1))
  ((name . select-file) (durationMs . 1))
  ((name . delegate-contract) (durationMs . 1))
  ((name . delegate-discovery) (durationMs . 1))
  ((name . setup-cleanup-export-discovery) (durationMs . 1)))
 (targetRationale
  .
  "upstream gxtest delegation must keep selection hot while preserving gxtest-owned suite and setup/cleanup discovery")
 (maxCollectMs . 50)
 (observedCollectMs . 1)
 (maxParseMs . 50)
 (observedParseMs . 1)
 (maxFileMs . 50)
 (observedFileMs . 1)
 (maxPhaseMs . 50)
 (observedPhaseMs . 1)
 (maxRssMb . 512)
 (memoryMetric . resident-set-size)
 (memoryUnit . "MB")
 (iterations . 3)
 (unit . "ms")
 (purpose . "prove the testing framework selects files and delegates gxtest semantics to the gxtest runner")
 (feature . "upstream-gxtest-delegation")
 (rule . "GERBIL-SCHEME-TESTING-UPSTREAM-GXTEST-DELEGATION")
 (optimizationFocus
  .
  "keep selection and receipt construction in the framework while leaving suite export and setup/cleanup semantics to gxtest-compatible delegates")
 (inputShape
  .
  "scenario build.ss declares one gxtest manifest suite with files that export test-setup!, test-cleanup!, and *-test suites")
 (expectedRepair
  .
  "use testing-select-project for scope selection, pass selected files to the gxtest delegate, and inspect gxtest exports through the runner")
 (measurementPhases
  "collect-before"
  "policy-before"
  "collect-after"
  "policy-after"
  "select-file"
  "delegate-contract"
  "delegate-discovery"
  "setup-cleanup-export-discovery"
  "assert-time-gate"
  "assert-memory-gate")
 (tags "testing"
       "framework"
       "gxtest"
       "delegation"
       "setup-cleanup"
       "scenario"
       "performance"
       "hot"))
