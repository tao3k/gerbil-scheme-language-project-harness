;;; -*- Gerbil -*-
;;; Parser selector and project aggregation helpers.

(import :gerbil/gambit
        :parser/model
        (only-in :std/srfi/13 string-prefix? string-suffix?))

(export project-definitions
        project-calls
        project-predicate-family-facts
        project-field-access-pattern-facts
        project-boolean-condition-facts
        project-loop-driver-facts
        project-dependency-adapter-quality-facts
        project-function-quality-profiles
        project-typed-contract-facts
        project-comment-quality-facts
        find-owner
        definition-selector
        call-fact-selector
        module-import-fact-selector
        module-export-fact-selector
        macro-fact-selector
        binding-fact-selector
        poo-form-fact-selector
        higher-order-fact-selector
        control-flow-fact-selector
        predicate-family-fact-selector
        field-access-pattern-fact-selector
        boolean-condition-fact-selector
        loop-driver-fact-selector
        dependency-adapter-quality-fact-selector
        function-quality-profile-selector
        typed-contract-fact-selector
        comment-quality-fact-selector
        top-form-selector
        relative-path
        source-full-path
        normalize-owner)

;;; Aggregation boundary:
;;; - Keep project-level fact projections outside the source reader.
;;; - Preserve source-file-owned ordering for policy and search packets.
;; (List Definition) <- ProjectIndex
(def (project-definitions index)
  (apply append (map source-file-definitions (project-index-files index))))

;;; Call aggregation preserves source-file order so selector and search packet
;;; output stay deterministic across project collection runs.
;; (List CallFact) <- ProjectIndex
(def (project-calls index)
  (apply append (map source-file-calls (project-index-files index))))

;;; Predicate-family facts are already source-owned by the native parser.
;;; The project projection only flattens file buckets for policy and search.
;; (List PredicateFamilyFact) <- ProjectIndex
(def (project-predicate-family-facts index)
  (apply append
         (map source-file-predicate-family-facts
              (project-index-files index))))

;;; Field-access facts must remain separate from predicate-family thresholds so
;;; agent repair can explain selector-helper evidence independently.
;; (List FieldAccessPatternFact) <- ProjectIndex
(def (project-field-access-pattern-facts index)
  (apply append
         (map source-file-field-access-pattern-facts
              (project-index-files index))))

;;; Boolean-condition facts keep individual predicate helpers queryable even
;;; when a family-level policy finding owns the repair decision.
;; (List BooleanConditionFact) <- ProjectIndex
(def (project-boolean-condition-facts index)
  (apply append
         (map source-file-boolean-condition-facts
              (project-index-files index))))

;;; Loop-driver facts distinguish pure transform drift from IO/runtime driver
;;; boundaries before policy decides whether a named let should remain.
;; (List LoopDriverFact) <- ProjectIndex
(def (project-loop-driver-facts index)
  (apply append
         (map source-file-loop-driver-facts
              (project-index-files index))))

;;; Dependency adapter facts expose define-type/protocol wrappers over imported
;;; dependency primitives before policy decides whether the boundary is strong.
;; (List DependencyAdapterQualityFact) <- ProjectIndex
(def (project-dependency-adapter-quality-facts index)
  (apply append
         (map source-file-dependency-adapter-quality-facts
              (project-index-files index))))

;;; Function-quality profiles are the function-level join across parser fact families.
;;; Keep this projection first-class so repair planning can group by function.
;; (List FunctionQualityProfile) <- ProjectIndex
(def (project-function-quality-profiles index)
  (apply append
         (map source-file-function-quality-profiles
              (project-index-files index))))

;;; Typed-contract facts are flattened after parsing so R013 can stay a policy
;;; consumer of native evidence rather than re-reading comment text.
;; (List TypedContractFact) <- ProjectIndex
(def (project-typed-contract-facts index)
  (apply append
         (map source-file-typed-contract-facts
              (project-index-files index))))

;;; Comment-quality facts carry parser evidence for R015 repair prompts.
;;; Keeping this as a projection helper lets check, info, and search share the
;;; same native evidence list.
;; (List CommentQualityFact) <- ProjectIndex
(def (project-comment-quality-facts index)
  (apply append
         (map source-file-comment-quality-facts
              (project-index-files index))))

;;; Owner lookup boundary:
;;; - Normalize user-facing owner paths before comparing parser-owned paths.
;;; - Keep parse-source-file independent from query selector policy.
;; SourceFile <- ProjectIndex String
(def (find-owner index owner)
  (find (lambda (file) (equal? (source-file-path file) (normalize-owner owner)))
        (project-index-files index)))

;; Selector <- Definition
(def (definition-selector defn)
  (string-append (definition-path defn) ":"
                 (number->string (definition-start defn))
                 "-"
                 (number->string (definition-end defn))))

;; Selector <- CallFact
(def (call-fact-selector call)
  (string-append (call-fact-path call) ":"
                 (number->string (call-fact-start call))
                 "-"
                 (number->string (call-fact-end call))))

;; Selector <- Fact
(def (module-import-fact-selector fact)
  (string-append (module-import-fact-path fact) ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

;; Selector <- Fact
(def (module-export-fact-selector fact)
  (string-append (module-export-fact-path fact) ":"
                 (number->string (module-export-fact-start fact))
                 "-"
                 (number->string (module-export-fact-end fact))))

;; Selector <- Fact
(def (macro-fact-selector fact)
  (string-append (macro-fact-path fact) ":"
                 (number->string (macro-fact-start fact))
                 "-"
                 (number->string (macro-fact-end fact))))

;; Selector <- Fact
(def (binding-fact-selector fact)
  (string-append (binding-fact-path fact) ":"
                 (number->string (binding-fact-start fact))
                 "-"
                 (number->string (binding-fact-end fact))))

;; Selector <- Fact
(def (poo-form-fact-selector fact)
  (string-append (poo-form-fact-path fact) ":"
                 (number->string (poo-form-fact-start fact))
                 "-"
                 (number->string (poo-form-fact-end fact))))

;; Selector <- Fact
(def (higher-order-fact-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

;; Selector <- ControlFlowFact
(def (control-flow-fact-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))

;; Selector <- PredicateFamilyFact
(def (predicate-family-fact-selector fact)
  (string-append (predicate-family-fact-path fact) ":"
                 (number->string (predicate-family-fact-start fact))
                 "-"
                 (number->string (predicate-family-fact-end fact))))

;; Selector <- FieldAccessPatternFact
(def (field-access-pattern-fact-selector fact)
  (string-append (field-access-pattern-fact-path fact) ":"
                 (number->string (field-access-pattern-fact-start fact))
                 "-"
                 (number->string (field-access-pattern-fact-end fact))))

;; Selector <- BooleanConditionFact
(def (boolean-condition-fact-selector fact)
  (string-append (boolean-condition-fact-path fact) ":"
                 (number->string (boolean-condition-fact-start fact))
                 "-"
                 (number->string (boolean-condition-fact-end fact))))

;; Selector <- LoopDriverFact
(def (loop-driver-fact-selector fact)
  (string-append (loop-driver-fact-path fact) ":"
                 (number->string (loop-driver-fact-start fact))
                 "-"
                 (number->string (loop-driver-fact-end fact))))

;; Selector <- DependencyAdapterQualityFact
(def (dependency-adapter-quality-fact-selector fact)
  (string-append (dependency-adapter-quality-fact-path fact) ":"
                 (number->string (dependency-adapter-quality-fact-start fact))
                 "-"
                 (number->string (dependency-adapter-quality-fact-end fact))))

;; Selector <- FunctionQualityProfile
(def (function-quality-profile-selector fact)
  (string-append (function-quality-profile-path fact) ":"
                 (number->string (function-quality-profile-start fact))
                 "-"
                 (number->string (function-quality-profile-end fact))))

;; Selector <- TypedContractFact
(def (typed-contract-fact-selector fact)
  (string-append (typed-contract-fact-path fact) ":"
                 (number->string (typed-contract-fact-comment-start fact))
                 "-"
                 (number->string (typed-contract-fact-comment-end fact))))

;; Selector <- CommentQualityFact
(def (comment-quality-fact-selector fact)
  (string-append (comment-quality-fact-path fact) ":"
                 (number->string (comment-quality-fact-comment-start fact))
                 "-"
                 (number->string (comment-quality-fact-comment-end fact))))

;; Selector <- Form
(def (top-form-selector form)
  (string-append (top-form-path form) ":"
                 (number->string (top-form-start form))
                 "-"
                 (number->string (top-form-end form))))

;;; Path normalization boundary:
;;; - Project paths are stored relative to the collected root.
;;; - Absolute selectors stay stable for CLI callers before becoming relpaths.
;; String <- String String
(def (relative-path root path)
  (let* ((root* (path-normalize root))
         (path* (path-normalize path))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; String <- String String
(def (source-full-path root path)
  (if (string-prefix? "/" path)
    (path-normalize path)
    (path-expand path root)))

;; NormalizeOwner <- String
(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))
