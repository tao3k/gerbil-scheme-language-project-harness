(runtimeSourceSearch
 (namespace "runtime-source")
 (authority "runtime-version-source")
 (evidenceGrade "fact")
 (quality "version-matched-source-plan")
 (query "macro")
 (facts
  ((runtimeSourceFact
    (id "gerbil-runtime-source")
    (summary "Gerbil language facts must come from a source checkout matched to the active runtime version.")
    (evidenceGrade "fact")
    (witness "active-runtime-version-to-source-acquisition-plan")
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
    (selectors ())
    (agentScenario "agent-needs-gerbil-macro-facts-from-versioned-source")
    (intent "clone-active-runtime-source-before-answering-language-or-macro-usage")
    (failureCases
     ((failureCase
       (id "memory-language-answer")
       (risk "agent-answers-gerbil-language-usage-from-training-memory")
       (correction "acquire-runtime-source-and-search-source-facts"))
      (failureCase
       (id "wrong-runtime-version")
       (risk "agent-uses-source-from-a-different-gerbil-version")
       (correction "checkout-source-tag-derived-from-active-runtime"))
      (failureCase
       (id "unindexed-source-checkout")
       (risk "agent-clones-source-but-searches-it-with-raw-grep")
       (correction "index-checkout-through-asp-before-agent-facing-search"))))
    (qualitySignals ("no-memory"
                     "version-matched-source"
                     "asp-state-managed-checkout"
                     "source-index-required")))))
 (missing ())
 (witness "active-runtime-version-to-source-acquisition-plan")
 (next "search runtime-source macro sugar module-sugar"))
