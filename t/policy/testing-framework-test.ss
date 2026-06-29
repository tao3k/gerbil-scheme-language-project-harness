;;; -*- Gerbil -*-
;;; POO-shaped testing framework contracts.

(import :gerbil/gambit
        :std/test
        :testing/model
        :testing/framework
        :benchmark/framework)

(export testing-framework-test)

(def +testing-fixture-root+
  "t/fixtures/testing-framework")

(def +testing-benchmark-root+
  "t/benchmarks/testing-framework")

(def (fixture-path file)
  (path-expand file +testing-fixture-root+))

(def (fixture-import->file import)
  (path-expand import +testing-fixture-root+))

(def (fake-run-files files)
  0)

(def (fake-run-scenario scenario)
  scenario)

(def +fake-native-poo-testing-project+
  '((name . "native-poo-project")
    (suites . [])
    (roots . ("t"))
    (batchSize . 2)
    (receiptPrefix . "native-poo")))

(def (fake-native-poo-ref object slot)
  (cdr (assq slot object)))

(def +testing-project-from-native-poo+
  (testing-native-poo-object
   'testing-project
   +fake-native-poo-testing-project+
   fake-native-poo-ref
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

(def +testing-project+
  (testing-project
   name: "poo-flow-like"
   suites: (list +testing-suite+ +testing-scenario-suite+)
   roots: (list +testing-fixture-root+)
   receipt-prefix: "gslph-testing"))

(def testing-framework-test
  (test-suite "gerbil scheme POO-shaped testing framework"
    (test-case "testing project is a user-facing POO-shaped object"
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit")
      (check (testing-object-kind +testing-scenario-suite+) => 'scenario-suite)
      (check (testing-suite-name +testing-scenario-suite+) => "policy-scenarios"))

    (test-case "native POO projection enters the same testing model"
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
        (check (cdr (assq 'id (testing-receipt-details scenario-receipt)))
               => "poo-construction-performance")))

    (test-case "project run manages gxtest and scenario suites together"
      (let (receipt
            (testing-run-project
             +testing-project+
             []
             fake-run-files))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length (testing-receipt-children receipt)) => 2)))

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
        (check (cdr (assq 'reason (testing-receipt-details receipt)))
               => 'no-selected-suites)))

    (test-case "performance gate remains a benchmark.ss gate under testing"
      (check (benchmark-contract-valid/root? +testing-benchmark-root+) => #t)
      (check (testing-performance-gate-valid?
              (car (testing-suite-gates +testing-suite+)))
             => #t))))
