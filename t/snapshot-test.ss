;;; -*- Gerbil -*-
(import :std/test
        :unit/evidence-graph
        :unit/search/prime-packet
        :unit/snapshot/check-report
        :unit/snapshot/compare
        :unit/snapshot/extension
        :unit/snapshot/language-evidence
        :unit/snapshot/parser
        :unit/snapshot/policy
        :unit/snapshot/runtime-source
        :unit/snapshot/self-apply)
(export snapshot-test)

(def snapshot-test
  (test-suite "gerbil scheme harness snapshots"
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
      (check-compare-snapshot-fixtures))
    (test-case "parser snapshot fixtures cover complex native syntax facts"
      (check-parser-complex-native-facts-snapshot))
    (test-case "policy snapshot fixtures cover downstream POO agent drift"
      (check-policy-snapshot-fixtures))
    (test-case "check report snapshot uses stable unit interface"
      (check-empty-check-report-snapshot))
    (test-case "self apply findings snapshot is an explicit invariant"
      (check-empty-self-apply-findings-snapshot))
    (test-case "search prime json exposes required schema envelope"
      (check-search-prime-required-envelope))
    (test-case "search prime json carries semantic fact graph"
      (check-search-prime-semantic-fact-graph))
    (test-case "evidence graph json exposes required schema envelope"
      (check-evidence-graph-packet))
    (test-case "evidence analyze emits graph turbo request"
      (check-evidence-analysis-request-packet))
    (test-case "registry and guide advertise evidence commands"
      (check-evidence-registry-and-guide))))
