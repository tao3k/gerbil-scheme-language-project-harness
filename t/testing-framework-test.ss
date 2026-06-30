;;; -*- Gerbil -*-
;;; Top-level smoke entry for the POO-shaped testing framework.

(import :std/test
        (only-in :clan/poo/object object? .ref .slot?)
        :testing/model
        :testing/framework
        :testing/build
        "./scenarios/policy/downstream-testing-framework-api-loading/input/build.ss"
        "./scenarios/policy/marlin-testing-speed-trap/expected/build.ss")

(export testing-framework-test)

;; : (-> (List Path) Integer)
(def (fake-run-files files)
  0)

;; : (-> Path Path)
(def (downstream-testing-path relative)
  (testing-build-path downstream-testing-project relative))

;; : (-> Path Path)
(def (marlin-speed-path relative)
  (testing-build-path marlin-speed-project relative))

(def +testing-suite+
  (gxtest-suite
   name: "unit"
   roots: ["t/fixtures/testing-framework"]
   files: ["t/fixtures/testing-framework/alpha-test.ss"
           "t/fixtures/testing-framework/beta-test.ss"]
   batch-size: 1))

(def +testing-project+
  (testing-project
   name: "poo-flow-like"
   suites: [+testing-suite+]
   roots: ["t/fixtures/testing-framework"]))

(def testing-framework-test
  (test-suite "gerbil scheme POO-shaped testing framework smoke"
    (test-case "testing project and suite are user-facing POO-shaped objects"
      (check (object? +testing-project+) => #t)
      (check (.slot? +testing-project+ 'name) => #t)
      (check (.ref +testing-project+ 'name) => "poo-flow-like")
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (object? +testing-suite+) => #t)
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit"))

    (test-case "suite batches files without downstream runner code"
      (check (testing-batches
              ["a.ss" "b.ss" "c.ss"]
              2)
             => '(("a.ss" "b.ss") ("c.ss"))))

    (test-case "suite split exposes batch rest without second traversal"
      (let-values (((batch rest)
                    (testing-split-batch
                     ["a.ss" "b.ss" "c.ss"]
                     2)))
        (check batch => ["a.ss" "b.ss"])
        (check rest => ["c.ss"])))

    (test-case "project run selects matching gxtest files"
      (let* ((receipt
              (testing-run-project
               +testing-project+
               ["t/fixtures/testing-framework/alpha-test.ss"]
               fake-run-files))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'receiptKind)
               => 'gxtest-suite)))

    (test-case "project selection is POO-native"
      (let* ((selection
              (testing-select-project
               +testing-project+
               ["t/fixtures/testing-framework/alpha-test.ss"]))
             (suites (testing-selection-suites selection)))
        (check (object? selection) => #t)
        (check (testing-object-kind selection) => 'testing-selection)
        (check (testing-selection-ok? selection) => #t)
        (check (length suites) => 1)
        (check (testing-suite-name (car suites)) => "unit")))

    (test-case "testing build maps package-prefixed symbol imports"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   import-prefix: ":poo-flow/t/"))
        (check (testing-build-import->file
                build
                ':poo-flow/t/cli-test)
               => "./t/cli-test.ss")))

    (test-case "testing build default delegate owns env and policy command shape"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   policy-file: "t/poo-flow-policy-test.ss"
                   scope-env: "POO_FLOW_TEST_FILES"))
        (check (testing-build-gxtest-command
                build
                ["t/unit-a-test.ss"])
               => ["env"
                   "POO_FLOW_TEST_FILES=(\"t/unit-a-test.ss\")"
                   "gxtest"
                   "t/unit-a-test.ss"
                   "t/poo-flow-policy-test.ss"])))

    (test-case "testing build can omit policy file after first delegate batch"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   policy-file: "t/poo-flow-policy-test.ss"
                   scope-env: "POO_FLOW_TEST_FILES"))
        (check (testing-build-gxtest-command
                build
                ["t/unit-b-test.ss"]
                #f)
               => ["env"
                   "POO_FLOW_TEST_FILES=(\"t/unit-b-test.ss\")"
                   "gxtest"
                   "t/unit-b-test.ss"])))

    (test-case "testing build injects loadpath only when explicitly configured"
      (let (build (testing-build
                   name: "poo-flow"
                   root: "."
                   loadpath: ".:.gerbil/lib"))
        (check (testing-build-gxtest-command
                build
                ["t/unit-a-test.ss"])
               => ["env"
                   "GERBIL_LOADPATH=.:.gerbil/lib"
                   "gxtest"
                   "t/unit-a-test.ss"])))

    (test-case "testing build rejects explicit files outside declared suites"
      (let* ((receipt
              (testing-build-main
               downstream-testing-project
               ["t/does-not-exist-test.ss"]
               (testing-build-dry-gxtest-runner
                downstream-testing-project))))
        (check (testing-receipt-ok? receipt) => #f)
        (check (testing-object-ref receipt 'status) => 'failed)))

    (test-case "testing build accepts relative files without dot-prefix drift"
      (testing-build-reset! downstream-testing-project)
      (let* ((receipt
              (downstream-testing-main
               ["t/scenarios/policy/downstream-testing-framework-api-loading/input/t/unit-a-test.ss"]
               (testing-build-dry-gxtest-runner
                downstream-testing-project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")))

    (test-case "downstream build.ss loads public testing API"
      (testing-build-reset! downstream-testing-project)
      (let* ((file (downstream-testing-path "t/unit-a-test.ss"))
             (receipt (downstream-testing-main
                       (list file)
                       (testing-build-dry-gxtest-runner
                        downstream-testing-project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "unit")
        (check (testing-build-gxtest-runs downstream-testing-project)
               => (list (list file)))))

    (test-case "downstream build.ss can delegate to a real gxtest runner"
      (testing-build-reset! downstream-testing-project)
      (let ((runs (vector []))
            (file (downstream-testing-path "t/unit-a-test.ss")))
        (let* ((runner
                (lambda (files)
                  (vector-set! runs 0 (cons files (vector-ref runs 0)))
                  0))
               (receipt (downstream-testing-main (list file) runner))
               (children (testing-receipt-children receipt)))
          (check (testing-receipt-ok? receipt) => #t)
          (check (length children) => 1)
          (check (testing-object-ref (car children) 'suite)
                 => "unit")
          (check (reverse (vector-ref runs 0))
                 => (list (list file)))
          (check (testing-build-gxtest-runs downstream-testing-project)
                 => []))))

    (test-case "marlin-like build speed trap stays incremental"
      (testing-build-reset! marlin-speed-project)
      (let* ((file (marlin-speed-path "t/config-interface-test.ss"))
             (receipt (marlin-speed-main
                       (list file)
                       (testing-build-dry-gxtest-runner
                        marlin-speed-project)))
             (children (testing-receipt-children receipt)))
        (check (testing-receipt-ok? receipt) => #t)
        (check (length children) => 1)
        (check (testing-object-ref (car children) 'suite)
               => "config-interface")
        (check (testing-build-gxtest-runs marlin-speed-project)
               => (list (list file)))))))
