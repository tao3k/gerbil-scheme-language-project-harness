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
    (test-case "search owner items skips call collection when limit is zero"
      (check-owner-items-limit-zero-skips-call-collection))
    (test-case "search owner items does not match syntax facts by selected owner path"
      (check-owner-items-query-ignores-selected-owner-path))
    (test-case "search owner items exposes gerbil.pkg package facts"
      (check-owner-items-gerbil-package-facts))
    (test-case "search owner items emits structural selector query next command"
      (check-owner-items-definition-next-command-uses-structural-selector))
    (test-case "search owner items fast entrypoint stays lightweight"
      (check-owner-items-fast-entrypoint-stays-light))
    (test-case "search guide fast entrypoint stays lightweight"
      (check-search-guide-fast-entrypoint-stays-light))
    (test-case "search guide static section data loads without runtime POO"
      (check-guide-sections-static-data-loads))))
