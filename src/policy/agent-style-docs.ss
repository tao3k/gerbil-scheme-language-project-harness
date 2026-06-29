;;; -*- Gerbil -*-
;;; Typed-combinator documentation and invalid-contract detail helpers.

(import :parser/facade
        :policy/agent-support
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 take)
        (only-in :std/sugar cut filter filter-map hash hash-get ormap))

(export typed-combinator-style-missing-doc-targets
        file-typed-contract-invalid-reasons
        file-typed-contract-invalid-examples)

;; (List Role)
(def +typed-combinator-style-doc-required-roles+
  '("macro-helper" "protocol-method" "poo-protocol-boundary"))

;; (List QualityFacet)
(def +typed-combinator-style-doc-required-facets+
  '("macro-runtime-source-witness" "poo-protocol-evidence"
    "loop-driver-classified"))

;;; Documentation target boundary:
;;; - Merge function-profile and macro evidence into one target list.
;;; - Each source of evidence remains parser-owned before this aggregation.
;; : (-> SourceFile (List String) )
(def (typed-combinator-style-missing-doc-targets file)
  (unique
   (append
    (filter-map (cut typed-combinator-style-profile-missing-doc-target file <>)
                (source-file-function-quality-profiles file))
    (filter-map (cut typed-combinator-style-macro-missing-doc-target file <>)
                (source-file-macros file)))))

;;; Profile target boundary:
;;; - Return the public helper name only when docs are required and absent.
;;; - The caller owns de-duplication across function and macro evidence.
;; : (-> SourceFile FunctionQualityProfile MaybeTargetName )
(def (typed-combinator-style-profile-missing-doc-target file profile)
  (and (typed-combinator-style-profile-requires-doc? profile)
       (not (typed-combinator-style-profile-has-doc? file profile))
       (function-quality-profile-name profile)))

;;; Profile requirement boundary:
;;; - Arity-bearing helpers need docs only when role or exported risk warrants it.
;;; - This keeps routine exported accessors on the short typed-comment path.
;; : (-> FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-requires-doc? profile)
  (and (> (function-quality-profile-arity profile) 0)
       (or (member (function-quality-profile-role profile)
                   +typed-combinator-style-doc-required-roles+)
           (and (function-quality-profile-exported profile)
                (typed-combinator-style-profile-doc-required-facet? profile)))))

;;; Boundary:
;;; - Facet-driven doc requirements come from parser-owned quality evidence.
;;; - This keeps R013 extensible without hard-coding path-specific policy exceptions.
;; : (-> FunctionQualityProfile Boolean)
(def (typed-combinator-style-profile-doc-required-facet? profile)
  (ormap (lambda (facet)
           (member facet
                   (function-quality-profile-quality-facets profile)))
         +typed-combinator-style-doc-required-facets+))

;;; Profile doc lookup:
;;; - A profile is documented only by its own adjacent typed contract.
;;; - Other module comments cannot satisfy helper-level public docs.
;; : (-> SourceFile FunctionQualityProfile Boolean )
(def (typed-combinator-style-profile-has-doc? file profile)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (function-quality-profile-name profile)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (function-quality-profile-name profile)))))

;;; Macro target boundary:
;;; - Macro facts carry their own public names.
;;; - Missing docs are reported at the macro boundary, not runtime helpers.
;; : (-> SourceFile MacroFact MaybeTargetName )
(def (typed-combinator-style-macro-missing-doc-target file macro)
  (and (not (typed-combinator-style-macro-has-doc? file macro))
       (macro-fact-name macro)))

;;; Macro doc lookup:
;;; - Macro documentation must be owned by the macro's typed contract.
;;; - This prevents runtime helper comments from hiding macro expansion risk.
;; : (-> SourceFile MacroFact Boolean )
(def (typed-combinator-style-macro-has-doc? file macro)
  (let (fact
        (typed-combinator-style-typed-contract-fact
         file
         (macro-fact-name macro)))
    (and fact
         (typed-combinator-style-typed-comment-has-full-doc?
          fact
          (macro-fact-name macro)))))

;;; Boundary:
;;; - Typed contract lookup is keyed by parser-owned definition name.
;;; - Policy must not scan source text to decide whether docs are complete.
;; : (-> SourceFile String MaybeTypedContractFact )
(def (typed-combinator-style-typed-contract-fact file name)
  (find (lambda (fact)
          (equal? (typed-contract-fact-definition-name fact) name))
        (source-file-typed-contract-facts file)))

;;; Full-doc boundary:
;;; - Ownership and doc completeness are both required.
;;; - This prevents a complete doc block for the wrong helper from passing.
;; : (-> TypedContractFact String Boolean)
(def (typed-combinator-style-typed-comment-has-full-doc? fact expected-name)
  (let (typed-comment (typed-contract-fact-typed-comment fact))
    (and (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
         (typed-combinator-style-docs-complete
          (typed-combinator-style-typed-comment-docs typed-comment)))))

;;; Ownership checks stay separate from documentation content so policy can
;;; explain whether a full-form block is missing or merely incomplete.
;; : (-> TypedCommentMetadata String Boolean)
(def (typed-combinator-style-typed-comment-owned? typed-comment expected-name)
  (and typed-comment
       (hash-get typed-comment 'fullForm)
       (equal? (hash-get typed-comment 'leadingName) expected-name)))

;;; Typed-comment docs are projected once from parser metadata; downstream
;;; body/example predicates consume the list without reaching back into hashes.
;; : (-> TypedCommentMetadata (List Json))
(def (typed-combinator-style-typed-comment-docs typed-comment)
  (or (hash-get typed-comment 'docs) []))

;;; Completeness is an aggregator over the two public doc evidence predicates.
;;; It is deliberately not a `?` helper so R016 does not treat it as another
;;; predicate-family member over `docs`.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-complete docs)
  (and (typed-combinator-style-docs-have-body? docs)
       (typed-combinator-style-docs-have-result-example? docs)))

;;; Boundary:
;;; - Documentation body evidence comes from typed-comment metadata.
;;; - Empty `| doc` sections cannot satisfy public helper documentation.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-body? docs)
  (ormap (lambda (doc)
           (let (body (or (hash-get doc 'body) ""))
             (not (blank-string? body))))
         docs))

;;; Boundary:
;;; - Result examples prove the doc block carries repair-checkable output.
;;; - Accept either section-level result evidence or parsed example packets.
;; : (-> (List Json) Boolean)
(def (typed-combinator-style-docs-have-result-example? docs)
  (ormap (lambda (doc)
           (or (hash-get doc 'hasResultExamples)
               (ormap typed-combinator-style-example-has-result?
                      (or (hash-get doc 'examples) []))))
         docs))

;;; Example result boundary:
;;; - A parsed result marker is enough evidence for repair-checkable docs.
;;; - Body-only examples remain incomplete for public helper guidance.
;; : (-> Json Boolean)
(def (typed-combinator-style-example-has-result? example)
  (if (hash-get example 'hasExpectedResult) #t #f))

;;; Boundary:
;;; - file-typed-contract-invalid-reasons composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractReason) )
(def (file-typed-contract-invalid-reasons file)
  (unique
   (apply append
          (map typed-contract-fact-reasons
               (filter invalid-typed-contract-fact?
                       (source-file-typed-contract-facts file))))))

;;; Boundary:
;;; - file-typed-contract-invalid-examples composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> SourceFile (List InvalidContractExample) )
(def (file-typed-contract-invalid-examples file)
  (let (facts (filter invalid-typed-contract-fact?
                      (source-file-typed-contract-facts file)))
    (map typed-contract-fact-example
         (take facts (min 3 (length facts))))))

;;; Invalid-contract predicate:
;;; - Typed contract quality is parser-owned.
;;; - Policy filters by the public quality field instead of re-parsing text.
;; : (-> TypedContractFact Boolean )
(def (invalid-typed-contract-fact? fact)
  (equal? (typed-contract-fact-quality fact) "invalid"))

;;; Invalid-contract packet:
;;; - Preserve compact parser evidence for agent repair.
;;; - The packet avoids source snippets while keeping selector and reason detail.
;; : (-> TypedContractFact InvalidContractExample )
(def (typed-contract-fact-example fact)
  (hash (definition (typed-contract-fact-definition-name fact))
        (selector (typed-contract-fact-selector fact))
        (contract (typed-contract-fact-contract fact))
        (tokens (typed-contract-fact-tokens fact))
        (quality (typed-contract-fact-quality fact))
        (reasons (typed-contract-fact-reasons fact))
        (arrowCount (typed-contract-fact-arrow-count fact))
        (groupCount (typed-contract-fact-group-count fact))))
