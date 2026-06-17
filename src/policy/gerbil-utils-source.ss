;;; -*- Gerbil -*-
;;; Policy bridge for source-backed gerbil-utils quality metadata.

(import :policy/detection)

(export gerbil-utils-source-detection-overlay
        gerbil-utils-source-details)

;;; Source metadata boundary:
;;; - These profiles are research-backed policy overlays, not activation state.
;;; - Keep owners as advisory strings until gerbil-utils has registered selectors.
;; (List SourceBackedProfile)
(def +gerbil-utils-source-profiles+
  `((predicate-combinator
     (sourcePattern . "gerbil-utils-predicate-combinator")
     (sourceOwners .
      ("gerbil-utils/base.ss#compose"
       "gerbil-utils/base.ss#cut/curry/rcurry"
       "gerbil-utils/base.ss#ensure-function"
       "gerbil-utils/generator.ss#generating-map/fold"))
     (qualitySignals .
      ("small-selector-helper"
       "expression-level-composition"
       "predicate-combinator"
       "generator-aware-transform"))
     (witness . "gerbil-utils study: compose/cut/curry helpers and generator map/fold are style witnesses for bounded predicate or selector helper repair"))
    (sequence-protocol
     (sourcePattern . "gerbil-utils-sequence-protocol")
     (sourceOwners .
      ("gerbil-utils/generator.ss#generating<-for-each"
       "gerbil-utils/generator.ss#generating-map"
       "gerbil-utils/generator.ss#generating-fold"
       "gerbil-utils/peekable-iterator.ss#cursor-state"))
     (qualitySignals .
      ("named-traversal-protocol"
       "map-fold-boundary"
       "observable-cursor-state"))
     (witness . "gerbil-utils study: generator protocol makes traversal state explicit before adding streaming or coroutine behavior"))
    (macro-helper
     (sourcePattern . "gerbil-utils-controlled-macro-helper")
     (sourceOwners .
      ("gerbil-utils/syntax.ss#defsyntax-stx"
       "gerbil-utils/syntax.ss#syntax-case"
       "gerbil-utils/base.ss#nest"
       "gerbil-utils/base.ss#left-to-right"))
     (qualitySignals .
      ("controlled-macro-helper"
       "syntax-case-with-local-parser"
       "thin-syntax-bridge"))
     (witness . "gerbil-utils study: macros are allowed when they are thin, syntax-case-backed helpers with local parsing and explicit transformer boundaries"))
    (default
     (sourcePattern . "gerbil-utils-quality-pattern")
     (sourceOwners .
      ("gerbil-utils/base.ss"
       "gerbil-utils/generator.ss"
       "gerbil-utils/syntax.ss"))
     (qualitySignals .
      ("compact-helper"
       "source-backed-style-exemplar"))
     (witness . "gerbil-utils study: source-backed style exemplar for compact, typed, expression-level Gerbil helpers"))))

;;; Boundary:
;;; - gerbil-utils is a style and engineering exemplar, not an activation
;;;   protocol like gerbil-poo.
;;; - Keep its source owners as advisory metadata until a registered selector
;;;   resolver owns gerbil-utils:// locators.
;; DetectionPrototype <- PatternKind
(def (gerbil-utils-source-detection-overlay kind)
  (detection-prototype-source-overlay
   (gerbil-utils-source-pattern-id kind)
   (gerbil-utils-source-owners kind)
   (gerbil-utils-quality-signals kind)
   (gerbil-utils-source-witness kind)))

;; PolicyDetails <- PatternKind
(def (gerbil-utils-source-details kind)
  (hash (sourcePattern (gerbil-utils-source-pattern-id kind))
        (sourceOwners (gerbil-utils-source-owners kind))
        (qualitySignals (gerbil-utils-quality-signals kind))
        (witness (gerbil-utils-source-witness kind))))

;; String <- PatternKind
(def (gerbil-utils-source-pattern-id kind)
  (gerbil-utils-source-profile-ref kind 'sourcePattern))

;; (List SourceOwner) <- PatternKind
(def (gerbil-utils-source-owners kind)
  (gerbil-utils-source-profile-ref kind 'sourceOwners))

;; (List QualitySignal) <- PatternKind
(def (gerbil-utils-quality-signals kind)
  (gerbil-utils-source-profile-ref kind 'qualitySignals))

;; Witness <- PatternKind
(def (gerbil-utils-source-witness kind)
  (gerbil-utils-source-profile-ref kind 'witness))

;; ProfileFieldValue <- PatternKind ProfileField
(def (gerbil-utils-source-profile-ref kind field)
  (cdr (assq field (cdr (gerbil-utils-source-profile kind)))))

;; SourceBackedProfile <- PatternKind
(def (gerbil-utils-source-profile kind)
  (or (assq kind +gerbil-utils-source-profiles+)
      (assq 'default +gerbil-utils-source-profiles+)))
