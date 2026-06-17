(policyScenario
 (id "macro-controlled-helper")
 (before
  (finding
   ("GERBIL-SCHEME-AGENT-R011"
    "src/macros/core.ss"
    "src/macros/core.ss:3-4"
    "macro with-order-field needs runtime-source or macro-expansion witness before agent edits; query search runtime-source macro sugar module-sugar and record gerbil.pkg macro-governance witness"))
  (guidance
   ((macro "with-order-field")
    (phase "syntax")
    (hygienic #t)
    (qualityFacets ("hygienic-macro" "syntax-template-witness"))
    (allowedMacroShape
     ("thin syntax bridge"
      "syntax-case transformer with local parsing helpers"
      "defrule/defrules wrapper over visible runtime behavior"
      "for-syntax helper with precise imports"))
    (runtimeSelectorFormat "gerbil-runtime-source://<source-path>#<symbol>")
    (styleSourcePattern "gerbil-utils-controlled-macro-helper")
    (styleSourceOwners
     ("gerbil-utils/syntax.ss#defsyntax-stx"
      "gerbil-utils/syntax.ss#syntax-case"
      "gerbil-utils/base.ss#nest"
      "gerbil-utils/base.ss#left-to-right"))
    (escapeConstraint
     "do not weaken macro-governance from a source macro edit; update gerbil.pkg only with a clear explanation and witness"))))
 (after
  (r011Findings ())
  (macroFact
   ((macro "with-order-field")
    (transformer "syntax-case")
    (phase "syntax")
    (hygienic #t)
    (qualityFacets
     ("hygienic-macro" "syntax-case-transformer" "syntax-template-witness"))))))
