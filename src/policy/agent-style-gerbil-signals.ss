;;; -*- Gerbil -*-
;;; Gerbil-specific style signals for R013 typed-combinator guidance.

(import :parser/facade
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter ormap))

(export typed-combinator-style-generator-quality-facets
        +typed-comment-metadata-fields+
        +gerbil-utils-implementation-signals+
        +gerbil-contract-projection-signals+
        typed-combinator-style-generator-combinator-signals
        typed-combinator-style-generator-contract-targets
        typed-combinator-style-controlled-macro-quality-facets
        typed-combinator-style-controlled-macro-syntax-signals
        typed-combinator-style-controlled-macro-targets
        typed-combinator-style-typeclass-quality-facets
        typed-combinator-style-typeclass-algebra-signals
        typed-combinator-style-typeclass-algebra-targets)

;;; Boundary:
;;; - This owner converts parser facts into bounded R013 steering signals.
;;; - It does not decide whether a finding should fire.
;;; - agent-style.ss owns policy triggering and message assembly.
;;; - Keeping these signals separate prevents the main policy owner from
;;;   becoming a sink for every Gerbil library idiom.

;;; Payload boundary:
;;; - These fields are provider-owned typedComment projection slots.
;;; - Keep them stable so policy details and JSON facts use one vocabulary.
;; (List String)
(def +typed-comment-metadata-fields+
  ["leadingName" "signatureType" "localTypes" "runtimeContracts"
   "runtimeContractsDetailed" "requires" "requiresDetailed"
   "warnings" "rationales" "docs" "docs.examples"
   "docs.hasResultExamples" "refinements"])

;;; Exemplar boundary:
;;; - These are gerbil-utils style signals, not mandatory syntax forms.
;;; - They steer repair suggestions without making policy depend on one library.
;; (List String)
(def +gerbil-utils-implementation-signals+
  ["λ/lambda-match local destructuring"
   "fun named lambda abstraction"
   "!>/!!> pipeline"
   "apply compose"
   "cut/curry/rcurry"
   "map/filter/filter-map/fold"
   "with-list-builder"])

;;; Projection boundary:
;;; - These strings describe how upstream Gerbil contracts reach harness facts.
;;; - Keep agent guidance tied to projection evidence instead of invented grammar.
;; (List String)
(def +gerbil-contract-projection-signals+
  ["legacy contracts split at top-level <-, not nested arrows"
   "Gerbil contract projection ;; : (forall (a) (-> ...)) blocks carry type aliases, runtime contracts, requires, warning, rationale, and doc sections"
   "higher-order contracts may use placeholder-looking Gerbil utility variables when the arrow/group evidence is higher-order"])

;;; Generator contracts are first-class style evidence.  They should steer the
;;; agent toward gerbil-utils/generator.ss instead of local producer loops.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-generator-quality-facets file)
  (if (pair? (typed-combinator-style-generator-contract-facts file))
    ["generator-combinator-boundary"]
    []))

;;; Signal boundary:
;;; - Generator guidance is emitted only when typed-contract facts prove it.
;;; - Empty output means the caller should not recommend generator rewrites.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-generator-combinator-signals file)
  (if (pair? (typed-combinator-style-generator-contract-facts file))
    ["Generating contract projection"
     "generating<-list source adapter"
     "generating-map transform"
     "generating-fold reducer"
     "generating-partition split"
     "generating-merge priority merge"
     "generating<-cothread continuation bridge"]
    []))

;;; Target projection keeps the public policy payload compact.
;;; Mapping over facts is safe here because the detector already filtered to
;;; generator contracts; no fallback source scan is needed.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-generator-contract-targets file)
  (map typed-contract-fact-definition-name
       (typed-combinator-style-generator-contract-facts file)))

;;; Boundary:
;;; - Generator detection is derived from typed-contract facts.
;;; - Output, inputs, and tokens are all checked because legacy contracts can
;;;   carry `Generating` at different nesting levels.
;; : (-> SourceFile (List TypedContractFact) )
(def (typed-combinator-style-generator-contract-facts file)
  (filter typed-combinator-style-generator-contract-fact?
          (source-file-typed-contract-facts file)))

;;; Predicate boundary:
;;; - A generator contract can mention `Generating` in output, input, or tokens.
;;; - The ormap path preserves nested legacy contracts without flattening them
;;;   into raw text heuristics.
;; : (-> TypedContractFact Boolean )
(def (typed-combinator-style-generator-contract-fact? fact)
  (or (member "Generating" (typed-contract-fact-tokens fact))
      (and (string? (typed-contract-fact-contract-output fact))
           (string-contains (typed-contract-fact-contract-output fact)
                            "Generating"))
      (ormap (lambda (input)
               (and (string? input)
                    (string-contains input "Generating")))
             (typed-contract-fact-contract-inputs fact))))

;;; Macro facts already classify syntax owners.  R013 exposes the engineering
;;; steering so macro-heavy files use upstream macro-library idioms without
;;; inventing a project-specific DSL.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-controlled-macro-quality-facets file)
  (if (pair? (source-file-macros file))
    ["controlled-macro-syntax-boundary"]
    []))

;;; Signal boundary:
;;; - Controlled macro guidance is driven by parser macro facts, not text matching.
;;; - The suggestions keep transformer shape separate from runtime helpers.
;;; - This is Gerbil Scheme macro usage, not a license to create a DSL.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-controlled-macro-syntax-signals file)
  (if (pair? (source-file-macros file))
    ["syntax-case/with-syntax transformer shape"
     "stx-lambda or def-stx helper boundary"
     "macro syntax stays a thin hygienic syntax wrapper"
     "runtime behavior remains in ordinary helpers"
     "docs explain the expansion contract and example result"]
    []))

;;; Target projection mirrors macro-fact ownership exactly.
;;; The map is intentionally direct: policy details should cite macro names
;;; already emitted by the parser, not derive display names from syntax text.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-controlled-macro-targets file)
  (map macro-fact-name (source-file-macros file)))

;;; POO typeclass facts come from the parser's options, not source text scans.
;;; The details expose concrete targets for gerbil-poo/fun.ss style repair.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-typeclass-quality-facets file)
  (if (pair? (typed-combinator-style-typeclass-poo-forms file))
    ["poo-typeclass-algebra-boundary"]
    []))

;;; Signal boundary:
;;; - POO algebra guidance is emitted only for parser-owned POO option facts.
;;; - This keeps typeclass repair tied to gerbil-poo semantics.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-typeclass-algebra-signals file)
  (if (pair? (typed-combinator-style-typeclass-poo-forms file))
    ["Category. compose/identity algebra"
     "Functor. map/tap/ap algebra"
     "Wrapper. wrap/unwrap/bind/map algebra"
     "ParametricFunctor. higher-kinded adapter boundary"
     "method bodies stay protocol-shaped instead of table-shaped"]
    []))

;;; Target projection keeps typeclass advice attached to the POO declaration.
;;; The upstream filter owns algebra recognition, so this function only exposes
;;; the repair target names.
;; : (-> SourceFile (List TargetName) )
(def (typed-combinator-style-typeclass-algebra-targets file)
  (map poo-form-fact-name
       (typed-combinator-style-typeclass-poo-forms file)))

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
