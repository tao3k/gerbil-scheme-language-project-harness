;;; -*- Gerbil -*-
;;; Agent guide command output.
;;; Boundary:
;;; - Owns agent-facing guide rows and source-excerpt routing.
;;; - guide --code must emit extracted comments plus code, not search packets.

(import :gerbil/gambit
        :commands/guide-sections
        :language/evidence
        :parser/facade
        :policy/catalog
        :support/args
        :support/io
        (only-in :std/misc/list length<=n? unique)
        (only-in :std/srfi/1 drop take)
        (only-in :std/srfi/13
                 string-join
                 string-contains
                 string-downcase
                 string-index
                 string-prefix?))

(export guide-lines
        guide-lines-for
        guide-code-lines
        guide-main
        print-guide)
;; : (-> (List String) (List String) )
(def (guide-lines-for args)
  (guide-section-lines-for args))

;; (List String)
(def (guide-lines)
  (guide-section-lines-for []))
;; : (-> (List String) Flag Boolean )
(def (arg-present? args flag)
  (and (member flag args) #t))
;;; Catalog route lookup: accept a full finding/rule fragment, then keep the
;;; first catalog-backed guide topic so guide and repair do not drift.
;; : (-> Rule RuleTopic )
(def (rule-topic rule)
  (and rule
       (let (matches
             (filter-map (lambda (rule-id)
                           (and (string-contains rule rule-id)
                                (agent-rule-guide-topic rule-id)))
                         (agent-steering-rule-ids)))
         (and (pair? matches) (car matches)))))
;; : (-> (List String) String )
(def (guide-intent args)
  (or (option "--intent" args)
      (option "--role" args)
      "study"))
;; : (-> String IntentTopic )
(def (intent-topic intent)
  (cond
   ((equal? intent "witness") "macro-runtime-source")
   (else #f)))
;; : (-> (List String) Topic )
(def (positional-topic args)
  (let (positionals (positional-args (drop-project-root args)))
    (and (pair? positionals) (car positionals))))
;; : (-> String Boolean )
(def (runtime-source-topic-token? topic)
  (or (equal? topic "macro")
      (equal? topic "runtime-source")
      (equal? topic "macro-runtime-source")))
;; : (-> (List String) Query )
(def (runtime-source-guide-query args)
  (or (option "--query" args)
      (let (positionals (positional-args (drop-project-root args)))
        (if (and (pair? positionals)
                 (runtime-source-topic-token? (car positionals)))
          (let (terms (cdr positionals))
            (if (null? terms) "macro" (string-join terms " ")))
          "macro"))))
;;; Canonicalization is the public guide compatibility layer: policy rules,
;;; user-facing topic aliases, and progressive exemplars can evolve without
;;; making callers learn every internal topic name.
;;; Boundary:
;;; - Add aliases only when they route to an existing source-backed exemplar.
;;; - Keep topic fallback stable so policy repair nextCommand rows remain valid.
;; : (-> String CanonicalTopic )
(def (canonical-topic topic)
  (cond
   ((or (equal? topic "poo") (equal? topic "poo-policy")) "poo-policy")
   ((or (equal? topic "functional") (equal? topic "functional-data-transform"))
    "functional-data-transform")
   ((or (equal? topic "typed") (equal? topic "typed-combinator")
        (equal? topic "typed-combinator-style")
        (equal? topic "combinator") (equal? topic "combinator-style"))
    "typed-combinator-style")
   ((member topic '("m3" "milestone-m3" "m3-policy-repair-loop" "policy-repair-loop"))
    "m3-policy-repair-loop")
   ((or (equal? topic "macro") (equal? topic "runtime-source")
        (equal? topic "macro-runtime-source"))
    "macro-runtime-source")
   ((or (equal? topic "controlled-branch-shape")
        (equal? topic "branch-shape")
        (equal? topic "match-readability"))
    "controlled-branch-shape")
   ((or (equal? topic "engineering-comment-quality")
        (equal? topic "comment-quality")
        (equal? topic "comments"))
    "engineering-comment-quality")
   ((or (equal? topic "predicate-family-combinator")
        (equal? topic "predicate-family")
        (equal? topic "field-access-pattern"))
    "predicate-family-combinator")
   ((or (equal? topic "dependency-protocol-adapter")
        (equal? topic "dependency-adapter")
        (equal? topic "protocol-adapter")
        (equal? topic "adapter-quality"))
    "dependency-protocol-adapter")
   ((or (equal? topic "explicit-precise-import")
        (equal? topic "precise-import")
        (equal? topic "only-in")
        (equal? topic "import-precision"))
    "explicit-precise-import")
   ((or (equal? topic "package-build-canonical-shape")
        (equal? topic "build-canonical-shape")
        (equal? topic "build.ss")
        (equal? topic "defbuild-script")
        (equal? topic "std/make"))
    "package-build-canonical-shape")
   (else "higher-order-control")))
;; : (-> (List String) String )
(def (guide-topic args)
  (canonical-topic
   (or (option "--topic" args)
       (rule-topic (option "--rule" args))
       (rule-topic (option "--finding" args))
       (intent-topic (guide-intent args))
       (positional-topic args)
       "typed-combinator-style")))
;; : (-> (List String) String )
(def (guide-level args)
  (or (option "--level" args) "normal"))
;; : (-> Level Boolean )
(def (advanced-level? level)
  (or (equal? level "advanced") (equal? level "full")))
;; emit-exemplar-source
;;   : (-> String String (List Symbol) Boolean Unit)
;;   | doc m%
;;       `emit-exemplar-source root owner symbols include-file-comment?` prints
;;       the requested exemplar definitions from an owner source file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-exemplar-source "." "src/parser/support.ss" '(datum-list-items) #t)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-exemplar-source root owner symbols include-file-comment?)
  (let* ((index (collect-project root))
         (file (guide-source-file index owner)))
    (when include-file-comment?
      (let (comment (read-source-file-purpose-comment root owner))
        (when (not (string=? comment ""))
          (display comment)
          (newline))))
    (emit-definition-exemplar-sources
     root
     (map (lambda (symbol)
            (guide-definition file owner symbol))
          symbols))))
;; emit-definition-exemplar-sources
;;   : (-> String (List Definition) Unit)
;;   | doc m%
;;       `emit-definition-exemplar-sources root definitions` prints each
;;       exemplar definition with its leading comments, separated by blank
;;       definition boundaries.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-definition-exemplar-sources "." [])
;;       ;; => (void)
;;       ```
;;     %
(def (emit-definition-exemplar-sources root definitions)
  (display
   (string-join (map (cut read-definition-with-leading-comments root <>)
                     definitions)
                "\n")))
;; guide-source-file
;;   : (-> ProjectIndex String SourceFile)
;;   | doc m%
;;       `guide-source-file index owner` returns the indexed source file for
;;       the requested owner path, or fails with owner context.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-file-path (guide-source-file index "src/orders/core.ss"))
;;       ;; => "src/orders/core.ss"
;;       ```
;;     %
(def (guide-source-file index owner)
  (or (find (lambda (file) (equal? (source-file-path file) owner))
            (project-index-files index))
      (error "guide exemplar owner not found" owner)))
;; guide-definition
;;   : (-> SourceFile String Symbol Definition)
;;   | doc m%
;;       `guide-definition file owner symbol` returns the named definition from
;;       the source file, or fails with owner and symbol context.
;;
;;       # Examples
;;
;;       ```scheme
;;       (definition-name (guide-definition file "src/orders/core.ss" 'order-total))
;;       ;; => "order-total"
;;       ```
;;     %
(def (guide-definition file owner symbol)
  (or (find (lambda (defn) (equal? (definition-name defn) symbol))
            (source-file-definitions file))
      (error "guide exemplar definition not found" owner symbol)))
;; : (-> String (List HigherOrderFact) )
(def (emit-higher-order-exemplar-source root)
  (emit-exemplar-source root
                         "src/checker/arity.ss"
                         ["call-arity-finding/known-signature"
                          "run-arity-checks"]
                         #t))
;; : (-> String Unit )
(def (emit-typed-combinator-style-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-style.ss"
                         ["typed-combinator-style-findings"
                          "typed-combinator-style-function-definitions"
                          "typed-combinator-style-evidence-callers"]
                         #f))
;; : (-> String Unit )
(def (emit-typed-combinator-style-more-source root)
  (emit-exemplar-source root
                         "src/policy/agent.ss"
                         ["functional-idiom-advice-findings"]
                         #f))
;; : (-> String Unit )
(def (emit-poo-policy-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/poo.ss"
                         ["poo-form-facts-from-form"]
                         #t))
;; : (-> RuntimeSourceQuery Unit )
(def (emit-macro-runtime-source-exemplar-source query)
  (emit-runtime-source-exemplar-source query 0 1))
;;; Boundary:
;;; - Emit only source/comment text selected from runtime-source acquisition facts.
;;; - Keep search packet rows out of guide --code output.
;; : (-> RuntimeSourceQuery StartIndex Limit Unit )
(def (emit-runtime-source-exemplar-source query start limit)
  (let* ((examples (runtime-source-examples query))
         (candidate-sources
          (filter-map runtime-source-example-source
                      (if (>= (length examples) start)
                        (drop examples start)
                        '())))
         (sources (if (length<=n? candidate-sources limit)
                    candidate-sources
                    (take candidate-sources limit))))
    (if (pair? sources)
      (display (string-join sources "\n"))
      (error "runtime-source exemplar selector did not resolve" query))))
;;; Intent:
;;; - Prefer runtime examples that carry source comment extraction evidence.
;;; - Preserve the acquisition packet order for examples without comments.
;; : (-> RuntimeSourceQuery (List RuntimeSourceExample) )
(def (runtime-source-examples query)
  (let* ((facts (filter (lambda (fact)
                          (evidence-fact-matches-query? fact query))
                        (runtime-source-facts)))
         (fact (and (pair? facts) (car facts)))
         (details (if fact (hash-get fact 'details) (hash))))
    (if (and fact (hash-key? details 'sourceExamples))
      (prioritize-runtime-source-examples
       (hash-get details 'sourceExamples)
       (if (hash-key? details 'sourceComments)
         (hash-get details 'sourceComments)
         []))
      [])))
;;; Boundary:
;;; - Comment-backed selectors teach agents the code plus nearby rationale first.
;;; - Un-commented examples remain available through progressive --more output.
;; : (-> (List RuntimeSourceExample) (List SourceComment) (List RuntimeSourceExample) )
(def (prioritize-runtime-source-examples examples comments)
  (let* ((selectors (filter-map (cut hash-get <> 'selector) comments))
         (commented (filter (lambda (example)
                              (member (hash-get example 'selector) selectors))
                            examples))
         (rest (filter (lambda (example)
                         (not (member (hash-get example 'selector) selectors)))
                       examples)))
    (append commented rest)))
;; : (-> Fact Query Boolean )
(def (evidence-fact-matches-query? fact query)
  (let ((haystack (string-join (hash-get fact 'terms) " "))
        (q (string-downcase query)))
    (or (string=? query "")
        (string-contains (string-downcase haystack) q))))
;;; Boundary:
;;; - Resolve gerbil-runtime-source selectors through the active runtime tree.
;;; - Do not fall back to local harness examples when runtime source is absent.
;; : (-> RuntimeSourceExample SourceText )
(def (runtime-source-example-source example)
  (let* ((selector (hash-get example 'selector))
         (parts (runtime-source-selector-parts selector)))
    (and parts
         (let* ((relpath (car parts))
                (symbol (cadr parts))
                (root (runtime-source-root-for relpath)))
           (and root
                (runtime-source-symbol-source root relpath symbol))))))
;;; Selector grammar is owned by selectorResolver.output in runtime-source facts.
;;; Keep parsing exact so malformed selectors surface as unresolved evidence.
;; : (-> RuntimeSourceSelector SelectorParts )
(def (runtime-source-selector-parts selector)
  (let* ((prefix "gerbil-runtime-source://")
         (prefix-len (string-length prefix)))
    (and (string? selector)
         (string-prefix? prefix selector)
         (let* ((body (substring selector prefix-len (string-length selector)))
                (hash-index (string-index body #\#)))
           (and hash-index
                [(substring body 0 hash-index)
                 (substring body (fx1+ hash-index) (string-length body))])))))
;; : (-> Relpath RuntimeSourceRoot )
(def (runtime-source-root-for relpath)
  (find (lambda (root)
          (file-exists? (path-expand relpath root)))
        (runtime-source-root-candidates)))
;; (List RuntimeSourceRoot)
(def (runtime-source-root-candidates)
  (unique
   (filter-map
    (lambda (path)
      (and path (path-normalize path)))
    (append
     [(gerbil-home)
      (path-expand ".." (gerbil-home))
      (path-expand "../.." (gerbil-home))]
     (runtime-source-ancestor-candidates)))))
;;; Self-apply often runs from a brewed runtime whose GERBIL_HOME contains only
;;; compiled artifacts. The source checkout remains ASP-managed under .data, so
;;; guide --code can resolve selectors without leaking local paths in packets.
;; (List RuntimeSourceRoot)
(def (runtime-source-ancestor-candidates)
  (filter file-directory?
          (map (cut path-expand ".data/gerbil" <>)
               (runtime-source-ancestor-directories))))

;;; Boundary:
;;; - Runtime source lookup is bounded to a small parent chain.
;;; - The explicit chain avoids open-ended filesystem walks in guide --code.
;; (List Directory)
(def (runtime-source-ancestor-directories)
  (let* ((d0 (path-normalize (current-directory)))
         (d1 (runtime-source-parent-directory d0))
         (d2 (runtime-source-parent-directory d1))
         (d3 (runtime-source-parent-directory d2))
         (d4 (runtime-source-parent-directory d3))
         (d5 (runtime-source-parent-directory d4))
         (d6 (runtime-source-parent-directory d5))
         (d7 (runtime-source-parent-directory d6))
         (d8 (runtime-source-parent-directory d7)))
    (unique [d0 d1 d2 d3 d4 d5 d6 d7 d8])))

;; : (-> Directory Directory )
(def (runtime-source-parent-directory dir)
  (path-normalize (path-expand ".." dir)))
;;; Boundary:
;;; - Prefer parser-owned definitions before top-form fallback for macro-rule forms.
;;; - Both paths use source ranges from the native parser.
;; : (-> RuntimeSourceRoot Relpath Symbol SourceText )
(def (runtime-source-symbol-source root relpath symbol)
  (let* ((file (parse-source-file root relpath))
         (definition (find (lambda (defn)
                             (equal? (definition-name defn) symbol))
                           (source-file-definitions file))))
    (cond
     (definition
      (read-definition-with-leading-comments root definition))
     (else
      (runtime-source-top-form-source root file symbol)))))
;;; Top-form fallback covers macro-form exemplars where the selector names the form head.
;;; Definition selectors must be handled before this branch.
;; : (-> RuntimeSourceRoot SourceFile Symbol SourceText )
(def (runtime-source-top-form-source root file symbol)
  (let (form (find (lambda (form)
                    (or (equal? (top-form-head form) symbol)
                        (equal? (top-form-head form)
                                (string-append "(" symbol))))
                  (source-file-forms file)))
    (and form
         (read-line-range (path-expand (source-file-path file) root)
                          (top-form-start form)
                          (top-form-end form)))))
;; : (-> String Unit )
(def (emit-controlled-branch-shape-exemplar-source root)
  (emit-exemplar-source root
                         "src/commands/search-render.ss"
                         ["ranked-syntax-facts"
                          "select-ranked-syntax-facts"]
                         #t))
;; : (-> String Unit )
(def (emit-engineering-comment-quality-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-comment.ss"
                         ["comment-quality-details"
                          "comment-quality-fact-summary"
                          "weak-required-comment-quality-fact?"]
                         #f))
;; : (-> String Unit )
(def (emit-predicate-family-combinator-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/quality-shape.ss"
                         ["predicate-family-facts-from-source"
                          "field-access-pattern-facts-from-source"]
                         #t))
;; SourceRelpath
(def +poo-rationaldict-exemplar-relpath+
  ".gerbil/pkg/git.cons.io/mighty-gerbils/gerbil-poo/rationaldict.ss")

;;; Boundary:
;;; - R017 default guidance is sourced from the dependency adapter itself.
;;; - The resolver stays bounded to the active workspace and its parent chain.
;; : (-> String Unit )
(def (emit-poo-rationaldict-exemplar-source root)
  (let (source-root (poo-rationaldict-exemplar-root root))
    (if source-root
      (emit-external-exemplar-source source-root
                                     +poo-rationaldict-exemplar-relpath+
                                     ["RationalDict." "RationalSet"])
      (error "POO rationaldict exemplar source not found"
             +poo-rationaldict-exemplar-relpath+))))

;;; Boundary:
;;; - External package exemplars are parsed by the same native parser.
;;; - This keeps guide --code source-backed without copying dependency code.
;; : (-> String Relpath (List Symbol) Unit )
(def (emit-external-exemplar-source root relpath symbols)
  (let (file (parse-source-file root relpath))
    (emit-definition-exemplar-sources
     root
     (map (lambda (symbol)
            (guide-definition file relpath symbol))
          symbols))))

;;; Intent:
;;; - Resolve the source root for the package-owned R017 exemplar.
;;; Data flow:
;;; - find checks the workspace candidate before parent cache candidates.
;;; - The lambda probes only the exact rationaldict source path.
;;; Invariant:
;;; - Keep lookup non-recursive so guide --code remains deterministic.
;; : (-> String MaybeRoot )
(def (poo-rationaldict-exemplar-root root)
  (find (lambda (candidate)
          (file-exists?
           (path-expand +poo-rationaldict-exemplar-relpath+ candidate)))
        (unique
         (append [root (current-directory)]
                 (runtime-source-ancestor-directories)))))

;; : (-> String Unit )
(def (emit-dependency-protocol-adapter-exemplar-source root)
  (emit-exemplar-source root
                         "src/parser/dependency-adapter-quality.ss"
                         ["dependency-adapter-quality-facts-from-candidates"
                          "dependency-adapter-derived-capabilities"
                          "dependency-adapter-manual-object-encoding-risk"
                          "dependency-adapter-quality-facets"]
                         #t))
;; : (-> String Unit )
(def (emit-explicit-precise-import-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-import.ss"
                         ["explicit-precise-import-finding"
                          "imprecise-runtime-import?"
                          "explicit-precise-import-details"]
                         #t))
;; : (-> String Unit )
(def (emit-package-build-canonical-shape-exemplar-source root)
  (emit-exemplar-source root
                         "src/policy/agent-build.ss"
                         ["package-build-canonical-shape-finding"
                          "package-build-spec-call?"
                          "package-build-manual-compiler-dispatch-call?"]
                         #t))
;;; Dispatch boundary: normalized topics route only to source-backed exemplar owners.
;; : (-> String String String Unit )
(def (emit-topic-exemplar-source topic root runtime-source-query)
  (cond
   ((or (equal? topic "higher-order-control")
        (equal? topic "functional-data-transform"))
    (emit-higher-order-exemplar-source root))
   ((member topic '("typed-combinator-style" "m3-policy-repair-loop"))
    (emit-typed-combinator-style-exemplar-source root))
   ((equal? topic "poo-policy")
    (emit-poo-policy-exemplar-source root))
   ((equal? topic "macro-runtime-source")
    (emit-macro-runtime-source-exemplar-source runtime-source-query))
   ((equal? topic "controlled-branch-shape")
    (emit-controlled-branch-shape-exemplar-source root))
   ((equal? topic "engineering-comment-quality")
    (emit-engineering-comment-quality-exemplar-source root))
   ((equal? topic "predicate-family-combinator")
    (emit-predicate-family-combinator-exemplar-source root))
   ((equal? topic "dependency-protocol-adapter")
    (emit-poo-rationaldict-exemplar-source root))
   ((equal? topic "explicit-precise-import")
    (emit-explicit-precise-import-exemplar-source root))
   ((equal? topic "package-build-canonical-shape")
    (emit-package-build-canonical-shape-exemplar-source root))
   (else
    (emit-higher-order-exemplar-source root))))
;;; Boundary:
;;; - emit-progressive-exemplar-source coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> String String Advanced String Unit )
(def (emit-progressive-exemplar-source topic root advanced? runtime-source-query)
  (cond
   ((or (equal? topic "higher-order-control")
        (equal? topic "functional-data-transform"))
    (newline)
    (emit-poo-policy-exemplar-source root)
    (when advanced?
      (newline)
      (emit-macro-runtime-source-exemplar-source runtime-source-query)))
   ((member topic '("typed-combinator-style" "m3-policy-repair-loop"))
    (newline)
    (emit-typed-combinator-style-more-source root)
    (when advanced?
      (newline)
      (emit-poo-policy-exemplar-source root)))
   ((equal? topic "poo-policy")
    (newline)
    (emit-higher-order-exemplar-source root)
    (when advanced?
      (newline)
      (emit-macro-runtime-source-exemplar-source runtime-source-query)))
   ((equal? topic "macro-runtime-source")
    (newline)
    (emit-runtime-source-exemplar-source runtime-source-query 1 1)
    (when advanced?
      (newline)
      (emit-higher-order-exemplar-source root)))
   ((equal? topic "controlled-branch-shape")
    (newline)
    (emit-typed-combinator-style-exemplar-source root)
    (when advanced?
      (newline)
      (emit-higher-order-exemplar-source root)))
   ((equal? topic "engineering-comment-quality")
    (newline)
    (emit-typed-combinator-style-exemplar-source root)
    (when advanced?
      (newline)
      (emit-controlled-branch-shape-exemplar-source root)))
   ((equal? topic "predicate-family-combinator")
    (newline)
    (emit-controlled-branch-shape-exemplar-source root)
    (when advanced?
      (newline)
      (emit-typed-combinator-style-exemplar-source root)))
   ((equal? topic "dependency-protocol-adapter")
    (newline)
    (emit-dependency-protocol-adapter-exemplar-source root)
    (when advanced?
      (newline)
      (emit-typed-combinator-style-exemplar-source root)))
   ((equal? topic "package-build-canonical-shape")
    (newline)
    (emit-explicit-precise-import-exemplar-source root)
    (when advanced?
      (newline)
      (emit-higher-order-exemplar-source root)))
   (else
    (newline)
    (emit-poo-policy-exemplar-source root))))
;; : (-> (List String) String )
(def (default-guide-source-root args)
  (cond
   ((option "--workspace" args) => values)
   ((file-directory? "src") ".")
   ((file-directory? "languages/gerbil-scheme-language-project-harness/src")
    "languages/gerbil-scheme-language-project-harness")
   (else (project-root args))))
;; : (-> (List String) String )
(def (guide-code-lines args)
  (let* ((topic (guide-topic args))
         (selector (option "--selector" args))
         (root (default-guide-source-root args))
         (runtime-source-query (runtime-source-guide-query args))
         (advanced? (advanced-level? (guide-level args)))
         (more? (or (arg-present? args "--more") advanced?)))
    (cond
     (selector
      (display (read-selector root selector)))
     (else
      (emit-topic-exemplar-source topic root runtime-source-query)
      (when more?
        (emit-progressive-exemplar-source topic root advanced? runtime-source-query)))))
  [])
;; : (-> (List String) Unit )
(def (print-guide . maybe-args)
  (let (args (if (pair? maybe-args) (car maybe-args) []))
    (for-each displayln (guide-lines-for args))))
;; : (-> (List String) String )
(def (print-guide-code args)
  (guide-code-lines args))
;; : (-> (List String) String )
(def (guide-main args)
  (if (arg-present? args "--code")
    (print-guide-code args)
    (print-guide args))
  0)
