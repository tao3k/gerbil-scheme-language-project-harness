;;; Boundary: this command resolves a compact guide receipt from parser-owned
;;; topics and selectors; it does not implement search or policy decisions.

(import :gerbil/gambit
        :gslph/src/commands/guide-sections
        :gslph/src/language/evidence
        :gslph/src/parser/facade
        :gslph/src/policy/catalog
        :gslph/src/support/args
        :gslph/src/support/io
        (only-in :std/misc/list length<=n? unique)
        (only-in :std/srfi/1 drop take)
        (only-in :std/srfi/13
                 string-join
                 string-contains
                 string-downcase
                 string-index
                 string-prefix?))
(export guide-lines guide-lines-for guide-code-lines guide-main print-guide)
(def (guide-lines-for args) (guide-section-lines-for args))
(def (guide-lines) (guide-section-lines-for []))
(def (arg-present? args flag) (and (member flag args) #t))
(def (rule-topic rule)
     (and rule
          (let (matches
                (filter-map
                 (lambda (rule-id)
                   (and (string-contains rule rule-id)
                        (agent-rule-guide-topic rule-id)))
                 (agent-steering-rule-ids)))
            (and (pair? matches) (car matches)))))
(def (guide-intent args)
     (or (option "--intent" args) (option "--role" args) "study"))
(def (intent-topic intent)
     (cond ((equal? intent "witness") "macro-runtime-source") (else #f)))
(def (positional-topic args)
     (let (positionals (positional-args (drop-project-root args)))
       (and (pair? positionals) (car positionals))))
(def (runtime-source-topic-token? topic)
     (or (equal? topic "macro")
         (equal? topic "runtime-source")
         (equal? topic "macro-runtime-source")))
(def (runtime-source-guide-query args)
     (or (option "--query" args)
         (let (positionals (positional-args (drop-project-root args)))
           (if (and (pair? positionals)
                    (runtime-source-topic-token? (car positionals)))
               (let (terms (cdr positionals))
                 (if (null? terms) "macro" (string-join terms " ")))
               "macro"))))
(def (canonical-topic topic)
     (cond ((or (equal? topic "poo") (equal? topic "poo-policy")) "poo-policy")
           ((or (equal? topic "functional")
                (equal? topic "functional-data-transform"))
            "functional-data-transform")
           ((or (equal? topic "typed")
                (equal? topic "typed-combinator")
                (equal? topic "typed-combinator-style")
                (equal? topic "combinator")
                (equal? topic "combinator-style"))
            "typed-combinator-style")
           ((member topic
                    '("m3"
                      "milestone-m3"
                      "m3-policy-repair-loop"
                      "policy-repair-loop"))
            "m3-policy-repair-loop")
           ((or (equal? topic "macro")
                (equal? topic "runtime-source")
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
(def (guide-topic args)
     (canonical-topic
      (or (option "--topic" args)
          (rule-topic (option "--rule" args))
          (rule-topic (option "--finding" args))
          (intent-topic (guide-intent args))
          (positional-topic args)
          "typed-combinator-style")))
(def (guide-level args) (or (option "--level" args) "normal"))
(def (advanced-level? level)
     (or (equal? level "advanced") (equal? level "full")))
(def (emit-exemplar-source root owner symbols include-file-comment?)
     (let* ((index (collect-project root))
            (file (guide-source-file index owner)))
       (when include-file-comment?
         (let (comment (read-source-file-purpose-comment root owner))
           (when (not (string=? comment "")) (display comment) (newline))))
       (emit-definition-exemplar-sources
        root
        (map (lambda (symbol) (guide-definition file owner symbol)) symbols))))
(def (emit-definition-exemplar-sources root definitions)
     (display (string-join
               (map (cut read-definition-with-leading-comments root <>)
                    definitions)
               "\n")))
(def (guide-source-file index owner)
     (or (find (lambda (file) (equal? (source-file-path file) owner))
               (project-index-files index))
         (error "guide exemplar owner not found" owner)))
(def (guide-definition file owner symbol)
     (or (find (lambda (defn) (equal? (definition-name defn) symbol))
               (source-file-definitions file))
         (error "guide exemplar definition not found" owner symbol)))
(def (emit-higher-order-exemplar-source root)
     (emit-exemplar-source
      root
      "src/policy/agent.ss"
      ["functional-idiom-advice-findings"]
      #t))
(def (emit-typed-combinator-style-exemplar-source root)
     (emit-exemplar-source
      root
      "src/policy/agent-style.ss"
      ["typed-combinator-style-findings"
       "typed-combinator-style-function-definitions"
       "typed-combinator-style-evidence-callers"]
      #f))
(def (emit-typed-combinator-style-more-source root)
     (emit-exemplar-source
      root
      "src/policy/agent.ss"
      ["functional-idiom-advice-findings"]
      #f))
(def (emit-poo-policy-exemplar-source root)
     (emit-exemplar-source
      root
      "src/parser/poo.ss"
      ["poo-form-facts-from-form"]
      #t))
(def (emit-macro-runtime-source-exemplar-source query)
     (emit-runtime-source-exemplar-source query 0 1))
(def (emit-runtime-source-exemplar-source query start limit)
     (let* ((examples (runtime-source-examples query))
            (candidate-sources
             (filter-map
              runtime-source-example-source
              (if (>= (length examples) start) (drop examples start) '())))
            (sources (if (length<=n? candidate-sources limit)
                         candidate-sources
                         (take candidate-sources limit))))
       (if (pair? sources)
           (display (string-join sources "\n"))
           (error "runtime-source exemplar selector did not resolve" query))))
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
(def (prioritize-runtime-source-examples examples comments)
     (let* ((selectors (filter-map (cut hash-get <> 'selector) comments))
            (commented
             (filter (lambda (example)
                       (member (hash-get example 'selector) selectors))
                     examples))
            (rest (filter (lambda (example)
                            (not (member (hash-get example 'selector)
                                         selectors)))
                          examples)))
       (append commented rest)))
(def (evidence-fact-matches-query? fact query)
     (let ((haystack (string-join (hash-get fact 'terms) " "))
           (q (string-downcase query)))
       (or (string=? query "")
           (string-contains (string-downcase haystack) q))))
(def (runtime-source-example-source example)
     (let* ((selector (hash-get example 'selector))
            (parts (runtime-source-selector-parts selector)))
       (and parts
            (let* ((relpath (car parts))
                   (symbol (cadr parts))
                   (root (runtime-source-root-for relpath)))
              (and root (runtime-source-symbol-source root relpath symbol))))))
(def (runtime-source-selector-parts selector)
     (let* ((prefix "gerbil-runtime-source://")
            (prefix-len (string-length prefix)))
       (and (string? selector)
            (string-prefix? prefix selector)
            (let* ((body (substring
                          selector
                          prefix-len
                          (string-length selector)))
                   (hash-index (string-index body #\#)))
              (and hash-index
                   [(substring body 0 hash-index)
                    (substring
                     body
                     (fx1+ hash-index)
                     (string-length body))])))))
(def (runtime-source-root-for relpath)
     (find (lambda (root) (file-exists? (path-expand relpath root)))
           (runtime-source-root-candidates)))
(def (runtime-source-root-candidates)
     (unique (filter-map
              (lambda (path) (and path (path-normalize path)))
              (append [(gerbil-home)
                       (path-expand ".." (gerbil-home))
                       (path-expand "../.." (gerbil-home))]
                      (runtime-source-ancestor-candidates)))))
(def (runtime-source-ancestor-candidates)
     (filter file-directory?
             (map (cut path-expand ".data/gerbil" <>)
                  (runtime-source-ancestor-directories))))
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
(def (runtime-source-parent-directory dir)
     (path-normalize (path-expand ".." dir)))
(def (runtime-source-symbol-source root relpath symbol)
     (let* ((file (parse-source-file root relpath))
            (definition
             (find (lambda (defn) (equal? (definition-name defn) symbol))
                   (source-file-definitions file))))
       (cond (definition
              (read-definition-with-leading-comments root definition))
             (else (runtime-source-top-form-source root file symbol)))))
(def (runtime-source-top-form-source root file symbol)
     (let (form
           (find (lambda (form)
                   (or (equal? (top-form-head form) symbol)
                       (equal? (top-form-head form)
                               (string-append "(" symbol))))
                 (source-file-forms file)))
       (and form
            (read-line-range
             (path-expand (source-file-path file) root)
             (top-form-start form)
             (top-form-end form)))))
(def (emit-controlled-branch-shape-exemplar-source root)
     (emit-exemplar-source
      root
      "src/commands/search-render.ss"
      ["ranked-syntax-facts" "select-ranked-syntax-facts"]
      #t))
(def (emit-engineering-comment-quality-exemplar-source root)
     (emit-exemplar-source
      root
      "src/policy/agent-comment.ss"
      ["comment-quality-details"
       "comment-quality-fact-summary"
       "weak-required-comment-quality-fact?"]
      #f))
(def (emit-predicate-family-combinator-exemplar-source root)
     (emit-exemplar-source
      root
      "src/parser/quality-shape.ss"
      ["predicate-family-facts-from-source"
       "field-access-pattern-facts-from-source"]
      #t))
(def +poo-rationaldict-exemplar-relpath+
     ".gerbil/pkg/git.cons.io/mighty-gerbils/gerbil-poo/rationaldict.ss")
(def (emit-poo-rationaldict-exemplar-source root)
     (let (source-root (poo-rationaldict-exemplar-root root))
       (if source-root
           (emit-external-exemplar-source
            source-root
            +poo-rationaldict-exemplar-relpath+
            ["RationalDict." "RationalSet"])
           (error "POO rationaldict exemplar source not found"
                  +poo-rationaldict-exemplar-relpath+))))
(def (emit-external-exemplar-source root relpath symbols)
     (let (file (parse-source-file root relpath))
       (emit-definition-exemplar-sources
        root
        (map (lambda (symbol) (guide-definition file relpath symbol))
             symbols))))
(def (poo-rationaldict-exemplar-root root)
     (find (lambda (candidate)
             (file-exists?
              (path-expand +poo-rationaldict-exemplar-relpath+ candidate)))
           (unique (append [root (current-directory)]
                           (runtime-source-ancestor-directories)))))
(def (emit-dependency-protocol-adapter-exemplar-source root)
     (emit-exemplar-source
      root
      "src/parser/dependency-adapter-quality.ss"
      ["dependency-adapter-quality-facts-from-candidates"
       "dependency-adapter-derived-capabilities"
       "dependency-adapter-manual-object-encoding-risk"
       "dependency-adapter-quality-facets"]
      #t))
(def (emit-explicit-precise-import-exemplar-source root)
     (emit-exemplar-source
      root
      "src/policy/agent-import.ss"
      ["explicit-precise-import-finding"
       "imprecise-runtime-import?"
       "explicit-precise-import-details"]
      #t))
(def (emit-package-build-canonical-shape-exemplar-source root)
     (emit-exemplar-source
      root
      "src/policy/agent-build.ss"
      ["package-build-canonical-shape-finding"
       "package-build-spec-call?"
       "package-build-manual-compiler-dispatch-call?"]
      #t))
(def (emit-topic-exemplar-source topic root runtime-source-query)
     (cond ((or (equal? topic "higher-order-control")
                (equal? topic "functional-data-transform"))
            (emit-higher-order-exemplar-source root))
           ((member topic '("typed-combinator-style" "m3-policy-repair-loop"))
            (emit-typed-combinator-style-exemplar-source root))
           ((equal? topic "poo-policy") (emit-poo-policy-exemplar-source root))
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
           (else (emit-higher-order-exemplar-source root))))
;;; Progressive exemplars retain the first topic-specific proof and add an
;;; advanced companion only when it clarifies the same repair boundary.
(def (emit-progressive-exemplar-source
      topic
      root
      advanced?
      runtime-source-query)
     (cond ((or (equal? topic "higher-order-control")
                (equal? topic "functional-data-transform"))
            (newline)
            (emit-poo-policy-exemplar-source root)
            (when advanced?
              (newline)
              (emit-macro-runtime-source-exemplar-source
               runtime-source-query)))
           ((member topic '("typed-combinator-style" "m3-policy-repair-loop"))
            (newline)
            (emit-typed-combinator-style-more-source root)
            (when advanced? (newline) (emit-poo-policy-exemplar-source root)))
           ((equal? topic "poo-policy")
            (newline)
            (emit-higher-order-exemplar-source root)
            (when advanced?
              (newline)
              (emit-macro-runtime-source-exemplar-source
               runtime-source-query)))
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
           (else (newline) (emit-poo-policy-exemplar-source root))))
(def (default-guide-source-root args)
     (cond ((option "--workspace" args) => values)
           ((file-directory? "src") ".")
           ((file-directory?
             "languages/gerbil-scheme-language-project-harness/src")
            "languages/gerbil-scheme-language-project-harness")
           (else (project-root args))))
(def (guide-code-lines args)
     (let* ((topic (guide-topic args))
            (selector (option "--selector" args))
            (root (default-guide-source-root args))
            (runtime-source-query (runtime-source-guide-query args))
            (advanced? (advanced-level? (guide-level args)))
            (more? (or (arg-present? args "--more") advanced?)))
       (cond (selector (display (read-selector root selector)))
             (else
              (emit-topic-exemplar-source topic root runtime-source-query)
              (when more?
                (emit-progressive-exemplar-source
                 topic
                 root
                 advanced?
                 runtime-source-query)))))
     [])
(def (print-guide . maybe-args)
     (let (args (if (pair? maybe-args) (car maybe-args) []))
       (for-each displayln (guide-lines-for args))))
(def (print-guide-code args) (guide-code-lines args))
(def (guide-main args)
     (if (arg-present? args "--code")
         (print-guide-code args)
         (print-guide args))
     0)
