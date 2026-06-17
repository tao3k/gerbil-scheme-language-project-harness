(policyScenario
 (id "dependency-manual-object-adapter")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R017"
    "src/orders/dict.ss"
    "src/orders/dict.ss:9-20"
    "dependency adapter OrderDict. wraps :clan/pure/dict/orderdict but is missing manual-object-encoding-risk; lift dependency primitives into a thin typed protocol adapter and add a contract witness"))
  (adapter
   ((styleGuide "dependency-protocol-adapter")
    (dependency ":clan/pure/dict/orderdict")
    (quality "partial")
    (manualObjectEncodingRisk "manual-object-encoding-risk")
    (genericContractWitnessKind "table-protocol-contract-witness")
    (contractWitnessPresent #t)
    (contractWitnessKind "generic-contract-test")
    (missingEvidence
     ("manual-object-encoding-risk"))
    (qualityFacets
     ("dependency-protocol-adapter"
      "precise-only-in-import"
      "declared-protocol-or-type-surface"
      "protocol-slot-surface"
      "table-method-surface"
      "typed-validation-boundary"
      "conversion-boundary"
      "equality-boundary"
      "thin-wrapper-over-dependency-api"
      "protocol-derived-capability"
      "table-derived-capability"
      "list-derived-capability"
      "sexp-derived-capability"
      "poo-define-type-adapter"))
    (derivedCapabilities
     ("table"
      "list"
      "sexp"))
    (adapterRepairShape
     "query the search-forwarded rationaldict adapter example first, then use R017 guide --code for local parser/policy repair code; follow exact only-in dependency import -> define-type protocol surface -> Key/Value/validation/serialization/equality slots -> generic contract tests")
    (agentRepairStandard
     "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value/validate/serialization/equality slots, behavior on protocol slots, derived table/set/list/sexp/json/marshal capabilities when slots exist, and generic contract tests"))))
 (after
  (r017Findings ())))
