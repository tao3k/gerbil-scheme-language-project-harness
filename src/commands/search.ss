;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Search command adapter.

(import :constants
        :commands/guide
        :commands/search-extension
        :commands/search-owner-items
        :commands/search-render
        :commands/search-structural
        :commands/search-workspace-scope
        :extensions/facade
        :language/facade
        :parser/facade
        :parser/query
        :protocol/json
        :support/args
        :support/io
        :support/list
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter match ormap))

(export search-main
        language-evidence-view?
        language-evidence-index-free-view?
        language-evidence-authority
        language-evidence-next)
;;; Invariant:
;;; - search-main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SearchMain <- (List XX)
(def (search-main args)
  (match args
    ([] (error "search requires a view"))
    ([view . rest]
     (if (equal? view "guide")
       (begin (print-guide) 0)
       (let* ((root (project-root rest))
              (args (drop-project-root rest))
              (json? (flag? "--json" args)))
         (cond
          ((equal? view "compare") (emit-compare-search args json?))
          ((language-evidence-index-free-view? view)
           (emit-language-evidence-search #f view args json?))
          ((poo-pattern-package-only-search? view args)
           (emit-pattern-search
            (collect-project-package-only root)
            args
            json?))
          ((equal? view "workspace-scope")
           (emit-workspace-scope root json?))
          ((equal? view "extension")
           (emit-extension-search
            (collect-project-package-only root)
            args
            json?))
          (else
           (let (index (collect-project root))
             (cond
          ((equal? view "workspace") (emit-workspace index json?))
          ((equal? view "prime") (emit-prime index json?))
          ((equal? view "owner") (emit-owner-search index args json?))
          ((equal? view "symbol") (emit-symbol-search index args json?))
          ((equal? view "import") (emit-import-search index args json?))
          ((equal? view "structural")
           (emit-structural-index index args json?))
          ((equal? view "extension") (emit-extension-search index args json?))
          ((equal? view "pattern") (emit-pattern-search index args json?))
          ((equal? view "compare") (emit-compare-search args json?))
          ((language-evidence-view? view)
           (emit-language-evidence-search index view args json?))
          ((or (equal? view "fzf") (equal? view "pipe"))
           (emit-fzf-search index args json?))
          ((equal? view "ingest") (emit-ingest index json?))
          (else (error "unsupported search view" view)))))))))))
;; Boolean <- SearchView Args
(def (poo-pattern-package-only-search? view args)
  (and (equal? view "pattern")
       (poo-pattern-query? (positional-args args))))
;;; Boundary:
;;; - emit-workspace composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex Json
(def (emit-workspace index json?)
  (if json?
    (write-json-line
     (hash (languageId +language-id+)
           (providerId +provider-id+)
           (root (project-index-root index))
           (projectPackage (project-package-json (project-index-package index)))
           (extensions (project-extension-json index))
           (files (map source-file-json (project-index-files index)))))
    (begin
      (displayln "[gerbil-workspace] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (emit-package-line index)
      (emit-extension-lines index)
      (for-each
        (lambda (file)
          (displayln "|owner path=" (source-file-path file)
                     " package=" (or (source-file-package file) "-")
                     " defs=" (length (source-file-definitions file))))
        (take* (project-index-files index) 20))))
  0)
;;; Boundary:
;;; - emit-prime composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex Json
(def (emit-prime index json?)
  (if json?
    (write-json-line
     (search-prime-packet-json index))
    (begin
      (displayln "[gerbil-search-prime] root=" (project-index-root index)
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index)))
      (displayln "|language id=" +language-id+ " provider=" +provider-id+
                 " parser=core-read-module")
      (emit-package-line index)
      (emit-extension-lines index)
      (for-each
       (lambda (file)
         (displayln "owner:path(" (source-file-path file) ")"
                    " package=" (or (source-file-package file) "-")
                    " sourceClass=" (source-path-class (source-file-path file))
                    " defs=" (length (source-file-definitions file))
                    " imports=" (length (source-file-imports file))))
       (take* (ranked-files index) 12))
      (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")
      (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --workspace . --view seeds")))
  0)
;; String <- ProjectIndex
(def (emit-package-line index)
  (let (package (project-index-package index))
    (when package
      (displayln "|package name=" (project-package-name package)
                 " path=" (project-package-path package)
                 " packageManager=" (project-package-manager package)
                 " dependencies=" (join (project-package-dependencies package) ",")))))
;; (List String) <- ProjectIndex
(def (emit-extension-lines index)
  (for-each displayln (project-extension-search-lines index)))
;;; Boundary:
;;; - resolve-owner-file owns owner path fallback semantics.
;;; - Keep indexed owners first; parse explicit files only when they are Gerbil sources.
;; SourceFile <- ProjectIndex String
(def (resolve-owner-file index owner)
  (or (find-owner index owner)
      (resolve-explicit-owner-file index owner)))
;; MaybeSourceFile <- ProjectIndex String
(def (resolve-explicit-owner-file index owner)
  (let* ((root (project-index-root index))
         (path (path-expand owner root)))
    (and (gerbil-source-path? path)
         (file-exists? path)
         (parse-source-file root path))))
;;; Boundary:
;;; - emit-owner-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List String) Json
(def (emit-owner-search index args json?)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals))))
    (unless owner (error "search owner requires a path"))
    (let (file (resolve-owner-file index owner))
      (unless file (error "owner not found" owner))
      (if (and (pair? (cdr positionals)) (equal? (cadr positionals) "items"))
        (let* ((query (option "--query" args))
               (terms (owner-item-query-terms query))
               (definition-matches
                (matching-definitions (source-file-definitions file) terms))
               (syntax-matches (matching-owner-syntax-facts file terms)))
          (cond
           ((flag? "--code" args)
            (for-each (lambda (defn)
                        (display (read-definition-code (project-index-root index) defn)))
                      definition-matches))
           ((flag? "--names-only" args)
            (for-each (lambda (defn) (displayln (definition-name defn)))
                      definition-matches)
            (for-each (lambda (fact) (displayln (hash-get fact 'name)))
                      syntax-matches))
           (else (emit-owner-items file definition-matches syntax-matches))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))
;;; Boundary:
;;; - emit-owner composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- SourceFile
(def (emit-owner file)
  (displayln "[gerbil-owner] path=" (source-file-path file)
             " package=" (or (source-file-package file) "-")
             " sourceClass=" (source-path-class (source-file-path file))
             " defs=" (length (source-file-definitions file))
             " imports=" (length (source-file-imports file))
             " exports=" (length (source-file-exports file)))
  (when (source-file-prelude file)
    (displayln "|prelude " (source-file-prelude file)))
  (when (source-file-namespace file)
    (displayln "|namespace " (source-file-namespace file)))
  (unless (null? (source-file-imports file))
    (displayln "|imports " (join (source-file-imports file) ",")))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   (take* (source-file-definitions file) 30))
  (displayln "nextCommand=gerbil-scheme-harness query " (source-file-path file)
             " --term '<symbol>' --workspace . --names-only"))
;;; Boundary:
;;; - emit-symbol-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List String) Json
(def (emit-symbol-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search symbol requires a query"))
    (let (matches (matching-definitions (project-definitions index) [query]))
      (if json?
        (write-json-line (hash (query query) (matches (map definition-json matches))))
        (begin
          (displayln "[gerbil-search-symbol] query=" query
                     " matches=" (length matches))
          (for-each
           (lambda (defn)
             (displayln "|match name=" (definition-name defn)
                        " kind=" (definition-kind defn)
                        " selector=" (definition-selector defn)))
           (take* matches 40)))))
    0))
;;; Boundary:
;;; - emit-import-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List XX) Json
(def (emit-import-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search import requires a query"))
    (let (matches
          (filter
           (lambda (file)
             (ormap (cut string-contains <> query)
                    (append (source-file-imports file) (source-file-includes file))))
           (project-index-files index)))
      (if json?
        (write-json-line (hash (query query) (matches (map source-file-json matches))))
        (begin
          (displayln "[gerbil-search-import] query=" query " owners=" (length matches))
          (for-each
           (lambda (file)
             (displayln "|owner path=" (source-file-path file)))
           (take* matches 40)))))
    0))
;;; Boundary:
;;; - emit-fzf-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex (List XX) Json
(def (emit-fzf-search index args json?)
  (let* ((positionals (positional-args args))
         (query (and (pair? positionals) (car positionals))))
    (unless query (error "search fzf requires a query"))
    (let (matches (ranked-query-files index query))
      (if json?
        (write-json-line (hash (query query) (matches (map source-file-json matches))))
        (begin
          (displayln "[gerbil-search-fzf] query=" query " matches=" (length matches))
          (for-each
           (lambda (file)
             (displayln "|owner path=" (source-file-path file)
                        " package=" (or (source-file-package file) "-")
                        " sourceClass=" (source-path-class (source-file-path file))
                        " defs=" (length (source-file-definitions file))))
           (take* matches 24))
          (when (pair? matches)
            (displayln "recommendedNext=gerbil-scheme-harness search owner "
                       (source-file-path (car matches)) " --workspace . --view seeds")))))
    0))
;; Boolean <- View
(def (language-evidence-view? view)
  (and (member view ["extension" "env" "runtime-source" "lang" "std" "pattern" "capability"]) #t))
;; Boolean <- View
(def (language-evidence-index-free-view? view)
  (and (member view ["env" "runtime-source" "lang" "std"]) #t))
;; String <- Namespace
(def (language-evidence-authority namespace)
  (cond
   ((equal? namespace "extension") "ecosystem-extension")
   ((equal? namespace "env") "active-runtime")
   ((equal? namespace "runtime-source") "runtime-version-source")
   ((equal? namespace "lang") "language-rules")
   ((equal? namespace "std") "standard-library")
   ((equal? namespace "pattern") "executable-pattern")
   ((equal? namespace "capability") "project-capability-posture")
   (else "unknown")))
;; String <- Namespace Query
(def (language-evidence-next namespace query)
  (string-append "search " namespace " " query))
;; String
(def +semantic-runtime-source-acquisition-schema-id+
  "agent.semantic-protocols.semantic-runtime-source-acquisition")
;; String
(def +semantic-compare-packet-schema-id+
  "agent.semantic-protocols.semantic-compare-packet")
;;; Boundary:
;;; - runtime-source-acquisition-packet-json coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Json <- Namespace Authority Grade Query (List XX) Next
(def (runtime-source-acquisition-packet-json namespace authority grade query facts next)
  (let* ((fact (and (pair? facts) (car facts)))
         (details (if fact (hash-get fact 'details) (hash)))
         (runtime (if (and fact (hash-key? details 'runtime))
                    (hash-get details 'runtime)
                    #f))
         (source-ref (if (and fact (hash-key? details 'sourceRef))
                       (hash-get details 'sourceRef)
                       #f))
         (acquisition (if (and fact (hash-key? details 'acquisition))
                        (hash-get details 'acquisition)
                        #f))
         (selector-resolver (if (and fact (hash-key? details 'selectorResolver))
                              (hash-get details 'selectorResolver)
                              #f))
         (source-examples (if (and fact (hash-key? details 'sourceExamples))
                            (hash-get details 'sourceExamples)
                            []))
         (source-comments (if (and fact (hash-key? details 'sourceComments))
                            (hash-get details 'sourceComments)
                            [])))
    (hash (schemaId +semantic-runtime-source-acquisition-schema-id+)
          (schemaVersion "1")
          (protocolId "agent.semantic-protocols")
          (protocolVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (namespace namespace)
          (authority authority)
          (evidenceGrade grade)
          (quality (if fact "version-matched-source-plan" "insufficient"))
          (query query)
          (runtime runtime)
          (sourceRef source-ref)
          (acquisition acquisition)
          (selectorResolver selector-resolver)
          (sourceExamples source-examples)
          (sourceComments source-comments)
          (facts facts)
          (failureCases (if fact (hash-get fact 'failureCases) []))
          (qualitySignals (if fact (hash-get fact 'qualitySignals) []))
          (missing (if fact [] ["runtime-source-fact"]))
          (witness (if fact (hash-get fact 'witness) "pending"))
          (next next))))
;;; Boundary:
;;; - emit-pattern-search coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; Unit <- ProjectIndex (List XX) Json
(def (emit-pattern-search index args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (join positionals " ") "-"))
         (pattern (pattern-evidence index positionals))
         (grade (if pattern "fact" "unknown"))
         (missing (if pattern
                    (pattern-missing pattern)
                    ["extension-fact" "pattern-registry" "runnable-witness"]))
         (quality (cond
                   ((not pattern) "insufficient")
                   ((null? missing) "verified")
                   (else "partial")))
         (next (if pattern
                 (hash-get pattern 'next)
                 "search extension <extension>")))
    (if json?
      (write-json-line
       (hash (schemaId +semantic-extension-pattern-mapping-schema-id+)
             (schemaVersion "1")
             (protocolId "agent.semantic-protocols.semantic-language")
             (protocolVersion "1")
             (languageId +language-id+)
             (providerId +provider-id+)
             (namespace "pattern")
             (authority (language-evidence-authority "pattern"))
             (evidenceGrade grade)
             (quality quality)
             (query query)
             (patternMapping (pattern-mapping-json pattern))
             (missing missing)
             (witness (if pattern (hash-get pattern 'witness) "pending"))
             (next next)))
      (begin
        (displayln "[gerbil-search-pattern] query=" query
                   " evidenceGrade=" grade
                   " authority=" (language-evidence-authority "pattern")
                   " quality=" quality)
        (if pattern
          (emit-pattern-lines pattern)
          (displayln "|missing " (join missing ",")))
        (displayln "next=" next)))
    0))
;; String <- ProjectIndex (List String)
(def (pattern-evidence index terms)
  (or (poo-pattern-evidence index terms)
      (hygienic-macro-pattern-evidence terms)))
;;; Boundary:
;;; - emit-pattern-lines composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- Pattern
(def (emit-pattern-lines pattern)
  (let* ((missing (pattern-missing pattern))
         (quality (if (null? missing) "verified" "partial"))
         (via (if (hash-key? pattern 'via) (hash-get pattern 'via) []))
         (via-text (if (null? via) "-" (join via "->"))))
    (displayln "|pattern id=" (hash-get pattern 'id)
               " extension=" (hash-get pattern 'extension)
               " focus=" (hash-get pattern 'focus)
               " origin=" (hash-get pattern 'origin)
               " via=" via-text
               " sourceRef=" (source-ref-summary (hash-get pattern 'sourceRef))
               " witness=" (hash-get pattern 'witness))
    (emit-pattern-agent-guidance pattern quality)
    (when (hash-key? pattern 'importWitness)
      (let* ((witness (hash-get pattern 'importWitness))
             (chain (hash-get witness 'dependencyChain))
             (chain-text (if (null? chain) "-" (join chain "->"))))
        (displayln "|importWitness status=" (hash-get witness 'status)
                   " module=" (hash-get witness 'module)
                   " minimalImport=" (hash-get witness 'minimalImport)
                   " evidence=" (hash-get witness 'evidence)
                   " dependencyChain=" chain-text)))
    (displayln "|agentScenario id=" (hash-get pattern 'agentScenario)
               " intent=" (hash-get pattern 'intent))
    (when (hash-key? pattern 'agentSteering)
      (displayln "|agentSteering " (hash-get pattern 'agentSteering)))
    (for-each
     (lambda (selector)
       (displayln "|selector role=" (hash-get selector 'role)
                  " symbol=" (hash-get selector 'symbol)
                  " selector=" (hash-get selector 'selector)))
     (hash-get pattern 'selectors))
    (for-each
     (lambda (form)
       (let (template (hash-get form 'template))
         (displayln "|form role=" (hash-get form 'role)
                    " symbol=" (hash-get form 'symbol)
                    " head=" (hash-get template 'head)
                    " operands=" (join (hash-get template 'operands) ",")
                    " keywords=" (join (hash-get template 'keywords) ",")
                    " selector=" (hash-get form 'selector))))
     (hash-get pattern 'minimalForms))
    (for-each emit-failure-case-line (hash-get pattern 'failureCases))
    (for-each emit-quality-signal-line (hash-get pattern 'qualitySignals))
    (displayln "|quality " quality
               " missing=" (if (null? missing) "-" (join missing ","))
               " selectorCount=" (length (hash-get pattern 'selectors))
               " formCount=" (length (hash-get pattern 'minimalForms))
               " failureCaseCount=" (length (hash-get pattern 'failureCases)))))
;;; Agent-facing renderer:
;;; - POO selectors are package logical anchors, not workspace line selectors.
;;; - Make the read order explicit so an agent can edit without guessing.
;; Unit <- Pattern Quality
(def (emit-pattern-agent-guidance pattern quality)
  (when (equal? (hash-get pattern 'extension) "poo")
    (let (source-ref (hash-get pattern 'sourceRef))
      (when (hash-key? source-ref 'selectorScheme)
        (displayln "|selectorResolver scheme=" (hash-get source-ref 'selectorScheme)
                   " status=logical-selector"
                   " querySelector=not-direct"
                   " sourceRef=" (source-ref-summary source-ref)))
      (when (and (hash-key? source-ref 'localSource)
                 (hash-key? source-ref 'repositorySource)
                 (hash-key? source-ref 'indexHint))
        (emit-source-lookup-line source-ref)))
    (displayln "|agentReadOrder first=agentScenario"
               " second=agentSteering"
               " third=selectorResolver"
               " fourth=minimalForms"
               " fifth=failureCases"
               " sixth=quality")
    (displayln "|agentAction action=use-minimalForms-before-editing"
               " selectorUse=source-anchor"
               " missingLocalAction=install-package-before-repository-fallback"
               " fallback=repository-source-after-install-check"
               " quality=" quality
               " avoid=generic-scheme-or-racket-class-guess")))
;;; Boundary:
;;; - emit-compare-search composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- (List XX) Json
(def (emit-compare-search args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (join positionals " ") "-"))
         (facts (matching-compare-facts positionals))
         (grade (if (null? facts) "unknown" "fact"))
         (quality (if (null? facts) "insufficient" "verified"))
         (next (if (null? facts)
                 "search compare env active documented"
                 (hash-get (car facts) 'next))))
    (if json?
      (write-json-line
       (hash (schemaId +semantic-compare-packet-schema-id+)
             (schemaVersion "1")
             (protocolId "agent.semantic-protocols.semantic-language")
             (protocolVersion "1")
             (languageId +language-id+)
             (providerId +provider-id+)
             (namespace "compare")
             (authority "active-runtime-vs-documented")
             (evidenceGrade grade)
             (quality quality)
             (query query)
             (comparisons (map compare-fact-json facts))
             (missing (if (null? facts) ["compare-fact"] []))
             (witness (if (null? facts)
                        "pending"
                        (hash-get (car facts) 'witness)))
             (next next)))
      (begin
        (displayln "[gerbil-search-compare] query=" query
                   " evidenceGrade=" grade
                   " authority=active-runtime-vs-documented"
                   " quality=" quality)
        (if (null? facts)
          (begin
            (displayln "|missing compare-fact")
            (displayln "|witness pending"))
          (for-each emit-compare-line facts))
        (displayln "next=" next)))
    0))
;; Unit <- CompareFact
(def (emit-compare-line fact)
  (let ((left (hash-get fact 'left))
        (right (hash-get fact 'right)))
    (displayln "|compare id=" (hash-get fact 'id)
               " result=" (hash-get fact 'result)
               " witness=" (hash-get fact 'witness))
    (displayln "|left kind=" (hash-get left 'kind)
               " systemVersion=" (hash-get left 'systemVersion)
               " gxiResolved=" (hash-get left 'gxiResolved)
               " gscResolved=" (hash-get left 'gscResolved))
    (displayln "|right kind=" (hash-get right 'kind)
               " source=" (hash-get right 'source)
               " status=" (hash-get right 'status))
    (when (hash-key? right 'targetVersions)
      (displayln "|compareTargets versions=" (join-or-dash (hash-get right 'targetVersions))
                 " compileMode=" (hash-get right 'compileMode)
                 " stateNamespace=" (hash-get right 'stateNamespace)))
    (displayln "|agentScenario id=" (hash-get fact 'agentScenario)
               " intent=" (hash-get fact 'intent))
    (for-each emit-failure-case-line (hash-get fact 'failureCases))
    (for-each emit-quality-signal-line (hash-get fact 'qualitySignals))))
;; PatternMissing <- Pattern
(def (pattern-missing pattern)
  (if (and pattern (hash-key? pattern 'missing))
    (hash-get pattern 'missing)
    []))
;; String <- SourceRef
(def (source-ref-summary source-ref)
  (string-append
   (hash-get source-ref 'kind)
   ":"
   (hash-get source-ref 'manager)
   ":"
   (hash-get source-ref 'dependency)
   ":"
   (hash-get source-ref 'pathPolicy)))
;; Unit <- SourceRef
(def (emit-source-lookup-line source-ref)
  (let* ((local-source (hash-get source-ref 'localSource))
         (repository-source (hash-get source-ref 'repositorySource))
         (index-hint (hash-get source-ref 'indexHint)))
    (displayln "|sourceLookup order=local-source-before-git"
               " missingLocalAction=" (hash-get index-hint 'missingLocalAction)
               " fallbackPolicy=" (hash-get index-hint 'fallbackPolicy)
               " localRootHint=" (hash-get local-source 'rootHint)
               " localPackage=" (hash-get local-source 'package)
               " localStatus=" (hash-get local-source 'status)
               " localMissingAction=" (hash-get local-source 'missingAction)
               " installHint=\"" (hash-get local-source 'installHint) "\""
               " repository=" (hash-get repository-source 'repository)
               " repositoryUrl=" (hash-get repository-source 'url)
               " indexOwner=" (hash-get index-hint 'owner)
               " indexBackend=" (hash-get index-hint 'backend)
               " indexPackageManager=" (hash-get index-hint 'packageManager))))
;;; Boundary:
;;; - emit-language-evidence-search coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; String <- ProjectIndex Namespace (List String) Json
(def (emit-language-evidence-search index namespace args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (join positionals " ") "-"))
         (authority (language-evidence-authority namespace))
         (facts (matching-language-evidence-facts index namespace positionals))
         (grade (if (null? facts) "unknown" "fact"))
         (next (if (null? facts)
                 (language-evidence-next namespace query)
                 (hash-get (car facts) 'next))))
    (if json?
      (if (equal? namespace "runtime-source")
        (write-json-line
         (runtime-source-acquisition-packet-json
          namespace authority grade query facts next))
        (write-json-line
         (hash (languageId +language-id+)
               (providerId +provider-id+)
               (namespace namespace)
               (authority authority)
               (evidenceGrade grade)
               (query query)
               (facts facts)
               (next next))))
      (begin
        (displayln "[gerbil-search-" namespace "] query=" query
                   " evidenceGrade=" grade " authority=" authority)
        (if (null? facts)
          (begin
            (displayln "|missing fact-registry-or-query-match")
            (displayln "|witness pending"))
          (for-each emit-language-evidence-line facts))
        (displayln "next=" next)))
    0))
;;; Boundary:
;;; - matching-language-evidence-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- ProjectIndex Namespace (List String)
(def (matching-language-evidence-facts index namespace terms)
  (let (facts
        (cond
         ((equal? namespace "env") (active-runtime-facts))
         ((equal? namespace "runtime-source") (runtime-source-facts))
         ((equal? namespace "lang") (language-rule-facts))
         ((equal? namespace "std") (standard-library-facts))
         ((equal? namespace "capability") (capability-posture-facts index))
         (else [])))
    (filter (cut evidence-fact-matches-terms? <> terms) facts)))
;;; Boundary:
;;; - evidence-fact-matches-terms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- LanguageEvidenceFact (List SearchTerm)
(def (evidence-fact-matches-terms? fact terms)
  (or (null? terms)
      (ormap (lambda (term)
               (ormap (cut string-contains <> term)
                      (hash-get fact 'terms)))
             terms)))
;;; Boundary:
;;; - emit-language-evidence-line composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- LanguageEvidenceFact
(def (emit-language-evidence-line fact)
  (displayln "|fact id=" (hash-get fact 'id)
             " evidenceGrade=" (hash-get fact 'evidenceGrade)
             " witness=" (hash-get fact 'witness)
             " summary=" (hash-get fact 'summary))
  (displayln "|agentScenario id=" (hash-get fact 'agentScenario)
             " intent=" (hash-get fact 'intent))
  (when (hash-key? fact 'agentSteering)
    (displayln "|agentSteering " (hash-get fact 'agentSteering)))
  (let (details (hash-get fact 'details))
    (when (hash-key? details 'gerbilHome)
      (displayln "|runtime gerbilHome=" (hash-get details 'gerbilHome)
                 " gxi=" (hash-get details 'gxi)
                 " gsc=" (hash-get details 'gsc)
                 " gxiExists=" (hash-get details 'gxiExists)
                 " gscExists=" (hash-get details 'gscExists)
                 " loadPathCount=" (length (hash-get details 'loadPath))))
    (when (hash-key? details 'sourceRef)
      (let ((source-ref (hash-get details 'sourceRef))
            (acquisition (hash-get details 'acquisition)))
        (displayln "|sourceRef kind=" (hash-get source-ref 'kind)
                   " manager=" (hash-get source-ref 'manager)
                   " repository=" (hash-get source-ref 'repository)
                   " checkout=" (hash-get source-ref 'checkout)
                   " checkoutPolicy=" (hash-get source-ref 'checkoutPolicy)
                   " statePathPolicy=" (hash-get source-ref 'statePathPolicy))
        (displayln "|acquisition owner=" (hash-get acquisition 'owner)
                   " operation=" (hash-get acquisition 'operation)
                   " stateNamespace=" (hash-get acquisition 'stateNamespace)
                   " versionKey=" (hash-get acquisition 'versionKey)
                   " indexOwner=" (hash-get acquisition 'indexOwner))))
    (when (hash-key? details 'selectorResolver)
      (emit-selector-resolver-line (hash-get details 'selectorResolver)))
    (for-each emit-source-example-line (detail-list details 'sourceExamples))
    (for-each emit-source-comment-line (detail-list details 'sourceComments))
    (when (hash-key? details 'capability)
      (displayln "|capability name=" (hash-get details 'capability)
                 " status=" (hash-get details 'status)
                 " policyRules=" (join-or-dash (hash-get details 'policyRules)))))
  (for-each
   (lambda (selector)
     (displayln "|selector role=" (hash-get selector 'role)
                " symbol=" (hash-get selector 'symbol)
                " selector=" (hash-get selector 'selector)))
   (hash-get fact 'selectors))
  (for-each emit-failure-case-line (hash-get fact 'failureCases))
  (for-each emit-quality-signal-line (hash-get fact 'qualitySignals)))
;; String <- Failure
(def (emit-failure-case-line failure)
  (displayln "|failureCase id=" (hash-get failure 'id)
             " risk=" (failure-risk failure)
             " correction=" (failure-correction failure)))
;; String <- Failure
(def (failure-risk failure)
  (cond
   ((hash-key? failure 'risk) (hash-get failure 'risk))
   ((hash-key? failure 'riskKind) (hash-get failure 'riskKind))
   (else "unknown")))
;; String <- Failure
(def (failure-correction failure)
  (cond
   ((hash-key? failure 'correction) (hash-get failure 'correction))
   ((hash-key? failure 'correctiveAction) (hash-get failure 'correctiveAction))
   (else "unknown")))
;; String <- Signal
(def (emit-quality-signal-line signal)
  (displayln "|qualitySignal id=" signal))
;;; Boundary:
;;; - emit-ingest composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- ProjectIndex Json
(def (emit-ingest index json?)
  (let* ((stdin-text (read-all-as-string (current-input-port)))
         (matches (filter (lambda (file)
                            (string-contains stdin-text (source-file-path file)))
                          (project-index-files index))))
    (if json?
      (write-json-line (hash (owners (map source-file-json matches))))
      (begin
        (displayln "[gerbil-search-ingest] owners=" (length matches))
        (for-each (lambda (file)
                    (displayln "|owner path=" (source-file-path file)))
                  matches)))
    0))
