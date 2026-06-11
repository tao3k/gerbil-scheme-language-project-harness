;;; -*- Gerbil -*-
(import :std/test
        :unit/search/prime-packet
        :unit/snapshot/check-report
        :unit/snapshot/extension
        :unit/snapshot/self-apply)
(export snapshot-test)

(def snapshot-test
  (test-suite "gerbil scheme harness snapshots"
    (test-case "provider extension snapshot uses schema field names"
      (check-extension-snapshot-schema-fields))
    (test-case "check report snapshot uses stable unit interface"
      (check-empty-check-report-snapshot))
    (test-case "self apply findings snapshot is an explicit invariant"
      (check-empty-self-apply-findings-snapshot))
    (test-case "search prime json exposes required schema envelope"
      (check-search-prime-required-envelope))
    (test-case "search prime json carries semantic fact graph"
      (check-search-prime-semantic-fact-graph))))
