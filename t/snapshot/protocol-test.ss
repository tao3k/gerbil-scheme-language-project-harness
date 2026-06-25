;;; -*- Gerbil -*-
;;; Protocol snapshot checks.

(import :std/test
        :unit/snapshot/extension-test
        :unit/snapshot/runtime-source
        :unit/snapshot/language-evidence
        :unit/snapshot/compare)

(export snapshot-protocol-test)

;; SnapshotSuite
(def snapshot-protocol-test
  (test-suite "protocol snapshots"
    (test-case "provider extension snapshot uses schema field names"
      (check-extension-snapshot-schema-fields))
    (test-case "provider extension search snapshot uses namespace evidence fields"
      (check-extension-search-snapshot-schema-fields))
    (test-case "pattern search snapshot exposes quality gaps"
      (check-pattern-search-snapshot-quality-fields))
    (test-case "pattern search snapshot captures POO C3 MRO scenario"
      (check-pattern-search-snapshot-c3-mro-fields))
    (test-case "pattern search snapshot captures partial missing evidence"
      (check-pattern-search-snapshot-partial-missing-fields))
    (test-case "pattern search snapshot fixtures cover complex scenarios"
      (check-pattern-search-snapshot-fixtures))
    (test-case "pattern search snapshot fixtures cover source gaps"
      (check-pattern-search-snapshot-source-gap-fixtures))
    (test-case "runtime-source snapshot exposes stable acquisition fields"
      (check-runtime-source-snapshot-fields))
    (test-case "runtime-source snapshot fixtures cover acquisition scenarios"
      (check-runtime-source-snapshot-fixtures))
    (test-case "language evidence snapshot exposes stable fields"
      (check-language-evidence-snapshot-fields))
    (test-case "language evidence snapshot fixtures cover env lang std"
      (check-language-evidence-snapshot-fixtures))
    (test-case "guide and registry snapshot fixtures cover search schemas"
      (check-guide-and-registry-snapshot-fixtures))
    (test-case "compare snapshot exposes active documented runtime fields"
      (check-compare-snapshot-fields))
    (test-case "compare snapshot fixtures cover active documented runtime"
      (check-compare-snapshot-fixtures))))
