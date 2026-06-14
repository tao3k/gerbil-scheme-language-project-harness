;;; -*- Gerbil -*-

(import :parser/facade
        :policy/facade
        :snapshot/facade
        :std/test
        :unit/policy/poo-scenarios)

(export check-policy-snapshot-fixtures)
;; Snapshot
(def (downstream-poo-agent-policy-snapshot)
  (write-downstream-poo-agent-project ".run/snapshot-policy-downstream-poo-agent")
  (let* ((index (collect-project ".run/snapshot-policy-downstream-poo-agent"))
         (findings (run-agent-policy index)))
    (list 'policyScenario
          (list 'id "downstream-poo-agent")
          (list 'findings (map finding-snapshot findings)))))
;; Snapshot
(def (check-policy-snapshot-fixtures)
  (check (downstream-poo-agent-policy-snapshot)
         => (snapshot-load "t/snapshots/policy-downstream-poo-agent.ss")))
