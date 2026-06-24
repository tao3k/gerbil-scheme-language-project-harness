;;; -*- Gerbil -*-
;;; Policy bridge for learned Gerbil quality metadata.
;;; This module keeps research corpus references structured without turning
;;; gerbil-utils or gerbil-poo into downstream dependency requirements.

(import :parser/facade
        :policy/detection
        :policy/prototype
        (only-in :std/srfi/1 find)
        (only-in :std/sugar ormap))

(export gerbil-utils-source-detection-overlay
        gerbil-utils-source-details
        quality-reference-details
        typed-combinator-style-quality-reference-details
        typed-combinator-style-gerbil-utils-source-details)

;;; Base profile:
;;; - gerbil-utils source evidence is now a C3 slot profile like other policy
;;;   descriptors, not a side table bolted onto detection.
;;; - Source owners remain advisory strings until gerbil-utils:// selectors are
;;;   provider-owned facts.
;; SourceBackedProfile
(def +gerbil-utils-source-base-profile+
  (slot-profile
   "gerbil-utils-source-base"
   [(cons 'profileComposition
          "policy/prototype slot-profile + POO/C3 source-profile overlay")
    (cons 'sourceFamily "gerbil-utils")]))

;;; Constructor boundary:
;;; - Keep profile literals compact while preserving named record fields.
;;; - gerbil-utils entries are study examples for style and quality, not
;;;   downstream dependency requirements.
;; : (-> PatternKind SourcePattern (List SourceOwner) (List QualitySignal) Witness SourceBackedProfile )
(def (make-gerbil-utils-source-profile kind source-pattern source-owners quality-signals witness)
  (slot-profile
   source-pattern
   [(cons 'kind kind)
    (cons 'source-pattern source-pattern)
    (cons 'source-owners source-owners)
    (cons 'quality-signals quality-signals)
    (cons 'witness witness)]
   supers: [+gerbil-utils-source-base-profile+]))

;;; Reference profile table boundary:
;;; - These profiles are research-backed policy overlays, not activation state.
;;; - Each entry names corpus examples, repair signals, and one witness sentence.
;;; - Keep exemplar expansion here so downstream policies stay compact.
;; (List SourceBackedProfile)
(def +gerbil-utils-source-profiles+
  [(make-gerbil-utils-source-profile
    'predicate-combinator
    "gerbil-utils-predicate-combinator"
    ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
     "gerbil-utils/base.ss#fun"
     "gerbil-utils/base.ss#compose/rcompose"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil-utils/base.ss#ensure-function"
     "gerbil-utils/generator.ss#generating-map/fold"]
    ["small-selector-helper"
     "lambda-match-destructuring"
     "lambda-match-rewrite-opportunity"
     "named-lambda-helper"
     "expression-level-composition"
     "predicate-combinator"
     "function-pipeline-abstraction"
     "generator-aware-transform"]
    "gerbil-utils study: lambda-match/lambda-ematch, fun, compose/rcompose, cut/curry/rcurry, and generator map/fold are style witnesses for bounded predicate or selector repair")
   (make-gerbil-utils-source-profile
    'higher-order-expression
    "gerbil-utils-higher-order-expression"
    ["gerbil-utils/base.ss#lambda-match/lambda-ematch"
     "gerbil-utils/base.ss#fun"
     "gerbil-utils/base.ss#compose/rcompose/!>/!!>"
     "gerbil-utils/base.ss#left-to-right"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
     "gerbil-utils/base.ss#case-lambda specializers"
     "gerbil-utils/generator.ss#compose-backed-generating-map"]
    ["lambda-match-destructuring"
     "lambda-match-rewrite-opportunity"
     "named-lambda-helper"
     "function-specialization-abstraction"
     "function-pipeline-abstraction"
     "pipeline-composition"
     "cut-prefix-predicate"
     "thin-wrapper-elimination"
     "multi-arity-abstraction"
     "generator-composition"]
    "gerbil-utils and gerbil:// study: prefer real higher-order expression idioms before inventing helper-only rewrites")
   (make-gerbil-utils-source-profile
    'list-combinator-boundary
    "list-combinator-boundary"
    ["gerbil://std/actor-v13/rpc/proto/cipher.ss#foldl-chunk-accumulator"
     "gerbil://std/actor-v18/executor.ss#cut-prefix-predicate"
     "gerbil-utils/list.ss#list-map"
     "gerbil-utils/list.ss#list<-monoid"
     "gerbil-utils/list.ss#with-deduplicated-list-builder"
     "gerbil-utils/list.ss#merge-lists"
     "gerbil-utils/base.ss#lambda-match"
     "gerbil-utils/base.ss#compose/rcompose"]
    ["list-combinator-boundary"
     "fold-reducer-boundary"
     "cut-predicate-specialization"
     "map-fold-boundary"
     "filter-map-selection-projection"
     "lambda-match-list-destructuring"
     "list-builder-output-shape"
     "deduplicated-builder-boundary"]
    "gerbil:// source corpus, gerbil-utils/list.ss, and base.ss study: list traversal quality comes from fold reducers, cut-shaped predicates, small mapper/reducer/selector boundaries, lambda-match when pair shape matters, and builders only when output construction needs them")
   (make-gerbil-utils-source-profile
    'destructuring-combinator-boundary
    "destructuring-combinator-boundary"
    ["gerbil://gerbil/core/match.ss#applicative-destructuring"
     "gerbil://gerbil/core/match.ss#syntax-local-match-macro"
     "gerbil://gerbil/core/match.ss#syntax-local-value-class-accessors"
     "gerbil://gerbil/core/match.ss#defsyntax-for-match"
     "gerbil-utils/base.ss#lambda-match"
     "gerbil-utils/base.ss#let-match"
     "gerbil-utils/base.ss#when-match"
     "gerbil-utils/base.ss#compose/rcompose"
     "gerbil-poo/mop.ss#slot-lens"
     "gerbil-poo/mop.ss#Lens.compose"]
    ["destructuring-combinator-boundary"
     "applicative-destructuring-boundary"
     "syntax-local-match-extension"
     "compile-time-metadata-lookup"
     "early-syntax-error-boundary"
     "lambda-match-destructuring"
     "named-selector-boundary"
     "slot-lens-boundary"
     "temporary-binding-collapse"
     "object-slot-access-boundary"]
    "gerbil:// core match, gerbil-utils/base.ss, and gerbil-poo/mop.ss study: repeated pair/alist/object destructuring should collapse into native match/applicative destructuring, syntax-local metadata lookup, a selector, or local slot/lens boundary instead of generated temporary let scaffolding")
   (make-gerbil-utils-source-profile
    'projection-builder
    "gerbil-utils-projection-builder"
    ["gerbil-utils/base.ss#compose"
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil/std/cli/getopt.ss#with-list-builder"
     "gerbil/std/actor-v18/server.ss#for/fold"]
    ["projection-helper"
     "line-renderer-boundary"
     "list-builder-output-shape"
     "expression-level-composition"]
    "gerbil-utils/base and Gerbil std show projection/rendering should be split into selectors, line builders, and compact folds instead of hash-get/display walls")
   (make-gerbil-utils-source-profile
    'sequence-protocol
    "gerbil-utils-sequence-protocol"
    ["gerbil-utils/generator.ss#generating<-for-each"
     "gerbil-utils/generator.ss#generating-map"
     "gerbil-utils/generator.ss#generating-fold"
     "gerbil-utils/peekable-iterator.ss#cursor-state"]
    ["named-traversal-protocol"
     "map-fold-boundary"
     "observable-cursor-state"]
    "gerbil-utils study: generator protocol makes traversal state explicit before adding streaming or coroutine behavior")
   (make-gerbil-utils-source-profile
    'generator-control
    "gerbil-utils-generator-control"
    ["gerbil-utils/generator.ss#generating<-for-each"
     "gerbil-utils/generator.ss#yield-continuation-boundary"
     "gerbil-utils/generator.ss#unexpected-yield"
     "gerbil-utils/generator.ss#eof!"
     "gerbil-utils/generator.ss#list<-generating"
     "gerbil-utils/generator.ss#generating<-cothread"]
    ["push-pull-control-inversion"
     "call/cc-yield-boundary"
     "one-shot-generator-protocol"
     "out-of-band-eof-boundary"
     "unexpected-yield-guard"
     "list-adapter-boundary"
     "cothread-finalization-boundary"]
    "gerbil-utils study: generators are push/pull control-inversion boundaries with one-shot semantics, explicit yield continuations, out-of-band EOF, and adapter functions at the stream boundary")
   (make-gerbil-utils-source-profile
    'protocol-serialization-boundary
    "protocol-serialization-boundary"
    ["gerbil-poo/io.ss#marshal"
     "gerbil-poo/io.ss#unmarshal"
     "gerbil-poo/io.ss#bytes<-"
     "gerbil-poo/io.ss#<-bytes"
     "gerbil-poo/io.ss#methods.string<-json"
     "gerbil-poo/io.ss#methods.bytes<-marshal"
     "gerbil-poo/io.ss#methods.marshal<-bytes"
     "gerbil-poo/io.ss#methods.marshal<-fixed-length-bytes"]
   ["protocol-serialization-boundary"
     "self-delimited-marshal-boundary"
     "bytes-non-self-delimited-boundary"
     "json-string-adapter-boundary"
     "reader-writer-symmetry"
     "local-protocol-adapter"]
    "gerbil-poo/io.ss study: serialization quality comes from separating local JSON/string/bytes/marshal protocol adapters, keeping marshal self-delimited, keeping raw bytes representation non-self-delimited, and preserving reader/writer symmetry")
   (make-gerbil-utils-source-profile
    'slot-lens-boundary
    "slot-lens-boundary"
    ["gerbil-poo/mop.ss#slot-checker"
     "gerbil-poo/mop.ss#slot-definer"
     "gerbil-poo/mop.ss#Class.effective-slots"
     "gerbil-poo/mop.ss#Lens.modify"
     "gerbil-poo/mop.ss#Lens.compose"
     "gerbil-poo/mop.ss#slot-lens"]
   ["slot-descriptor-boundary"
     "lens-get-set-modify-boundary"
     "slot-validation-boundary"
     "slot-serialization-boundary"
     "local-lens-helper"
     "reader-writer-symmetry"]
   "gerbil-poo/mop.ss study: slot quality comes from local descriptor/lens boundaries that centralize get/set/modify, validation, and serialization symmetry without requiring a gerbil-poo dependency")
   (make-gerbil-utils-source-profile
    'typeclass-wrapper-adapter
    "typeclass-wrapper-adapter"
    ["gerbil-poo/fun.ss#Category."
     "gerbil-poo/fun.ss#Functor."
     "gerbil-poo/fun.ss#ParametricFunctor."
     "gerbil-poo/fun.ss#methods.io<-wrap"
     "gerbil-poo/fun.ss#Wrapper."
     "gerbil-poo/fun.ss#Wrap."
     "gerbil-poo/fun.ss#Wrap^."]
    ["typeclass-algebra-boundary"
     "functor-map-ap-boundary"
     "wrapper-adapter-lift"
     "wrap-unwrap-boundary"
     "method-protocol-lift"
     "cut-backed-runtime-parameterization"]
    "gerbil-poo/fun.ss study: wrapper and functor quality comes from keeping wrap/unwrap as the only representation crossing, lifting IO/JSON/bytes/marshal methods through local adapters, and preserving map/ap algebra without requiring a gerbil-poo dependency")
   (make-gerbil-utils-source-profile
   'concurrency-control-boundary
   "concurrency-control-boundary"
    ["gerbil://gerbil/runtime/control.ss#make-atomic-promise"
     "gerbil://gerbil/runtime/control.ss#call-with-parameters"
     "gerbil://gerbil/runtime/control.ss#with-unwind-protect"
     "gerbil-utils/concurrency.ss#sequentialize/mutex"
     "gerbil-utils/concurrency.ss#race/list"
     "gerbil-utils/concurrency.ss#parallel-map"
     "gerbil-utils/concurrency.ss#spawn/name/params"
     "gerbil-utils/concurrency.ss#all-thread-parameters"]
    ["concurrency-control-boundary"
     "dynamic-wind-reentry-guard"
     "unwind-cleanup-boundary"
     "spawn-join-helper-boundary"
     "mutex-sequentialization-boundary"
     "race-shutdown-boundary"
     "parallel-map-join-boundary"
     "thread-parameter-propagation"]
    "gerbil:// runtime control and gerbil-utils/concurrency.ss study: concurrency quality comes from preserving dynamic-wind reentry guards and unwind cleanup while naming spawn/join, mutex sequentialization, race shutdown, parallel map, and thread-parameter propagation boundaries without requiring a gerbil-utils dependency")
   (make-gerbil-utils-source-profile
    'exception-continuation-boundary
    "exception-continuation-boundary"
    ["gerbil-utils/exception.ss#string<-exception"
     "gerbil-utils/exception.ss#with-catch/cont"
     "gerbil-utils/exception.ss#escaping-handler"
     "gerbil-utils/exception.ss#call-with-logged-exceptions"
     "gerbil-utils/exception.ss#thunk-with-logged-exceptions"
     "gerbil-utils/exception.ss#with-logged-exceptions"]
    ["exception-continuation-boundary"
     "handler-restoration-boundary"
     "contextual-exception-logging"
     "re-raise-after-logging"
     "printable-exception-fallback"
     "local-exception-wrapper"]
    "gerbil-utils/exception.ss study: exception quality comes from capturing continuation context, restoring the prior handler before escaping, logging contextual diagnostics, and re-raising instead of swallowing failures")
   (make-gerbil-utils-source-profile
    'stateful-structure
    "gerbil-utils-stateful-structure"
    ["gerbil-utils/stateful-avl-map.ss#avl-map-update-height!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-rotate-left!/right!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-balance!"
     "gerbil-utils/stateful-avl-map.ss#avl-map-put!/remove!"
     "gerbil-utils/stateful-avl-map.ss#generating<-avl-map"
     "gerbil-utils/stateful-avl-map.ss#table<-avl-map/alist<-avl-map"]
    ["bounded-mutable-invariant"
     "height-cache-maintenance"
     "rotation-comment-boundary"
     "local-structural-mutation"
     "generator-adapter-boundary"
     "table-alist-conversion-boundary"]
    "gerbil-utils study: stateful AVL mutation is acceptable when it is local to a data-structure invariant, documents rotations, maintains cached height, and exposes generator/table/alist adapters at the boundary")
   (make-gerbil-utils-source-profile
    'macro-helper
    "gerbil-utils-controlled-macro-helper"
    ["gerbil://gerbil/compiler/method.ss#ast-case-with-syntax-map-cut"
     "gerbil-utils/syntax.ss#defsyntax-stx"
     "gerbil-utils/syntax.ss#syntax-case"
     "gerbil-utils/syntax.ss#begin-syntax parse-formals"
     "gerbil-utils/autocurry.ss#syntax-rules"
     "gerbil-utils/base.ss#nest"
     "gerbil-utils/base.ss#left-to-right"]
    ["controlled-macro-helper"
     "macro-hygiene-boundary"
     "ast-case-transformer-boundary"
     "with-syntax-reconstruction-boundary"
     "syntax-case-with-local-parser"
     "syntax-rules-thin-dsl"
     "thin-syntax-bridge"
     "runtime-helper-boundary"
     "expansion-contract-doc"]
    "gerbil:// source corpus and gerbil-utils study: macros are allowed when they are thin hygienic syntax wrappers, use ast-case/syntax-case or syntax-rules for local parsing, reconstruct with with-syntax, and keep reusable runtime behavior outside the transformer")
   (make-gerbil-utils-source-profile
    'default
    "gerbil-utils-quality-pattern"
    ["gerbil-utils/base.ss"
     "gerbil-utils/generator.ss"
     "gerbil-utils/syntax.ss"]
    ["compact-helper"
     "source-backed-style-exemplar"]
    "gerbil-utils study: source-backed style exemplar for compact, typed, expression-level Gerbil helpers")])

;;; Boundary:
;;; - gerbil-utils is a style and engineering exemplar, not an activation
;;;   protocol like gerbil-poo.
;;; - Keep reference examples as advisory evidence, not downstream import
;;;   requirements.
;; : (-> PatternKind DetectionPrototype )
(def (gerbil-utils-source-detection-overlay kind)
  (let (profile (gerbil-utils-source-profile kind))
    (detection-prototype-extend
     (detection-prototype-source-overlay
      (gerbil-utils-source-pattern-id kind)
      (gerbil-utils-source-owners kind)
      (gerbil-utils-quality-signals kind)
      (gerbil-utils-source-witness kind))
     (slot-profile
      (string-append (gerbil-utils-source-pattern-id kind)
                     "-source-profile-overlay")
      [(cons 'source-profile-composition
             (gerbil-utils-source-profile-composition profile))
       (cons 'source-profile-precedence
             (slot-profile-precedence-names profile))]))))

;;; JSON detail boundary:
;;; - TypeFinding details need plain hash data for provider output.
;;; - The profile record remains the internal source of truth.
;;; - Expose learned quality references, not source-owner requirements.
;; : (-> PatternKind PolicyDetails )
(def (gerbil-utils-source-details kind)
  (let (profile (gerbil-utils-source-profile kind))
    (hash (referencePattern (source-backed-profile-source-pattern profile))
          (referenceExamples (source-backed-profile-source-owners profile))
          (qualitySignals (source-backed-profile-quality-signals profile))
          (witness (source-backed-profile-witness profile))
          (profileComposition
           (gerbil-utils-source-profile-composition profile))
          (profilePrecedence (slot-profile-precedence-names profile)))))

;;; Neutral reference boundary:
;;; - Callers should use this name for agent-facing quality references.
;;; - The old gerbil-utils-source name remains only as an internal storage
;;;   owner while the corpus includes gerbil-utils and gerbil-poo examples.
;; : (-> PatternKind PolicyDetails )
(def (quality-reference-details kind)
  (gerbil-utils-source-details kind))

;;; Typed-combinator bridge:
;;; - Select the learned reference from parser-owned quality facets.
;;; - The returned payload is neutral quality evidence, never an import
;;;   recommendation for the reference corpus package.
;; : (-> SourceFile QualityFacets PolicyDetails )
(def (typed-combinator-style-quality-reference-details file quality-facets)
  (quality-reference-details
   (typed-combinator-style-gerbil-utils-source-kind file quality-facets)))

;;; Typed-combinator bridge:
;;; - Select the source-backed profile from parser-owned facts and facets.
;;; - The result is report evidence; R013 triggering remains in agent-style.ss.
;; : (-> SourceFile QualityFacets PolicyDetails )
(def (typed-combinator-style-gerbil-utils-source-details file quality-facets)
  (typed-combinator-style-quality-reference-details file quality-facets))

;;; Selection boundary:
;;; - Specific parser-owned risk facets win before broad higher-order style.
;;; - The ordering prevents a serialization or generator protocol warning from
;;;   being flattened into a generic expression-composition reference.
;;; - Returned kinds are quality references, not package dependency choices.
;; : (-> SourceFile QualityFacets PatternKind )
(def (typed-combinator-style-gerbil-utils-source-kind file quality-facets)
  (cond
   ((pair? (source-file-macros file)) 'macro-helper)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["protocol-serialization-boundary"])
    'protocol-serialization-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["slot-lens-boundary"])
    'slot-lens-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["poo-typeclass-algebra-boundary"])
    'typeclass-wrapper-adapter)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["concurrency-control-boundary"])
    'concurrency-control-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["exception-continuation-boundary"])
    'exception-continuation-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["generator-combinator-boundary"])
    'generator-control)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["list-combinator-boundary"])
    'list-combinator-boundary)
   ((gerbil-utils-source-quality-facet-any?
     quality-facets
     ["destructuring-combinator-boundary"])
    'destructuring-combinator-boundary)
   ((or (pair? (source-file-higher-order-forms file))
        (gerbil-utils-source-quality-facet-any?
         quality-facets
         ["base-style-combinator-composition"
          "higher-order-constructor-abstraction"
          "arity-specialized-function-factory"
          "wrapper-lambda-drift"
          "function-specialization-opportunity"
          "eta-wrapper-drift"
          "lambda-match-destructuring"
          "lambda-match-rewrite-opportunity"
          "function-specialization-abstraction"
          "function-pipeline-abstraction"]))
    'higher-order-expression)
   (else 'default)))

;;; Facet helper stays local so this source bridge does not depend on the main
;;; R013 policy owner's private predicate vocabulary.
;; : (-> QualityFacets (List QualityFacet) Boolean )
(def (gerbil-utils-source-quality-facet-any? facets candidates)
  (ormap (lambda (candidate)
           (if (member candidate facets) #t #f))
         candidates))

;;; Accessor boundary:
;;; - Public helpers expose stable policy fields.
;;; - Internal profile representation can change without touching callers.
;; : (-> PatternKind String )
(def (gerbil-utils-source-pattern-id kind)
  (source-backed-profile-source-pattern (gerbil-utils-source-profile kind)))

;;; Example accessor keeps advisory anchors grouped as reference evidence.
;; : (-> PatternKind (List SourceOwner) )
(def (gerbil-utils-source-owners kind)
  (source-backed-profile-source-owners (gerbil-utils-source-profile kind)))

;;; Quality accessor feeds parser-owned repair steering.
;; : (-> PatternKind (List QualitySignal) )
(def (gerbil-utils-quality-signals kind)
  (source-backed-profile-quality-signals (gerbil-utils-source-profile kind)))

;;; Witness accessor keeps prose at the report edge instead of policy logic.
;; : (-> PatternKind Witness )
(def (gerbil-utils-source-witness kind)
  (source-backed-profile-witness (gerbil-utils-source-profile kind)))

;;; Lookup boundary:
;;; - Unknown patterns intentionally fall back to the default exemplar.
;;; - The default keeps repair guidance available without inventing a match.
;; : (-> PatternKind SourceBackedProfile )
(def (gerbil-utils-source-profile kind)
  (or (find (lambda (profile)
              (eq? (source-backed-profile-kind profile) kind))
            +gerbil-utils-source-profiles+)
      (find (lambda (profile)
              (eq? (source-backed-profile-kind profile) 'default))
            +gerbil-utils-source-profiles+)))

;; : (-> SourceBackedProfile PatternKind )
(def (source-backed-profile-kind profile)
  (slot-profile-ref profile 'kind 'default))

;; : (-> SourceBackedProfile SourcePattern )
(def (source-backed-profile-source-pattern profile)
  (slot-profile-ref profile 'source-pattern "gerbil-utils-quality-pattern"))

;; : (-> SourceBackedProfile (List SourceOwner) )
(def (source-backed-profile-source-owners profile)
  (slot-profile-ref profile 'source-owners '()))

;; : (-> SourceBackedProfile (List QualitySignal) )
(def (source-backed-profile-quality-signals profile)
  (slot-profile-ref profile 'quality-signals '()))

;; : (-> SourceBackedProfile Witness )
(def (source-backed-profile-witness profile)
  (slot-profile-ref profile 'witness ""))

;; : (-> SourceBackedProfile String )
(def (gerbil-utils-source-profile-composition profile)
  (slot-profile-ref profile 'profileComposition ""))
