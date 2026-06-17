;;; -*- Gerbil -*-
;;; Evidence graph snapshot checks.

(import :std/test
        :unit/evidence-graph)

(export snapshot-evidence-test)

;; SnapshotSuite
(def snapshot-evidence-test
  (test-suite "evidence graph snapshots"
    (test-case "evidence graph json exposes required schema envelope"
      (check-evidence-graph-packet))
    (test-case "evidence analyze emits graph turbo request"
      (check-evidence-analysis-request-packet))
    (test-case "registry and guide advertise evidence commands"
      (check-evidence-registry-and-guide))))

