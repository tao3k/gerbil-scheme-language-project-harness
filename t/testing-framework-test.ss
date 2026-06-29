;;; -*- Gerbil -*-
;;; Top-level smoke entry for the POO-shaped testing framework.

(import :std/test
        :testing/model
        :testing/framework)

(export testing-framework-test)

(def (fake-run-files files)
  0)

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
      (check (testing-object-kind +testing-project+) => 'testing-project)
      (check (testing-project-name +testing-project+) => "poo-flow-like")
      (check (testing-object-kind +testing-suite+) => 'gxtest-suite)
      (check (testing-suite-name +testing-suite+) => "unit"))

    (test-case "suite batches files without downstream runner code"
      (check (testing-batches
              ["a.ss" "b.ss" "c.ss"]
              2)
             => '(("a.ss" "b.ss") ("c.ss"))))

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
               => 'gxtest-suite)))))
