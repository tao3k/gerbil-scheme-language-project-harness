;;; -*- Gerbil -*-
;;; Macro and POO typeclass style signals for R013 Gerbil guidance.

(import :parser/facade
        (only-in :policy/agent-style-gerbil-signal-support
                 typed-combinator-style-facts->quality-facet
                 typed-combinator-style-facts->signals
                 typed-combinator-style-facts->targets)
        (only-in :std/sugar filter ormap))

(export typed-combinator-style-macro-family-quality-facets
        typed-combinator-style-macro-family-signals
        typed-combinator-style-macro-family-targets
        typed-combinator-style-controlled-macro-quality-facets
        typed-combinator-style-controlled-macro-syntax-signals
        typed-combinator-style-controlled-macro-targets
        typed-combinator-style-typeclass-quality-facets
        typed-combinator-style-typeclass-algebra-signals
        typed-combinator-style-typeclass-algebra-targets
        typed-combinator-style-typeclass-poo-forms)

;;; Macro-family facts catch repeated same-prefix thin macro wrappers before
;;; policy turns them into copy-pasted syntax APIs.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-macro-family-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (source-file-macro-family-facts file)
   "macro-family-boundary"))

;;; Signal boundary:
;;; - Family guidance is emitted only from parser-owned macro-family facts.
;;; - It does not make downstream projects depend on poo-flow or gerbil-utils.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-macro-family-signals file)
  (typed-combinator-style-facts->signals
   (source-file-macro-family-facts file)
   ["collapse repeated same-prefix macro wrappers into one macro family helper"
    "prefer a syntax-rules family table or stx helper over copy-pasted defrules"
    "split shared macro parsing from syntax generation when the family has more than one expansion shape"
    "keep runtime semantics in ordinary helpers and make macro expansion a thin surface"]))

;;; Target projection names the macro family prefix, not each repeated wrapper.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-macro-family-targets file)
  (typed-combinator-style-facts->targets
   (source-file-macro-family-facts file)
   macro-family-fact-prefix))

;;; Macro facts already classify syntax owners.  R013 exposes the engineering
;;; steering so macro-heavy files use upstream macro-library idioms without
;;; inventing a project-specific DSL.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-controlled-macro-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (source-file-macros file)
   "controlled-macro-syntax-boundary"))

;;; Signal boundary:
;;; - Controlled macro guidance is driven by parser macro facts, not text matching.
;;; - The suggestions keep transformer shape separate from runtime helpers.
;;; - This is Gerbil Scheme macro usage, not a license to create a DSL.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-controlled-macro-syntax-signals file)
  (typed-combinator-style-facts->signals
   (source-file-macros file)
   ["syntax-case/with-syntax transformer shape"
    "syntax-rules thin macro DSL"
    "hygienic macro boundary"
    "parameterize phase/context state instead of mutating global macro state"
    "typed context records for macro/import/export state"
    "raise-syntax-error keeps source-aware failure paths"
    "parse complex syntax into a small local IR before generating output"
    "separate syntax validation, pattern parsing, and output reconstruction helpers"
    "stx-lambda or def-stx helper boundary"
    "macro syntax stays a thin hygienic syntax wrapper"
    "runtime behavior remains in ordinary helpers"
    "docs explain the expansion contract and example result"]))

;;; Target projection mirrors macro-fact ownership exactly.
;;; The map is intentionally direct: policy details should cite macro names
;;; already emitted by the parser, not derive display names from syntax text.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-controlled-macro-targets file)
  (typed-combinator-style-facts->targets
   (source-file-macros file)
   macro-fact-name))

;;; POO typeclass facts come from the parser's options, not source text scans.
;;; The details expose concrete targets for gerbil-poo/fun.ss style repair.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-typeclass-quality-facets file)
  (typed-combinator-style-facts->quality-facet
   (typed-combinator-style-typeclass-poo-forms file)
   "poo-typeclass-algebra-boundary"))

;;; Signal boundary:
;;; - POO algebra guidance is emitted only for parser-owned POO option facts.
;;; - This keeps typeclass repair tied to gerbil-poo semantics.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-typeclass-algebra-signals file)
  (typed-combinator-style-facts->signals
   (typed-combinator-style-typeclass-poo-forms file)
   ["Category. compose/identity algebra"
    "Functor. map/tap/ap algebra"
    "Wrapper. wrap/unwrap/bind/map algebra"
    "ParametricFunctor. higher-kinded adapter boundary"
    "methods.io<-wrap lifts IO/JSON/bytes/marshal through wrap/unwrap"
    "method bodies stay protocol-shaped instead of table-shaped"]))

;;; Target projection keeps typeclass advice attached to the POO declaration.
;;; The upstream filter owns algebra recognition, so this function only exposes
;;; the repair target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-typeclass-algebra-targets file)
  (typed-combinator-style-facts->targets
   (typed-combinator-style-typeclass-poo-forms file)
   poo-form-fact-name))

;;; Boundary:
;;; - Typeclass detection consumes POO options emitted by parser/poo.ss.
;;; - The option vocabulary mirrors gerbil-poo/fun.ss algebra families.
;; : (-> SourceFile (List PooFormFact) )
(def (typed-combinator-style-typeclass-poo-forms file)
  (filter typed-combinator-style-typeclass-poo-form?
          (source-file-poo-forms file)))

;;; Option predicate:
;;; - Compare only parser-owned option tokens from parser/poo.ss.
;;; - The inline lambda keeps the accepted algebra vocabulary local and avoids
;;;   spreading raw typeclass strings through policy assembly.
;; : (-> PooFormFact Boolean )
(def (typed-combinator-style-typeclass-poo-form? fact)
  (ormap (lambda (option)
           (member option
                   ["typeclass:category"
                    "typeclass:functor"
                    "typeclass:parametric-functor"
                    "typeclass:wrapper"
                    "categoryAlgebra:compose-identity"
                    "functorAlgebra:tap-ap-map"
                    "wrapperAlgebra:wrap-unwrap-bind-map"]))
         (poo-form-fact-options fact)))
