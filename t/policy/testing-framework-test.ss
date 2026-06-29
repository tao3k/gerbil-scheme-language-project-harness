;;; -*- Gerbil -*-
;;; POO-shaped testing framework contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/1 find)
        (only-in :clan/poo/object object? .o .ref .slot?)
        :testing/model
        :testing/framework
        :testing/build
        :testing/gxtest-smoke
        :testing/gxtest-runner
        :benchmark/framework
        "../scenarios/policy/downstream-testing-framework-api-loading/input/build.ss"
        "../scenarios/policy/marlin-testing-speed-trap/expected/build.ss"
        "../scenarios/policy/upstream-gxtest-delegation/expected/build.ss")

(export testing-framework-test)

(def +testing-fixture-root+
  "t/fixtures/testing-framework")

(def +testing-benchmark-root+
  "t/benchmarks/testing-framework")

(def +upstream-build-improvement-benchmark-root+
  "t/benchmarks/testing-framework-upstream-build-improvement")

(def +downstream-api-loading-scenario-root+
  "t/scenarios/policy/downstream-testing-framework-api-loading")

(def +marlin-speed-trap-scenario-root+
  "t/scenarios/policy/marlin-testing-speed-trap")

(def +upstream-gxtest-delegation-scenario-root+
  "t/scenarios/policy/upstream-gxtest-delegation")

(def (fixture-path file)
  (path-expand file +testing-fixture-root+))

(def (fixture-import->file import)
  (path-expand import +testing-fixture-root+))

(def (fake-run-files files)
  0)

(def (fake-run-scenario scenario)
  scenario)

(def (downstream-testing-path relative)
  (testing-build-path downstream-testing-project relative))

(def (marlin-speed-path relative)
  (testing-build-path marlin-speed-project relative))

(def (upstream-gxtest-path relative)
  (testing-build-path upstream-gxtest-project relative))

(def (testing-details-ref details key)
  (cdr (assq key details)))

(def (testing-receipt-detail receipt key)
  (testing-details-ref (testing-receipt-details receipt) key))

(def (testing-selection-detail selection key)
  (testing-details-ref (testing-selection-details selection) key))

(def (testing-test-phase-names receipt)
  (map testing-test-phase-name (testing-receipt-phases receipt)))

(def (testing-test-phase-name phase)
  (testing-receipt-detail phase 'phase))

(def (testing-test-phase receipt phase-name)
  (find (lambda (phase)
          (eq? (testing-test-phase-name phase) phase-name))
        (testing-receipt-phases receipt)))

(def +fake-native-poo-testing-project+
  (.o (name "native-poo-project")
      (suites [])
      (roots ["t"])
      (batchSize 2)
      (receiptPrefix "native-poo")))

(def +testing-project-from-native-poo+
  (testing-native-poo-object
   'testing-project
   +fake-native-poo-testing-project+
   '(name suites roots batchSize receiptPrefix)))

(def +testing-suite+
  (gxtest-suite
   name: "unit"
   default-root: (fixture-path "unit-tests.ss")
   roots: (list (fixture-path "unit-tests.ss"))
   batch-size: 1
   import->file: fixture-import->file
   gates: (list
           (performance-gate
            name: "testing-framework"
            contract-root: +testing-benchmark-root+))))

(def +testing-scenario-suite+
  (policy-scenario-suite
   name: "policy-scenarios"
   root: "t/scenarios/policy"
   scenario-ids: (list "poo-construction-performance")
   batch-size: 1
   runner: fake-run-scenario
   gates: (list
           (performance-gate
            name: "poo-scenario-contract"
            contract-root: "t/benchmarks/poo-scenario-contract"))))

(def +upstream-integration-suite+
  (gxtest-suite
   name: "integration"
   default-root: (fixture-path "integration-tests.ss")
   roots: (list (fixture-path "integration-tests.ss"))
   batch-size: 2
   import->file: fixture-import->file
   max-selected-files: 2
   max-selected-sources: 4
   max-selected-outputs: 4))

(def +upstream-build-improvement-scenario-suite+
  (policy-scenario-suite
   name: "policy-scenarios-complex"
   root: "t/scenarios/policy"
   scenario-ids: (list "poo-construction-performance"
                       "poo-real-dashboard-workflow-performance")
   batch-size: 1
   runner: fake-run-scenario
   gates: (list
           (performance-gate
            name: "testing-framework-upstream-build-improvement"
            contract-root: +upstream-build-improvement-benchmark-root+))))

(def +upstream-build-improvement-project+
  (testing-project
   name: "upstream-build-improvement"
   suites: (list +testing-suite+
                 +upstream-integration-suite+
                 +upstream-build-improvement-scenario-suite+)
   roots: (list +testing-fixture-root+ "t/scenarios/policy")
   batch-size: 3
   receipt-prefix: "gslph-upstream-build-improvement"))

(def +downstream-improvement-build+
  (testing-build
   name: "downstream-improvement"
   root: "."
   gxtest: [["unit" "t/fixtures/testing-framework/unit-tests.ss"]]
   scenario-root: "t/scenarios/policy"
   scenario-suite-name: "improvement-scenarios"
   improvement-scenarios: ["poo-construction-performance"]
   scenario-metadata:
   '(("poo-construction-performance"
      . ((downstreamRepairTarget . "poo-flow")
         (idiom . "native-poo-construction")
         (expectedRepair . "preserve native POO object syntax while optimizing runner mechanics")
         (benchmarkPhases . ("batch-split" "scenario-root-projection"))
         (nextRepairAction . "apply the native POO construction idiom to the downstream object builder"))))))

(def +testing-project+
  (testing-project
   name: "poo-flow-like"
   suites: (list +testing-suite+ +testing-scenario-suite+)
   roots: (list +testing-fixture-root+)
   receipt-prefix: "gslph-testing"))

(def testing-framework-test
  (test-suite "gerbil scheme POO-shaped testing framework"
    (test-case "testing project is a user-facing POO-shaped object"
      (check (object? +testing-project+) => #t)
      (check (.slot? +testing-project+ 'name) => #t)
      (check (.ref +testing-project+ 'name) => "poo-flow-like")
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (object? +testing-suite+) => #t)
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit")
      (check (object? +testing-scenario-suite+) => #t)
      (check (testing-object-kind +testing-scenario-suite+) => 'scenario-suite)
      (check (testing-suite-name +testing-scenario-suite+) => "policy-scenarios"))

    (test-case "native POO projection enters the same testing model"
      (check (object? +fake-native-poo-testing-project+) => #t)
      (check (.ref +fake-native-poo-testing-project+ 'name)
             => "native-poo-project")
      (check (object? +testing-project-from-native-poo+) => #t)
      (check (testing-object-kind +testing-project-from-native-poo+)
             => 'testing-project)
      (check (testing-project-name +testing-project-from-native-poo+)
             => "native-poo-project")
      (check (testing-project-batch-size +testing-project-from-native-poo+)
             => 2))

    (test-case "empty args expand through default manifest root"
      (check (testing-expand-suite-args +testing-suite+ [])
             => (list (fixture-path "alpha-test.ss")
                      (fixture-path "beta-test.ss"))))

    (test-case "declared root args expand like poo-flow manifests"
      (check (testing-expand-suite-args
              +testing-suite+
              (list (fixture-path "unit-tests.ss")))
             => (list (fixture-path "alpha-test.ss")
                      (fixture-path "beta-test.ss"))))

    (test-case "explicit files remain explicit"
      (check (testing-expand-suite-args
              +testing-suite+
              (list (fixture-path "alpha-test.ss")))
             => (list (fixture-path "alpha-test.ss"))))

    (test-case "suite batches files without downstream runner code"
      (check (testing-batches
              (list "a.ss" "b.ss" "c.ss")
              2)
             => '(("a.ss" "b.ss") ("c.ss"))))

    (test-case "batch splitting returns head and tail in one pass"
      (let-values (((batch rest)
                    (testing-split-batch
                     (list "a.ss" "b.ss" "c.ss")
                     2)))
        (check batch => '("a.ss" "b.ss"))
        (check rest => '("c.ss"))))

    (test-case "scenario suite expands declared policy scenarios"
      (let (scenarios
            (testing-expand-scenario-args +testing-scenario-suite+ []))
        (check (length scenarios) => 1)
        (check (testing-scenario-id (car scenarios))
               => "poo-construction-performance")
        (check (testing-scenario-root +testing-scenario-suite+ (car scenarios))
               => "t/scenarios/policy/poo-construction-performance")))

    (test-case "suite run returns machine-readable receipts"
      (let* ((receipt
              (testing-run-suite
               +testing-project+
               +testing-suite+
               []
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 2)
        (check (testing-receipt-files (car children))
               => (list (fixture-path "alpha-test.ss")))
        (check (testing-receipt-files (cadr children))
               => (list (fixture-path "beta-test.ss")))))

    (test-case "scenario suite run returns the same receipt shape"
      (let* ((receipt
              (testing-run-suite
               +testing-project+
               +testing-scenario-suite+
               []
               fake-run-files))
             (children (testing-receipt-children receipt))
             (batch (car children))
             (scenario-receipt
              (car (testing-receipt-children batch))))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-receipt-files scenario-receipt)
               => (list "t/scenarios/policy/poo-construction-performance"))
        (check (testing-receipt-detail scenario-receipt 'id)
               => "poo-construction-performance")))

    (test-case "project run manages gxtest and scenario suites together"
      (let (receipt
            (testing-run-project
             +testing-project+
             []
             fake-run-files))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length (testing-receipt-children receipt)) => 2)))

    (test-case "project receipt separates scope selection as a phase"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (phase-names (testing-test-phase-names receipt)))
        (check (member 'select-scope phase-names) ? true)))

    (test-case "gxtest suite receipt separates expansion, delegate, and benchmark phases"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "unit-tests.ss"))
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt)))
        (check (member 'expand-manifest phase-names) ? true)
        (check (member 'delegate-gxtest phase-names) ? true)
        (check (member 'benchmark-assert phase-names) ? true)))

    (test-case "scenario suite receipt separates policy delegate and benchmark phases"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list "poo-construction-performance")
               fake-run-files))
             (suite-receipt (car (testing-receipt-children receipt)))
             (phase-names (testing-test-phase-names suite-receipt))
             (delegate-phase
              (testing-test-phase suite-receipt 'delegate-policy)))
        (check (member 'delegate-policy phase-names) ? true)
        (check (member 'benchmark-assert phase-names) ? true)
        (check (testing-receipt-files delegate-phase)
               => (testing-receipt-files suite-receipt))))

    (test-case "default testing gate includes full self-apply policy"
      (let ((files (gslph-default-gxtest-smoke-files))
            (suite (gslph-default-gxtest-smoke-suite)))
        (check (member "t/self-apply-full-gate.ss" files) ? true)
        (check (testing-suite-files suite) => files)))

    (test-case "project run selects only the matching gxtest suite"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)))

    (test-case "project selection is a POO object before execution"
      (let* ((selection
              (testing-select-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))))
             (suites (testing-selection-suites selection)))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #t)
        (check (testing-selection-project selection) => +testing-project+)
        (check (testing-selection-args selection)
               => (list (fixture-path "alpha-test.ss")))
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "unit")))

    (test-case "project run consumes POO selection without widening"
      (let* ((selection
              (testing-select-project
               +testing-project+
               (list (fixture-path "alpha-test.ss"))))
             (receipt
              (testing-run-selection selection fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)
        (check (testing-receipt-files (car children))
               => (list (fixture-path "alpha-test.ss")))))

    (test-case "project selection reports rejected scopes before execution"
      (let (selection
            (testing-select-project
             +testing-project+
             (list "unknown-scope")))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #f)
        (check (testing-selection-suites selection) => [])
        (check (testing-selection-detail selection 'reason)
               => 'no-selected-suites)))

    (test-case "project run does not widen explicit files across gxtest suites"
      (let* ((other-suite
              (gxtest-suite
               name: "other-unit"
               roots: (list (fixture-path "other-unit-tests.ss"))
               files: (list (fixture-path "gamma-test.ss"))))
             (project
              (testing-project
               name: "multi-gxtest"
               suites: (list +testing-suite+ other-suite)))
             (receipt
              (testing-run-project
               project
               (list (fixture-path "alpha-test.ss"))
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")))

    (test-case "project run selects only the matching scenario suite"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               (list "poo-construction-performance")
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'scenario-suite)))

    (test-case "project run reports unknown incremental scopes"
      (let (receipt
            (testing-run-project
             +testing-project+
             (list "unknown-scope")
             fake-run-files))
        (check (testing-receipt-ok? receipt) => #f)
        (check (testing-receipt-detail receipt 'reason)
               => 'no-selected-suites)))

    (test-case "complex upstream build file scope does not widen"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((selected (fixture-path "alpha-test.ss"))
               (receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list selected)
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "unit")
          (check (testing-receipt-files suite-receipt)
                 => (list selected))
          (check (reverse runs)
                 => (list (list selected))))))

    (test-case "complex upstream build manifest root stays in its suite"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((root (fixture-path "integration-tests.ss"))
               (gamma (fixture-path "gamma-test.ss"))
               (delta (fixture-path "delta-test.ss"))
               (receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list root)
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "integration")
          (check (testing-receipt-files suite-receipt)
                 => (list gamma delta))
          (check (reverse runs)
                 => (list (list gamma delta))))))

    (test-case "complex upstream build scenario id does not run gxtest suites"
      (let (runs [])
        (def (record-run files)
          (set! runs (cons files runs))
          0)
        (let* ((receipt
                (testing-run-project
                 +upstream-build-improvement-project+
                 (list "poo-real-dashboard-workflow-performance")
                 record-run))
               (children (testing-receipt-children receipt))
               (suite-receipt (car children)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref suite-receipt 'suite)
                 => "policy-scenarios-complex")
          (check (testing-receipt-files suite-receipt)
                 => (list "t/scenarios/policy/poo-real-dashboard-workflow-performance"))
          (check runs => []))))

    (test-case "downstream build enables improvement scenarios through testing config"
      (testing-build-reset! +downstream-improvement-build+)
      (let* ((receipt
              (testing-build-main
               +downstream-improvement-build+
               ["poo-construction-performance"]))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children))
             (delegate-phase
              (testing-test-phase suite-receipt 'delegate-policy))
             (repair-guidance
              (testing-receipt-detail delegate-phase 'repairGuidance))
             (batch-receipt (car (testing-receipt-children suite-receipt)))
             (scenario-receipt
              (car (testing-receipt-children batch-receipt)))
             (scenario-details
              (testing-receipt-details scenario-receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "improvement-scenarios")
        (check (testing-receipt-files suite-receipt)
               => ["./t/scenarios/policy/poo-construction-performance"])
        (check (testing-build-gxtest-runs +downstream-improvement-build+)
               => [])
        (check (testing-build-scenario-runs +downstream-improvement-build+)
               => ["poo-construction-performance"])
        (check (testing-details-ref scenario-details 'downstreamRepairTarget)
               => "poo-flow")
        (check (testing-details-ref scenario-details 'idiom)
               => "native-poo-construction")
        (check (testing-details-ref scenario-details 'nextRepairAction)
               => "apply the native POO construction idiom to the downstream object builder")
        (check (testing-details-ref (car repair-guidance) 'id)
               => "poo-construction-performance")
        (check (testing-details-ref (car repair-guidance) 'expectedRepair)
               => "preserve native POO object syntax while optimizing runner mechanics")))

    (test-case "complex upstream build hot path has a benchmark gate"
      (check (benchmark-contract-valid/root?
              +upstream-build-improvement-benchmark-root+)
             => #t)
      (let (bench
            (benchmark-contract-run/root
             +upstream-build-improvement-benchmark-root+
             (lambda ()
               (let (file (fixture-path "alpha-test.ss"))
                 (testing-run-project
                  +upstream-build-improvement-project+
                  (list file)
                  fake-run-files)))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))

    (test-case "downstream build.ss loads testing framework API"
      (testing-build-reset! downstream-testing-project)
      (let* ((file (downstream-testing-path "t/unit-a-test.ss"))
             (receipt (downstream-testing-main (list file)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-object-ref suite-receipt 'suite)
               => "unit")
        (check (testing-receipt-files suite-receipt)
               => (list file))
        (check (testing-build-gxtest-runs downstream-testing-project)
               => (list (list file)))))

    (test-case "downstream build.ss manifest root stays incremental"
      (testing-build-reset! downstream-testing-project)
      (let* ((root (downstream-testing-path "t/unit-tests.ss"))
             (unit-a (downstream-testing-path "t/unit-a-test.ss"))
             (unit-b (downstream-testing-path "t/unit-b-test.ss"))
             (receipt (downstream-testing-main (list root)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "unit")
        (check (testing-receipt-files suite-receipt)
               => (list unit-a unit-b))
        (check (testing-build-gxtest-runs downstream-testing-project)
               => (list (list unit-a unit-b)))))

    (test-case "downstream build.ss scenario id does not run gxtest"
      (testing-build-reset! downstream-testing-project)
      (let* ((receipt
              (downstream-testing-main
               (list "style-large-object")))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "policy")
        (check (testing-receipt-files suite-receipt)
               => (list (downstream-testing-path
                         "policy-scenarios/style-large-object")))
        (check (testing-build-gxtest-runs downstream-testing-project) => [])
        (check (testing-build-scenario-runs downstream-testing-project)
               => (list "style-large-object"))))

    (test-case "downstream build.ss scenario owns a benchmark gate"
      (check (benchmark-contract-valid/root?
             +downstream-api-loading-scenario-root+)
             => #t)
      (testing-build-reset! downstream-testing-project)
      (let (bench
            (benchmark-contract-run/root
             +downstream-api-loading-scenario-root+
             (lambda ()
               (downstream-testing-main
                (list (downstream-testing-path "t/unit-a-test.ss"))))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))

    (test-case "marlin speed trap explicit file stays single-suite"
      (testing-build-reset! marlin-speed-project)
      (let* ((file (marlin-speed-path "t/config-interface-test.ss"))
             (receipt (marlin-speed-main (list file)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "config-interface")
        (check (testing-receipt-files suite-receipt)
               => (list file))
        (check (testing-build-gxtest-runs marlin-speed-project)
               => (list (list file)))))

    (test-case "marlin speed trap manifest root does not pull policy scope"
      (testing-build-reset! marlin-speed-project)
      (let* ((root (marlin-speed-path "t/deck-runtime-tests.ss"))
             (condition (marlin-speed-path
                         "t/deck-runtime-condition-policy-test.ss"))
             (strategy (marlin-speed-path
                        "t/deck-runtime-strategy-test.ss"))
             (receipt (marlin-speed-main (list root)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "deck-runtime")
        (check (testing-receipt-files suite-receipt)
               => (list condition strategy))
        (check (testing-build-gxtest-runs marlin-speed-project)
               => (list (list condition strategy)))
        (check (testing-build-scenario-runs marlin-speed-project) => [])))

    (test-case "marlin speed trap scenario id does not run gxtest-main"
      (testing-build-reset! marlin-speed-project)
      (let* ((receipt (marlin-speed-main (list "large-config-object")))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref suite-receipt 'suite)
               => "policy-scenarios")
        (check (testing-receipt-files suite-receipt)
               => (list (marlin-speed-path
                         "policy-scenarios/large-config-object")))
        (check (testing-build-gxtest-runs marlin-speed-project) => [])
        (check (testing-build-scenario-runs marlin-speed-project)
               => (list "large-config-object"))))

    (test-case "marlin speed trap owns testing optimization metric"
      (check (benchmark-contract-valid/root?
             +marlin-speed-trap-scenario-root+)
             => #t)
      (testing-build-reset! marlin-speed-project)
      (let (bench
            (benchmark-contract-run/root
             +marlin-speed-trap-scenario-root+
             (lambda ()
                (marlin-speed-main
                (list (marlin-speed-path "t/config-interface-test.ss"))))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))

    (test-case "upstream gxtest delegation selects files before delegate execution"
      (testing-build-reset! upstream-gxtest-project)
      (let* ((file (upstream-gxtest-path "t/alpha-test.ss"))
             (selection (testing-build-select upstream-gxtest-project (list file)))
             (suites (testing-selection-suites selection))
             (receipt (upstream-gxtest-main (list file)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #t)
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "upstream")
        (check (testing-receipt-ok? receipt) => #t)
        (check (testing-receipt-files suite-receipt) => (list file))
        (check (testing-build-gxtest-runs upstream-gxtest-project)
               => (list (list file)))))

    (test-case "upstream gxtest delegation keeps manifest expansion in one suite"
      (testing-build-reset! upstream-gxtest-project)
      (let* ((root (upstream-gxtest-path "t/upstream-tests.ss"))
             (alpha (upstream-gxtest-path "t/alpha-test.ss"))
             (beta (upstream-gxtest-path "t/beta-test.ss"))
             (receipt (upstream-gxtest-main (list root)))
             (children (testing-receipt-children receipt))
             (suite-receipt (car children)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-receipt-files suite-receipt)
               => (list alpha beta))
        (check (testing-build-gxtest-runs upstream-gxtest-project)
               => (list (list alpha beta)))))

    (test-case "upstream gxtest delegate owns suite and setup cleanup discovery"
      (let* ((alpha (upstream-gxtest-path "t/alpha-test.ss"))
             (symbols (gxtest-file-exported-symbols alpha)))
        (check (member 'test-setup! symbols) ? true)
        (check (member 'test-cleanup! symbols) ? true)
        (check (member 'alpha-test symbols) ? true)
        (check (gxtest-file-exported-suite alpha)
               => 'alpha-test)))

    (test-case "upstream gxtest delegation owns a benchmark gate"
      (check (benchmark-contract-valid/root?
             +upstream-gxtest-delegation-scenario-root+)
             => #t)
      (testing-build-reset! upstream-gxtest-project)
      (let (bench
            (benchmark-contract-run/root
             +upstream-gxtest-delegation-scenario-root+
             (lambda ()
               (upstream-gxtest-main
                (list (upstream-gxtest-path "t/alpha-test.ss"))))))
        (check (benchmark-contract-receipt-pass? bench) => #t)))

    (test-case "performance gate remains a benchmark.ss gate under testing"
      (check (benchmark-contract-valid/root? +testing-benchmark-root+) => #t)
      (check (testing-performance-gate-valid?
              (car (testing-suite-gates +testing-suite+)))
             => #t))))
