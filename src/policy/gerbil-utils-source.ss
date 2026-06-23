;;; -*- Gerbil -*-
;;; Policy bridge for source-backed gerbil-utils quality metadata.
;;; This module keeps research corpus references structured until provider-owned
;;; gerbil-utils selectors replace advisory owner strings.

(import :policy/detection
        :policy/prototype
        (only-in :std/srfi/1 find))

(export gerbil-utils-source-detection-overlay
        gerbil-utils-source-details)

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
;;; - This is the interim shape before gerbil-utils:// selectors exist.
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

;;; Source profile table boundary:
;;; - These profiles are research-backed policy overlays, not activation state.
;;; - Each entry names owner anchors, repair signals, and one witness sentence.
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
     "gerbil-utils/base.ss#cut/curry/rcurry"
     "gerbil-utils/base.ss#case-lambda specializers"
     "gerbil-utils/generator.ss#compose-backed-generating-map"]
    ["lambda-match-destructuring"
     "named-lambda-helper"
     "function-specialization-abstraction"
     "function-pipeline-abstraction"
     "multi-arity-abstraction"
     "generator-composition"]
    "gerbil-utils study: prefer real higher-order expression idioms before inventing helper-only rewrites")
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
    'macro-helper
    "gerbil-utils-controlled-macro-helper"
    ["gerbil-utils/syntax.ss#defsyntax-stx"
     "gerbil-utils/syntax.ss#syntax-case"
     "gerbil-utils/base.ss#nest"
     "gerbil-utils/base.ss#left-to-right"]
    ["controlled-macro-helper"
     "syntax-case-with-local-parser"
     "thin-syntax-bridge"]
    "gerbil-utils study: macros are allowed when they are thin, syntax-case-backed helpers with local parsing and explicit transformer boundaries")
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
;;; - Keep its source owners as advisory metadata until a registered selector
;;;   resolver owns gerbil-utils:// locators.
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
;; : (-> PatternKind PolicyDetails )
(def (gerbil-utils-source-details kind)
  (let (profile (gerbil-utils-source-profile kind))
    (hash (sourcePattern (source-backed-profile-source-pattern profile))
          (sourceOwners (source-backed-profile-source-owners profile))
          (qualitySignals (source-backed-profile-quality-signals profile))
          (witness (source-backed-profile-witness profile))
          (profileComposition
           (gerbil-utils-source-profile-composition profile))
          (profilePrecedence (slot-profile-precedence-names profile)))))

;;; Accessor boundary:
;;; - Public helpers expose stable policy fields.
;;; - Internal profile representation can change without touching callers.
;; : (-> PatternKind String )
(def (gerbil-utils-source-pattern-id kind)
  (source-backed-profile-source-pattern (gerbil-utils-source-profile kind)))

;;; Owner accessor keeps advisory anchors grouped as reference evidence.
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
