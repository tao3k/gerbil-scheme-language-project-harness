;;; -*- Gerbil -*-
;;; Parser selector and project aggregation helpers.

(import :gerbil/gambit
        :parser/model
        (only-in :std/srfi/13 string-prefix? string-suffix?))

(export project-definitions
        project-calls
        project-predicate-family-facts
        project-field-access-pattern-facts
        project-projection-burst-facts
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
        projection-burst-fact-selector
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
;; : (-> ProjectIndex (List Definition) )
(def (project-definitions index)
  (apply append (map source-file-definitions (project-index-files index))))

;;; Call aggregation preserves source-file order so selector and search packet
;;; output stay deterministic across project collection runs.
;; : (-> ProjectIndex (List CallFact) )
(def (project-calls index)
  (apply append (map source-file-calls (project-index-files index))))

;;; Predicate-family facts are already source-owned by the native parser.
;;; The project projection only flattens file buckets for policy and search.
;; : (-> ProjectIndex (List PredicateFamilyFact) )
(def (project-predicate-family-facts index)
  (apply append
         (map source-file-predicate-family-facts
              (project-index-files index))))

;;; Field-access facts must remain separate from predicate-family thresholds so
;;; agent repair can explain selector-helper evidence independently.
;; : (-> ProjectIndex (List FieldAccessPatternFact) )
(def (project-field-access-pattern-facts index)
  (apply append
         (map source-file-field-access-pattern-facts
              (project-index-files index))))

;;; Projection-burst facts are caller-scoped native evidence for output/projection walls.
;;; Policy consumers decide thresholds through detection profiles.
;; : (-> ProjectIndex (List ProjectionBurstFact) )
(def (project-projection-burst-facts index)
  (apply append
         (map source-file-projection-burst-facts
              (project-index-files index))))

;;; Boolean-condition facts keep individual predicate helpers queryable even
;;; when a family-level policy finding owns the repair decision.
;; : (-> ProjectIndex (List BooleanConditionFact) )
(def (project-boolean-condition-facts index)
  (apply append
         (map source-file-boolean-condition-facts
              (project-index-files index))))

;;; Loop-driver facts distinguish pure transform drift from IO/runtime driver
;;; boundaries before policy decides whether a named let should remain.
;; : (-> ProjectIndex (List LoopDriverFact) )
(def (project-loop-driver-facts index)
  (apply append
         (map source-file-loop-driver-facts
              (project-index-files index))))

;;; Dependency adapter facts expose define-type/protocol wrappers over imported
;;; dependency primitives before policy decides whether the boundary is strong.
;; : (-> ProjectIndex (List DependencyAdapterQualityFact) )
(def (project-dependency-adapter-quality-facts index)
  (apply append
         (map source-file-dependency-adapter-quality-facts
              (project-index-files index))))

;;; Function-quality profiles are the function-level join across parser fact families.
;;; Keep this projection first-class so repair planning can group by function.
;; : (-> ProjectIndex (List FunctionQualityProfile) )
(def (project-function-quality-profiles index)
  (apply append
         (map source-file-function-quality-profiles
              (project-index-files index))))

;;; Typed-contract facts are flattened after parsing so R013 can stay a policy
;;; consumer of native evidence rather than re-reading comment text.
;; : (-> ProjectIndex (List TypedContractFact) )
(def (project-typed-contract-facts index)
  (apply append
         (map source-file-typed-contract-facts
              (project-index-files index))))

;;; Comment-quality facts carry parser evidence for R015 repair prompts.
;;; Keeping this as a projection helper lets check, info, and search share the
;;; same native evidence list.
;; : (-> ProjectIndex (List CommentQualityFact) )
(def (project-comment-quality-facts index)
  (apply append
         (map source-file-comment-quality-facts
              (project-index-files index))))

;;; Owner lookup boundary:
;;; - Normalize user-facing owner paths before comparing parser-owned paths.
;;; - Keep parse-source-file independent from query selector policy.
;; : (-> ProjectIndex String SourceFile )
(def (find-owner index owner)
  (find (lambda (file) (equal? (source-file-path file) (normalize-owner owner)))
        (project-index-files index)))

;; : (-> Definition Selector )
(def (definition-selector defn)
  (string-append (definition-path defn) ":"
                 (number->string (definition-start defn))
                 "-"
                 (number->string (definition-end defn))))

;; : (-> CallFact Selector )
(def (call-fact-selector call)
  (string-append (call-fact-path call) ":"
                 (number->string (call-fact-start call))
                 "-"
                 (number->string (call-fact-end call))))

;; : (-> Fact Selector )
(def (module-import-fact-selector fact)
  (string-append (module-import-fact-path fact) ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

;; : (-> Fact Selector )
(def (module-export-fact-selector fact)
  (string-append (module-export-fact-path fact) ":"
                 (number->string (module-export-fact-start fact))
                 "-"
                 (number->string (module-export-fact-end fact))))

;; : (-> Fact Selector )
(def (macro-fact-selector fact)
  (string-append (macro-fact-path fact) ":"
                 (number->string (macro-fact-start fact))
                 "-"
                 (number->string (macro-fact-end fact))))

;; : (-> Fact Selector )
(def (binding-fact-selector fact)
  (string-append (binding-fact-path fact) ":"
                 (number->string (binding-fact-start fact))
                 "-"
                 (number->string (binding-fact-end fact))))

;; : (-> Fact Selector )
(def (poo-form-fact-selector fact)
  (string-append (poo-form-fact-path fact) ":"
                 (number->string (poo-form-fact-start fact))
                 "-"
                 (number->string (poo-form-fact-end fact))))

;; : (-> Fact Selector )
(def (higher-order-fact-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

;; : (-> ControlFlowFact Selector )
(def (control-flow-fact-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))

;; : (-> PredicateFamilyFact Selector )
(def (predicate-family-fact-selector fact)
  (string-append (predicate-family-fact-path fact) ":"
                 (number->string (predicate-family-fact-start fact))
                 "-"
                 (number->string (predicate-family-fact-end fact))))

;; : (-> FieldAccessPatternFact Selector )
(def (field-access-pattern-fact-selector fact)
  (string-append (field-access-pattern-fact-path fact) ":"
                 (number->string (field-access-pattern-fact-start fact))
                 "-"
                 (number->string (field-access-pattern-fact-end fact))))

;; : (-> ProjectionBurstFact Selector )
(def (projection-burst-fact-selector fact)
  (string-append (projection-burst-fact-path fact) ":"
                 (number->string (projection-burst-fact-start fact))
                 "-"
                 (number->string (projection-burst-fact-end fact))))

;; : (-> BooleanConditionFact Selector )
(def (boolean-condition-fact-selector fact)
  (string-append (boolean-condition-fact-path fact) ":"
                 (number->string (boolean-condition-fact-start fact))
                 "-"
                 (number->string (boolean-condition-fact-end fact))))

;; : (-> LoopDriverFact Selector )
(def (loop-driver-fact-selector fact)
  (string-append (loop-driver-fact-path fact) ":"
                 (number->string (loop-driver-fact-start fact))
                 "-"
                 (number->string (loop-driver-fact-end fact))))

;; : (-> DependencyAdapterQualityFact Selector )
(def (dependency-adapter-quality-fact-selector fact)
  (string-append (dependency-adapter-quality-fact-path fact) ":"
                 (number->string (dependency-adapter-quality-fact-start fact))
                 "-"
                 (number->string (dependency-adapter-quality-fact-end fact))))

;; : (-> FunctionQualityProfile Selector )
(def (function-quality-profile-selector fact)
  (string-append (function-quality-profile-path fact) ":"
                 (number->string (function-quality-profile-start fact))
                 "-"
                 (number->string (function-quality-profile-end fact))))

;; : (-> TypedContractFact Selector )
(def (typed-contract-fact-selector fact)
  (string-append (typed-contract-fact-path fact) ":"
                 (number->string (typed-contract-fact-comment-start fact))
                 "-"
                 (number->string (typed-contract-fact-comment-end fact))))

;; : (-> CommentQualityFact Selector )
(def (comment-quality-fact-selector fact)
  (string-append (comment-quality-fact-path fact) ":"
                 (number->string (comment-quality-fact-comment-start fact))
                 "-"
                 (number->string (comment-quality-fact-comment-end fact))))

;; : (-> Form Selector )
(def (top-form-selector form)
  (string-append (top-form-path form) ":"
                 (number->string (top-form-start form))
                 "-"
                 (number->string (top-form-end form))))

;;; Path normalization boundary:
;;; - Project paths are stored relative to the collected root.
;;; - Absolute selectors stay stable for CLI callers before becoming relpaths.
;; : (-> String String String )
(def (relative-path root path)
  (let* ((root* (canonical-root-path root))
         (path* (path-normalize (path-expand path root*)))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; : (-> String String )
(def (canonical-root-path root)
  (let (path (path-normalize (path-expand "" root)))
    (if (and (> (string-length path) 1)
             (string-suffix? "/" path))
      (substring path 0 (- (string-length path) 1))
      path)))

;; : (-> String String String )
(def (source-full-path root path)
  (if (string-prefix? "/" path)
    (path-normalize path)
    (path-expand path root)))

;; : (-> String NormalizeOwner )
(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))
