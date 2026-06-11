;;; -*- Gerbil -*-
(import :std/test
        :parser/facade
        :snapshot/facade
        :types/facade)
(export self-apply-test)

(def self-apply-test
  (test-suite "gerbil scheme harness self apply"
    (test-case "current harness findings match snapshot"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (self-apply-findings-snapshot findings))
             (expected (snapshot-load "test/snapshots/self-apply-findings.ss")))
        (check snapshot => expected)))
    (test-case "current harness check report matches snapshot"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (check-report-snapshot index findings))
             (expected (snapshot-load "test/snapshots/self-apply-check-report.ss")))
        (check snapshot => expected)))))
