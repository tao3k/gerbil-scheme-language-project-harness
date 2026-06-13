(runtimeSourceSearch
 (namespace "runtime-source")
 (authority "runtime-version-source")
 (evidenceGrade "fact")
 (quality "version-matched-source-plan")
 (query "writeenv printer hook")
 (facts
  ((runtimeSourceFact
    (id "gerbil-runtime-writeenv-source")
    (summary "Gerbil writeenv and printer hook guidance must come from the active runtime source before POO :wr roundtrip claims.")
    (evidenceGrade "fact")
    (witness "active-runtime-version-to-writeenv-source-acquisition-plan")
    (sourceRef
     (kind "runtime-version-source")
     (manager "git")
     (repository "https://git.cons.io/mighty-gerbils/gerbil")
     (checkoutPolicy "exact-tag-from-active-runtime")
     (statePathPolicy "asp-state-managed")
     (selectorScheme "runtime-source-owner-selector"))
    (acquisition
     (owner "asp")
     (operation "clone-or-fetch-checkout-index")
     (stateNamespace "runtime-source/gerbil-scheme")
     (indexOwner "asp-structural-index"))
    (selectors
     ((selector
       (role "writeenv-builtin")
       (symbol "writeenv")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"))
      (selector
       (role "core-writeenv-binding")
       (symbol "writeenv")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"))
      (selector
       (role "runtime-write-object-owner")
       (symbol "write-object")
       (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"))))
    (agentScenario "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims")
    (intent "query-versioned-runtime-writeenv-and-write-object-source-before-promoting-poo-io-to-verified")
    (failureCases
     ((failureCase
       (id "memory-writeenv-answer")
       (risk "agent-answers-writeenv-or-printer-hook-behavior-from-training-memory")
       (correction "acquire-active-runtime-source-and-query-writeenv-selectors"))
      (failureCase
       (id "poo-writeenv-roundtrip-assumption")
       (risk "agent-promotes-poo-io-pattern-to-verified-without-runtime-writeenv-roundtrip-witness")
       (correction "keep-poo-io-partial-until-runtime-source-backed-roundtrip-witness-exists"))
      (failureCase
       (id "raw-runtime-source-search")
       (risk "agent-clones-gerbil-source-but-searches-it-with-raw-grep")
       (correction "use-asp-managed-runtime-source-index-before-agent-facing-search"))))
    (qualitySignals ("no-memory"
                     "version-matched-source"
                     "asp-state-managed-checkout"
                     "writeenv-source-index-required"
                     "printer-hook-source-required")))))
 (missing ())
 (witness "active-runtime-version-to-writeenv-source-acquisition-plan")
 (next "search runtime-source writeenv printer hook"))
