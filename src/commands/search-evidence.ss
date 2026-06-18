;;; -*- Gerbil -*-
;;; Search evidence packet rendering for pattern, compare, runtime-source, and ingest views.

(import :constants
        :commands/search-render
        :extensions/facade
        :language/facade
        :parser/facade
        :protocol/json
        :support/args
        :support/io
        :support/list
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter hash ormap))

(export language-evidence-view?
        language-evidence-index-free-view?
        language-evidence-authority
        language-evidence-next
        emit-pattern-search
        emit-compare-search
        emit-language-evidence-search
        emit-ingest)

;; : (-> View Boolean )
(def (language-evidence-view? view)
  (and (member view ["extension" "env" "runtime-source" "lang" "std" "pattern" "capability"]) #t))
;; : (-> View Boolean )
(def (language-evidence-index-free-view? view)
  (and (member view ["env" "runtime-source" "lang" "std"]) #t))
;; : (-> Namespace String )
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
;; : (-> Namespace Query String )
(def (language-evidence-next namespace query)
  (string-append "search " namespace " " query))
;; String
(def +semantic-runtime-source-acquisition-schema-id+
  "agent.semantic-protocols.semantic-runtime-source-acquisition")
;; String
(def +semantic-compare-packet-schema-id+
  "agent.semantic-protocols.semantic-compare-packet")
;; runtime-source-acquisition-packet-json
;;   : (-> String String String String (List LanguageEvidenceFact) String JsonPacket)
;;   | doc m%
;;       `runtime-source-acquisition-packet-json namespace authority grade query
;;       facts next` builds the runtime source acquisition packet for language
;;       evidence search.
;;
;;       # Examples
;;
;;       ```scheme
;;       (runtime-source-acquisition-packet-json "std" "language" "fact" "macro" facts next)
;;       ;; => acquisition JSON packet
;;       ```
;;     %
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
;; emit-pattern-search
;;   : (-> ProjectIndex (List String) Boolean Integer)
;;   | doc m%
;;       `emit-pattern-search index args json?` emits POO and macro pattern
;;       evidence as JSON or compact agent-facing lines.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-pattern-search index '("gerbil-poo") #f)
;;       ;; => 0
;;       ```
;;     %
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
;; : (-> ProjectIndex (List String) String )
(def (pattern-evidence index terms)
  (or (poo-pattern-evidence index terms)
      (hygienic-macro-pattern-evidence terms)))
;; emit-pattern-lines
;;   : (-> Pattern Unit)
;;   | doc m%
;;       `emit-pattern-lines pattern` prints the pattern evidence row plus
;;       agent guidance, import witnesses, and source selectors.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-pattern-lines pattern)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-pattern-lines pattern)
  (let* ((missing (pattern-missing pattern))
         (quality (if (null? missing) "verified" "partial"))
         (via (if (hash-key? pattern 'via) (hash-get pattern 'via) []))
         (via-text (if (null? via) "-" (join via "->"))))
    (emit-field-line
     "|pattern"
     [(line-field "id" (hash-get pattern 'id))
      (line-field "extension" (hash-get pattern 'extension))
      (line-field "focus" (hash-get pattern 'focus))
      (line-field "origin" (hash-get pattern 'origin))
      (line-field "via" via-text)
      (line-field "sourceRef" (source-ref-summary (hash-get pattern 'sourceRef)))
      (line-field "witness" (hash-get pattern 'witness))])
    (emit-pattern-agent-guidance pattern quality)
    (when (hash-key? pattern 'importWitness)
      (let* ((witness (hash-get pattern 'importWitness))
             (chain (hash-get witness 'dependencyChain))
             (chain-text (if (null? chain) "-" (join chain "->"))))
        (emit-field-line
         "|importWitness"
         [(line-field "status" (hash-get witness 'status))
          (line-field "module" (hash-get witness 'module))
          (line-field "minimalImport" (hash-get witness 'minimalImport))
          (line-field "evidence" (hash-get witness 'evidence))
          (line-field "dependencyChain" chain-text)])))
    (emit-field-line
     "|agentScenario"
     [(line-field "id" (hash-get pattern 'agentScenario))
      (line-field "intent" (hash-get pattern 'intent))])
    (when (hash-key? pattern 'agentSteering)
      (emit-text-line (string-append "|agentSteering "
                                     (hash-get pattern 'agentSteering))))
    (for-each
     (lambda (selector)
       (emit-field-line
        "|selector"
        [(line-field "role" (hash-get selector 'role))
         (line-field "symbol" (hash-get selector 'symbol))
         (line-field "selector" (hash-get selector 'selector))]))
     (hash-get pattern 'selectors))
    (for-each
     (lambda (form)
       (let (template (hash-get form 'template))
         (emit-field-line
          "|form"
          [(line-field "role" (hash-get form 'role))
           (line-field "symbol" (hash-get form 'symbol))
           (line-field "head" (hash-get template 'head))
           (line-field "operands" (join (hash-get template 'operands) ","))
           (line-field "keywords" (join (hash-get template 'keywords) ","))
           (line-field "selector" (hash-get form 'selector))])))
     (hash-get pattern 'minimalForms))
    (for-each emit-failure-case-line (hash-get pattern 'failureCases))
    (for-each emit-quality-signal-line (hash-get pattern 'qualitySignals))
    (emit-field-line
     (string-append "|quality " quality)
     [(line-field "missing" (if (null? missing) "-" (join missing ",")))
      (line-field "selectorCount" (length (hash-get pattern 'selectors)))
      (line-field "formCount" (length (hash-get pattern 'minimalForms)))
      (line-field "failureCaseCount" (length (hash-get pattern 'failureCases)))])))
;;; Agent-facing renderer:
;;; - POO selectors are package logical anchors, not workspace line selectors.
;;; - Make the read order explicit so an agent can edit without guessing.
;; : (-> Pattern Quality Unit )
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
;; emit-compare-search
;;   : (-> (List String) Boolean Integer)
;;   | doc m%
;;       `emit-compare-search args json?` prints or serializes compare evidence
;;       for the query terms and returns a process-style status code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-compare-search '("env" "active") #f)
;;       ;; => 0
;;       ```
;;     %
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
;; : (-> CompareFact Unit )
(def (emit-compare-line fact)
  (let ((left (hash-get fact 'left))
        (right (hash-get fact 'right)))
    (emit-field-line
     "|compare"
     [(line-field "id" (hash-get fact 'id))
      (line-field "result" (hash-get fact 'result))
      (line-field "witness" (hash-get fact 'witness))])
    (emit-field-line
     "|left"
     [(line-field "kind" (hash-get left 'kind))
      (line-field "systemVersion" (hash-get left 'systemVersion))
      (line-field "gxiResolved" (hash-get left 'gxiResolved))
      (line-field "gscResolved" (hash-get left 'gscResolved))])
    (emit-field-line
     "|right"
     [(line-field "kind" (hash-get right 'kind))
      (line-field "source" (hash-get right 'source))
      (line-field "status" (hash-get right 'status))])
    (when (hash-key? right 'targetVersions)
      (emit-field-line
       "|compareTargets"
       [(line-field "versions" (join-or-dash (hash-get right 'targetVersions)))
        (line-field "compileMode" (hash-get right 'compileMode))
        (line-field "stateNamespace" (hash-get right 'stateNamespace))]))
    (emit-field-line
     "|agentScenario"
     [(line-field "id" (hash-get fact 'agentScenario))
      (line-field "intent" (hash-get fact 'intent))])
    (for-each emit-failure-case-line (hash-get fact 'failureCases))
    (for-each emit-quality-signal-line (hash-get fact 'qualitySignals))))
;; : (-> Pattern PatternMissing )
(def (pattern-missing pattern)
  (if (and pattern (hash-key? pattern 'missing))
    (hash-get pattern 'missing)
    []))
;; : (-> SourceRef String )
(def (source-ref-summary source-ref)
  (string-append
   (hash-get source-ref 'kind)
   ":"
   (hash-get source-ref 'manager)
   ":"
   (hash-get source-ref 'dependency)
   ":"
   (hash-get source-ref 'pathPolicy)))
;; : (-> SourceRef Unit )
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
;; : (-> ProjectIndex Namespace (List String) Json String )
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
;; matching-language-evidence-facts
;;   : (-> ProjectIndex String (List String) (List LanguageEvidenceFact))
;;   | doc m%
;;       `matching-language-evidence-facts index namespace terms` selects the
;;       namespace fact registry and filters it by the requested terms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (matching-language-evidence-facts index "std" '("macro"))
;;       ;; => matching facts
;;       ```
;;     %
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
;; evidence-fact-matches-terms?
;;   : (-> LanguageEvidenceFact (List String) Boolean)
;;   | doc m%
;;       `evidence-fact-matches-terms? fact terms` returns `#t` when any search
;;       term is contained in the fact term list.
;;
;;       # Examples
;;
;;       ```scheme
;;       (evidence-fact-matches-terms? fact '("macro"))
;;       ;; => #t
;;       ```
;;     %
(def (evidence-fact-matches-terms? fact terms)
  (or (null? terms)
      (ormap (lambda (term)
               (ormap (cut string-contains <> term)
                      (hash-get fact 'terms)))
             terms)))
;; emit-language-evidence-line
;;   : (-> LanguageEvidenceFact Unit)
;;   | doc m%
;;       `emit-language-evidence-line fact` prints one fact and its associated
;;       scenario, runtime, selector, failure, and quality evidence lines.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-language-evidence-line fact)
;;       ;; => (void)
;;       ```
;;     %
(def (emit-language-evidence-line fact)
  (emit-field-line
   "|fact"
   [(line-field "id" (hash-get fact 'id))
    (line-field "evidenceGrade" (hash-get fact 'evidenceGrade))
    (line-field "witness" (hash-get fact 'witness))
    (line-field "summary" (hash-get fact 'summary))])
  (emit-field-line
   "|agentScenario"
   [(line-field "id" (hash-get fact 'agentScenario))
    (line-field "intent" (hash-get fact 'intent))])
  (when (hash-key? fact 'agentSteering)
    (emit-text-line (string-append "|agentSteering "
                                   (hash-get fact 'agentSteering))))
  (let (details (hash-get fact 'details))
    (when (hash-key? details 'gerbilHome)
      (emit-field-line
       "|runtime"
       [(line-field "gerbilHome" (hash-get details 'gerbilHome))
        (line-field "gxi" (hash-get details 'gxi))
        (line-field "gsc" (hash-get details 'gsc))
        (line-field "gxiExists" (hash-get details 'gxiExists))
        (line-field "gscExists" (hash-get details 'gscExists))
        (line-field "loadPathCount" (length (hash-get details 'loadPath)))]))
    (when (hash-key? details 'sourceRef)
      (let ((source-ref (hash-get details 'sourceRef))
            (acquisition (hash-get details 'acquisition)))
        (emit-field-line
         "|sourceRef"
         [(line-field "kind" (hash-get source-ref 'kind))
          (line-field "manager" (hash-get source-ref 'manager))
          (line-field "repository" (hash-get source-ref 'repository))
          (line-field "checkout" (hash-get source-ref 'checkout))
          (line-field "checkoutPolicy" (hash-get source-ref 'checkoutPolicy))
          (line-field "statePathPolicy" (hash-get source-ref 'statePathPolicy))])
        (emit-field-line
         "|acquisition"
         [(line-field "owner" (hash-get acquisition 'owner))
          (line-field "operation" (hash-get acquisition 'operation))
          (line-field "stateNamespace" (hash-get acquisition 'stateNamespace))
          (line-field "versionKey" (hash-get acquisition 'versionKey))
          (line-field "indexOwner" (hash-get acquisition 'indexOwner))])))
    (when (hash-key? details 'selectorResolver)
      (emit-selector-resolver-line (hash-get details 'selectorResolver)))
    (for-each emit-source-example-line (detail-list details 'sourceExamples))
    (for-each emit-source-comment-line (detail-list details 'sourceComments))
    (when (hash-key? details 'capability)
      (emit-field-line
       "|capability"
       [(line-field "name" (hash-get details 'capability))
        (line-field "status" (hash-get details 'status))
        (line-field "policyRules" (join-or-dash (hash-get details 'policyRules)))])))
  (for-each
   (lambda (selector)
     (emit-field-line
      "|selector"
      [(line-field "role" (hash-get selector 'role))
       (line-field "symbol" (hash-get selector 'symbol))
       (line-field "selector" (hash-get selector 'selector))]))
   (hash-get fact 'selectors))
  (for-each emit-failure-case-line (hash-get fact 'failureCases))
  (for-each emit-quality-signal-line (hash-get fact 'qualitySignals)))
;; : (-> Failure String )
(def (emit-failure-case-line failure)
  (displayln "|failureCase id=" (hash-get failure 'id)
             " risk=" (failure-risk failure)
             " correction=" (failure-correction failure)))
;; : (-> Failure String )
(def (failure-risk failure)
  (cond
   ((hash-key? failure 'risk) (hash-get failure 'risk))
   ((hash-key? failure 'riskKind) (hash-get failure 'riskKind))
   (else "unknown")))
;; : (-> Failure String )
(def (failure-correction failure)
  (cond
   ((hash-key? failure 'correction) (hash-get failure 'correction))
   ((hash-key? failure 'correctiveAction) (hash-get failure 'correctiveAction))
   (else "unknown")))
;; : (-> Signal String )
(def (emit-quality-signal-line signal)
  (displayln "|qualitySignal id=" signal))
;; emit-ingest
;;   : (-> ProjectIndex Boolean Integer)
;;   | doc m%
;;       `emit-ingest index json?` reads stdin text, matches indexed owner paths,
;;       and emits either JSON owners or compact owner lines.
;;
;;       # Examples
;;
;;       ```scheme
;;       (emit-ingest index #f)
;;       ;; => 0
;;       ```
;;     %
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
