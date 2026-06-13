;;; -*- Gerbil -*-
(import :std/test
        :commands/bench
        :parser/facade
        :snapshot/facade
        :std/misc/ports
        (only-in :std/text/json read-json)
        :types/facade)
(export self-apply-test)

(def (bench-json-packet)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status
                  (bench-main ["--json" "--iterations" "1" "--max-total-ms" "60000" "."])))))))
    (check status => 0)
    (call-with-input-string output read-json)))

(def self-apply-test
  (test-suite "gerbil scheme harness self apply"
    (test-case "current harness findings match snapshot"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (self-apply-findings-snapshot findings))
             (expected (snapshot-load "t/snapshots/self-apply-findings.ss")))
        (check snapshot => expected)))
    (test-case "current harness check report matches snapshot"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (check-report-snapshot index findings))
             (expected (snapshot-load "t/snapshots/self-apply-check-report.ss")))
        (check snapshot => expected)))
    (test-case "current harness bench report matches snapshot"
      (let* ((packet (bench-json-packet))
             (snapshot (bench-report-snapshot packet))
             (expected (snapshot-load "t/snapshots/self-apply-bench-report.ss")))
        (check snapshot => expected)))))
