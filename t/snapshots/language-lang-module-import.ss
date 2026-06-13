(languageEvidenceSearch
 (namespace "lang")
 (authority "language-rules")
 (evidenceGrade "fact")
 (query "rename-in")
 (facts
  ((languageEvidenceFact
    (id "module-import")
    (summary "Gerbil module imports are resolved through the active load path and module-sugar import/export sets; project guidance must include runtime source when import set syntax matters.")
    (evidenceGrade "fact")
    (witness "runtime-source-module-sugar-import-export-sets")
    (next "search runtime-source module-sugar")
    (details
     (rule "module-import")
     (authority "language-rules")
     (runtimeSourceSelector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss"))
    (selectors
     ((selector
       (role "import-filter")
       (symbol "only-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"))
      (selector
       (role "import-filter")
       (symbol "except-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#except-in"))
      (selector
       (role "import-rename")
       (symbol "rename-in")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in"))
      (selector
       (role "phase-import")
       (symbol "for-syntax")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#for-syntax"))
      (selector
       (role "export-rename")
       (symbol "rename-out")
       (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out"))))
    (agentScenario "agent-does-not-know-gerbil-module-load-path-resolution")
    (intent "query-active-load-path-and-module-sugar-source-before-adding-imports-or-exports")
    (failureCases
     ((failureCase
       (id "missing-load-path")
       (risk "agent-adds-import-that-current-gxi-cannot-resolve")
       (correction "query-search-env-load-path-before-editing-imports"))
      (failureCase
       (id "racket-require-assumption")
       (risk "agent-uses-racket-require-forms-in-gerbil-imports")
       (correction "use-gerbil-module-sugar-selectors-for-only-in-except-in-rename-in"))
      (failureCase
       (id "unchecked-rename-in")
       (risk "agent-renames-an-identifier-that-is-not-in-the-import-set")
       (correction "use-rename-in-witness-that-checks-identifier-membership"))
      (failureCase
       (id "rename-out-confusion")
       (risk "agent-confuses-import-renaming-with-export-renaming")
       (correction "use-rename-in-for-imports-and-rename-out-for-exports"))))
    (qualitySignals ("load-path-policy"
                     "runtime-route"
                     "module-sugar-source"
                     "import-set-witness"
                     "export-set-witness")))))
 (next "search runtime-source module-sugar"))
