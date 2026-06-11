;;; -*- Gerbil -*-
(import :std/test
        :parser/facade
        :types/facade)
(export self-apply-test)

(def self-apply-test
  (test-suite "gerbil scheme harness self apply"
    (test-case "current harness findings match snapshot"
      (let* ((index (collect-project "."))
             (findings (map finding->snapshot (run-type-checks index)))
             (expected (load-snapshot "test/snapshots/self-apply-findings.scm")))
        (check findings => expected)))))

(def (finding->snapshot finding)
  [(type-finding-rule-id finding)
   (type-finding-path finding)
   (type-finding-selector finding)
   (type-finding-message finding)])

(def (load-snapshot path)
  (call-with-input-file path read))
