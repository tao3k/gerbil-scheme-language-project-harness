(compareSearch
 (namespace "compare")
 (authority "active-runtime-vs-documented")
 (evidenceGrade "fact")
 (quality "verified")
 (query "compile v0.18 v0.19 nightly")
 (comparisons
  ((comparison
    (id "compile-target-runtime-source")
    (summary "Compile-version questions must resolve the active gxi/gsc first, then acquire the matching source checkout before answering syntax or macro usage.")
    (evidenceGrade "fact")
    (witness "active-runtime-selects-versioned-source-before-compile-guidance")
    (next "search runtime-source macro sugar module-sugar")
    (left
     (kind "active-runtime")
     (gxiResolved #t)
     (gscResolved #t))
    (right
     (kind "requested-compile-target")
     (source "agent-request-or-user-claim")
     (status "non-authoritative-until-runtime-source-acquired")
     (targetVersions ("v0.18" "v0.19" "nightly"))
     (compileMode "active-gxi-gsc-first")
     (stateNamespace "runtime-source/gerbil-scheme"))
    (result "active-runtime-source-checkout-required-before-version-guidance")
    (agentScenario "agent-needs-to-answer-gerbil-compile-or-syntax-question-for-a-requested-version")
    (intent "compare-requested-compile-version-against-active-runtime-and-route-to-versioned-source")
    (failureCases
     ((failureCase
       (id "requested-version-wins-without-runtime")
       (risk "agent-answers-for-v0-18-v0-19-or-nightly-without-checking-active-gxi")
       (correction "query-compare-compile-target-runtime-source-before-version-sensitive-guidance"))
      (failureCase
       (id "compile-source-mismatch")
       (risk "agent-uses syntax or macro examples from a different compiler source tree")
       (correction "route-to-runtime-source-checkout-derived-from-active-runtime-version"))
      (failureCase
       (id "nightly-assumption")
       (risk "agent-treats-nightly-features-as-available-on-the-active-stable-runtime")
       (correction "verify-active-gxi-gsc-and-matching-source-before-nightly-feature-guidance"))))
    (qualitySignals ("active-runtime-fact"
                     "compile-version-query"
                     "version-matched-source"
                     "no-memory"
                     "source-checkout-required")))))
 (missing ())
 (witness "active-runtime-selects-versioned-source-before-compile-guidance")
 (next "search runtime-source macro sugar module-sugar"))
