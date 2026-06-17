;;; -*- Gerbil -*-
;;; Search snapshot checks.

(import :std/test
        :unit/search/prime-packet
        :unit/search/owner-items)

(export snapshot-search-test)

;; SnapshotSuite
(def snapshot-search-test
  (test-suite "search snapshots"
    (test-case "search prime json exposes required schema envelope"
      (check-search-prime-required-envelope))
    (test-case "search prime json carries semantic fact graph"
      (check-search-prime-semantic-fact-graph))
    (test-case "search owner items applies the materialization budget"
      (check-owner-items-limit-budget))
    (test-case "provider launcher keeps owner items on the native inline route"
      (check-provider-launcher-native-fast-route))
    (test-case "search owner items fast entrypoint stays lightweight"
      (check-owner-items-fast-entrypoint-stays-light))
    (test-case "search guide fast entrypoint stays lightweight"
      (check-search-guide-fast-entrypoint-stays-light))))

