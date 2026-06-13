;;; -*- Gerbil -*-
;;; Search command adapter.

(import :constants
        :commands/guide
        :extensions/facade
        :language/facade
        :parser/facade
        :parser/query
        :protocol/json
        :support/args
        :support/io
        :support/list
        :std/misc/ports
        :std/srfi/13)

(export search-main
        language-evidence-view?
        language-evidence-authority
        language-evidence-next)

(def (search-main args)
  (match args
    ([] (error "search requires a view"))
    ([view . rest]
     (if (equal? view "guide")
       (begin (print-guide) 0)
       (let* ((root (project-root rest))
              (args (drop-project-root rest))
              (index (collect-project root))
              (json? (flag? "--json" args)))
         (cond
          ((equal? view "workspace") (emit-workspace index json?))
          ((equal? view "prime") (emit-prime index json?))
          ((equal? view "owner") (emit-owner-search index args json?))
          ((equal? view "symbol") (emit-symbol-search index args json?))
          ((equal? view "import") (emit-import-search index args json?))
          ((equal? view "structural") (emit-structural-index index json?))
          ((equal? view "extension") (emit-extension-search index args json?))
          ((equal? view "pattern") (emit-pattern-search index args json?))
          ((equal? view "compare") (emit-compare-search args json?))
          ((language-evidence-view? view)
           (emit-language-evidence-search index view args json?))
          ((or (equal? view "fzf") (equal? view "pipe"))
           (emit-fzf-search index args json?))
          ((equal? view "ingest") (emit-ingest index json?))
          (else (error "unsupported search view" view))))))))

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
                    " defs=" (length (source-file-definitions file))
                    " imports=" (length (source-file-imports file))))
       (take* (ranked-files index) 12))
      (displayln "recommendedNext=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")
      (displayln "nextCommand=gerbil-scheme-harness search fzf '<term>' owner tests --view seeds .")))
  0)

(def (emit-package-line index)
  (let (package (project-index-package index))
    (when package
      (displayln "|package name=" (project-package-name package)
                 " path=" (project-package-path package)
                 " packageManager=" (project-package-manager package)
                 " dependencies=" (join (project-package-dependencies package) ",")))))

(def (emit-extension-lines index)
  (for-each displayln (project-extension-search-lines index)))

(def (emit-owner-search index args json?)
  (let* ((positionals (positional-args args))
         (owner (and (pair? positionals) (car positionals))))
    (unless owner (error "search owner requires a path"))
    (let (file (find-owner index owner))
      (unless file (error "owner not found" owner))
      (if (and (pair? (cdr positionals)) (equal? (cadr positionals) "items"))
        (let* ((query (option "--query" args))
               (matches (matching-definitions (source-file-definitions file)
                                              (if query [query] '()))))
          (cond
           ((flag? "--code" args)
            (for-each (lambda (defn)
                        (display (read-definition-code (project-index-root index) defn)))
                      matches))
           ((flag? "--names-only" args)
            (for-each (lambda (defn) (displayln (definition-name defn))) matches))
           (else (emit-owner-items file matches))))
        (if json?
          (write-json-line (source-file-json file))
          (emit-owner file))))
    0))

(def (emit-owner file)
  (displayln "[gerbil-owner] path=" (source-file-path file)
             " package=" (or (source-file-package file) "-")
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

(def (emit-owner-items file matches)
  (displayln "[gerbil-owner-items] path=" (source-file-path file)
             " matches=" (length matches))
  (for-each
   (lambda (defn)
     (displayln "|item kind=" (definition-kind defn)
                " name=" (definition-name defn)
                " selector=" (definition-selector defn)))
   matches))

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

(def (emit-structural-index index json?)
  (let* ((packet (structural-index-packet-json index))
         (file-hashes (hash-get packet 'fileHashes))
         (owners (hash-get packet 'owners))
         (symbols (hash-get packet 'symbols))
         (dependency-usages (hash-get packet 'dependencyUsages)))
    (if json?
      (write-json-line packet)
      (begin
        (displayln "[gerbil-search-structural] root=" (project-index-root index)
                   " generationId=" (hash-get packet 'generationId)
                   " files=" (length file-hashes)
                   " owners=" (length owners)
                   " symbols=" (length symbols)
                   " dependencyUsages=" (length dependency-usages))
        (displayln "|artifact id=" (hash-get packet 'sourceArtifactId)
                   " schemaId=" (hash-get packet 'schemaId)
                   " rawSourceStored=false")
        (for-each
         (lambda (owner)
           (displayln "|owner path=" (hash-get owner 'ownerPath)
                      " kind=" (hash-get owner 'ownerKind)
                      " authority=" (hash-get owner 'sourceAuthority)))
         (take* owners 20))
        (displayln "nextCommand=gerbil-scheme-harness search structural --json ."))))
  0)

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
                        " defs=" (length (source-file-definitions file))))
           (take* matches 24))
          (when (pair? matches)
            (displayln "recommendedNext=gerbil-scheme-harness search owner "
                       (source-file-path (car matches)) " --view seeds .")))))
    0))

(def (language-evidence-view? view)
  (and (member view ["extension" "env" "runtime-source" "lang" "std" "pattern"]) #t))

(def (language-evidence-authority namespace)
  (cond
   ((equal? namespace "extension") "ecosystem-extension")
   ((equal? namespace "env") "active-runtime")
   ((equal? namespace "runtime-source") "runtime-version-source")
   ((equal? namespace "lang") "language-rules")
   ((equal? namespace "std") "standard-library")
   ((equal? namespace "pattern") "executable-pattern")
   (else "unknown")))

(def (language-evidence-next namespace query)
  (string-append "search " namespace " " query))

(def +semantic-runtime-source-acquisition-schema-id+
  "agent.semantic-protocols.semantic-runtime-source-acquisition")

(def +semantic-compare-packet-schema-id+
  "agent.semantic-protocols.semantic-compare-packet")

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

(def (emit-extension-search index args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (join positionals " ") "-"))
         (matches (matching-extension-facts index positionals))
         (grade (if (null? matches) "unknown" "fact")))
    (if json?
      (write-json-line
       (hash (languageId +language-id+)
             (providerId +provider-id+)
             (namespace "extension")
             (authority (language-evidence-authority "extension"))
             (evidenceGrade grade)
             (query query)
             (matches (map extension-fact-json matches))
             (next (extension-evidence-next positionals matches))))
      (begin
        (displayln "[gerbil-search-extension] query=" query
                   " matches=" (length matches)
                   " evidenceGrade=" grade
                   " authority=" (language-evidence-authority "extension"))
        (for-each
         (lambda (fact)
           (displayln (extension-fact-search-line fact)))
         matches)
        (displayln "next=" (extension-evidence-next positionals matches))))
    0))

(def (matching-extension-facts index terms)
  (let (facts (project-extension-facts index))
    (if (null? terms)
      facts
      (filter (lambda (fact)
                (ormap (cut extension-fact-matches-term? fact <>)
                       terms))
              facts))))

(def (extension-fact-matches-term? fact term)
  (or (string-contains (extension-fact-name fact) term)
      (ormap (cut string-contains <> term)
             (extension-fact-dependencies fact))
      (ormap (cut string-contains <> term)
             (extension-fact-capabilities fact))))

(def (extension-evidence-next terms matches)
  (let ((extension-name (if (pair? matches)
                          (extension-fact-name (car matches))
                          (if (pair? terms) (car terms) "<extension>")))
        (focus (if (and (pair? terms) (pair? (cdr terms)))
                 (join (cdr terms) " ")
                 "<api|syntax|pattern>")))
    (string-append "search pattern " extension-name " " focus)))

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

(def (pattern-evidence index terms)
  (or (poo-pattern-evidence index terms)
      (hygienic-macro-pattern-evidence terms)))

(def (emit-pattern-lines pattern)
  (let* ((missing (pattern-missing pattern))
         (quality (if (null? missing) "verified" "partial")))
    (displayln "|pattern id=" (hash-get pattern 'id)
               " extension=" (hash-get pattern 'extension)
               " focus=" (hash-get pattern 'focus)
               " sourceRef=" (source-ref-summary (hash-get pattern 'sourceRef))
               " witness=" (hash-get pattern 'witness))
    (displayln "|agentScenario id=" (hash-get pattern 'agentScenario)
               " intent=" (hash-get pattern 'intent))
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

(def (pattern-missing pattern)
  (if (and pattern (hash-key? pattern 'missing))
    (hash-get pattern 'missing)
    []))

(def (source-ref-summary source-ref)
  (string-append
   (hash-get source-ref 'kind)
   ":"
   (hash-get source-ref 'manager)
   ":"
   (hash-get source-ref 'dependency)
   ":"
   (hash-get source-ref 'pathPolicy)))

(def (emit-language-evidence-search index namespace args json?)
  (let* ((positionals (positional-args args))
         (query (if (pair? positionals) (join positionals " ") "-"))
         (authority (language-evidence-authority namespace))
         (facts (matching-language-evidence-facts namespace positionals))
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

(def (matching-language-evidence-facts namespace terms)
  (let (facts
        (cond
         ((equal? namespace "env") (active-runtime-facts))
         ((equal? namespace "runtime-source") (runtime-source-facts))
         ((equal? namespace "lang") (language-rule-facts))
         ((equal? namespace "std") (standard-library-facts))
         (else [])))
    (filter (cut evidence-fact-matches-terms? <> terms) facts)))

(def (evidence-fact-matches-terms? fact terms)
  (or (null? terms)
      (ormap (lambda (term)
               (ormap (cut string-contains <> term)
                      (hash-get fact 'terms)))
             terms)))

(def (emit-language-evidence-line fact)
  (displayln "|fact id=" (hash-get fact 'id)
             " evidenceGrade=" (hash-get fact 'evidenceGrade)
             " witness=" (hash-get fact 'witness)
             " summary=" (hash-get fact 'summary))
  (displayln "|agentScenario id=" (hash-get fact 'agentScenario)
             " intent=" (hash-get fact 'intent))
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
    (for-each emit-source-comment-line (detail-list details 'sourceComments)))
  (for-each
   (lambda (selector)
     (displayln "|selector role=" (hash-get selector 'role)
                " symbol=" (hash-get selector 'symbol)
                " selector=" (hash-get selector 'selector)))
   (hash-get fact 'selectors))
  (for-each emit-failure-case-line (hash-get fact 'failureCases))
  (for-each emit-quality-signal-line (hash-get fact 'qualitySignals)))

(def (emit-selector-resolver-line resolver)
  (displayln "|selectorResolver scheme=" (hash-get resolver 'scheme)
             " owner=" (hash-get resolver 'owner)
             " stateNamespace=" (hash-get resolver 'stateNamespace)
             " versionKey=" (hash-get resolver 'versionKey)
             " selectorFormat=" (hash-get resolver 'selectorFormat)
             " output=" (hash-get resolver 'output)
             " indexOwner=" (hash-get resolver 'indexOwner)))

(def (emit-source-example-line example)
  (let (form (hash-get example 'form))
    (displayln "|sourceExample id=" (hash-get example 'id)
               " role=" (hash-get example 'role)
               " symbol=" (hash-get example 'symbol)
               " selector=" (hash-get example 'selector)
               " head=" (hash-get form 'head)
               " operands=" (join-or-dash (hash-get form 'operands))
               " keywords=" (join-or-dash (hash-get form 'keywords))
               " commentMode=" (hash-get example 'commentMode))))

(def (emit-source-comment-line comment)
  (displayln "|sourceComment id=" (hash-get comment 'id)
             " selector=" (hash-get comment 'selector)
             " extractor=" (hash-get comment 'extractor)
             " summary=" (hash-get comment 'summary)
             " fallback=" (hash-get comment 'fallback)))

(def (detail-list details key)
  (if (hash-key? details key)
    (hash-get details key)
    []))

(def (join-or-dash values)
  (if (null? values)
    "-"
    (join values ",")))

(def (emit-failure-case-line failure)
  (displayln "|failureCase id=" (hash-get failure 'id)
             " risk=" (failure-risk failure)
             " correction=" (failure-correction failure)))

(def (failure-risk failure)
  (cond
   ((hash-key? failure 'risk) (hash-get failure 'risk))
   ((hash-key? failure 'riskKind) (hash-get failure 'riskKind))
   (else "unknown")))

(def (failure-correction failure)
  (cond
   ((hash-key? failure 'correction) (hash-get failure 'correction))
   ((hash-key? failure 'correctiveAction) (hash-get failure 'correctiveAction))
   (else "unknown")))

(def (emit-quality-signal-line signal)
  (displayln "|qualitySignal id=" signal))

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
