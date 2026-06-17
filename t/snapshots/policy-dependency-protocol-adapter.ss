(policyScenario
 (id "dependency-protocol-adapter")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R017"
    "src/orders/dict.ss"
    "src/orders/dict.ss:9-14"
    "dependency adapter OrderDict. wraps :clan/pure/dict/orderdict but is missing protocol-slot-surface,typed-validation-boundary,conversion-boundary,equality-boundary,generic-contract-test-witness; lift dependency primitives into a thin typed protocol adapter and add a contract witness"))
  (adapter
   ((styleGuide "dependency-protocol-adapter")
    (dependency ":clan/pure/dict/orderdict")
    (quality "weak")
    (manualObjectEncodingRisk "none")
    (genericContractWitnessKind "table-protocol-contract-witness")
    (contractWitnessPresent #f)
    (contractWitnessKind "missing")
    (missingEvidence
     ("protocol-slot-surface"
      "typed-validation-boundary"
      "conversion-boundary"
      "equality-boundary"
      "generic-contract-test-witness"))
    (qualityFacets
     ("dependency-protocol-adapter"
      "precise-only-in-import"
      "declared-protocol-or-type-surface"
      "table-method-surface"
      "thin-wrapper-over-dependency-api"
      "protocol-derived-capability"
      "table-derived-capability"
      "list-derived-capability"
      "no-manual-object-encoding"
      "poo-define-type-adapter"))
    (derivedCapabilities
     ("table"
      "list"))
    (adapterRepairShape
     "query the search-forwarded rationaldict adapter example first, then use R017 guide --code for local parser/policy repair code; follow exact only-in dependency import -> define-type protocol surface -> Key/Value/validation/serialization/equality slots -> generic contract tests")
    (agentRepairStandard
     "current dependency already provides the bottom data structure; do not hand-write loose hash/alist objects. Build a typed protocol adapter: precise only-in imports for primitives, define-type Key/Value/validate/serialization/equality slots, behavior on protocol slots, derived table/set/list/sexp/json/marshal capabilities when slots exist, and generic contract tests"))))
 (after
  (r017Findings ())))
