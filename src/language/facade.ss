;;; -*- Gerbil -*-
;;; Stable facade for Gerbil language/runtime/std evidence.

(import :language/evidence
        :language/compare)

(export runtime-bin
        evidence-fact
        active-runtime-facts
        runtime-source-facts
        language-rule-facts
        standard-library-facts
        compare-facts
        matching-compare-facts
        compare-fact-json
        hygienic-macro-pattern-evidence
        hygienic-macro-pattern-query?
        hygienic-macro-minimal-forms
        hygienic-macro-failure-cases)
