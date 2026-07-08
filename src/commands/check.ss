;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Check command adapter.

(import :gerbil/gambit
        :checker/facade
        :commands/check-cache
        :constants
        :parser/facade
        (rename-in :parser/core
                   (collect-project/profile collect-project-profile))
        :policy/core
        :policy/repair
        :protocol/json
        (only-in :std/misc/path path-normalize)
        (only-in :std/misc/process run-process)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-tokenize)
        (only-in :std/sugar filter foldl ormap)
        :support/args
        :support/time
        (only-in :types/core
                 run-type-checks/whitelist
                 type-status)
        :types/findings)

(export check-main)

;; : (-> String Integer Json)
(def (check-profile-row name start-ms)
  (hash (name name)
        (durationMs (duration-ms start-ms (monotonic-ms)))))

;; : (-> String (-> Value) (Values Value Json))
(def (timed-check-value name thunk)
  (let* ((start-ms (monotonic-ms))
         (value (thunk)))
    (values value (check-profile-row name start-ms))))

;; : (-> String String (List String) Boolean (Values ProjectIndex Json))
(def (collect-project/check root scope changed-paths profile?)
  (cond
   ((and profile? (equal? scope "full"))
      (let* ((collect-report (collect-project-profile root))
             (index (hash-get collect-report 'index))
             (profile (hash-get collect-report 'profile)))
        (values index profile)))
   ((equal? scope "changed")
    (timed-check-value "collect-source-scope"
                       (lambda ()
                         (collect-source-scope root changed-paths))))
   (else
    (timed-check-value "collect-project"
                       (lambda ()
                         (collect-project root))))))

;;; Cache boundary: full check is deterministic for a fixed source/config input
;;; set and output mode. Profile runs bypass this cache so timing receipts always
;;; measure the real cold path.
;; : (-> String Boolean String)
(def (check-output-mode json? profile-json?)
  (cond
   (profile-json? "profile-json")
   (json? "json")
   (else "text")))

;; : (-> Integer Json Json Json Json Json)
(def (check-profile-json total-start-ms collect-profile type-phase policy-phase findings-phase)
  (hash (totalMs (duration-ms total-start-ms (monotonic-ms)))
        (collectProject collect-profile)
        (phases [type-phase policy-phase findings-phase])))

;; : (-> Integer Boolean Boolean String (List String) ProjectIndex Json Json Json Json (List TypeFinding) String Void)
(def (emit-check-report total-start-ms json? profile-json? scope changed-paths
                        index collect-profile type-phase policy-phase findings-phase
                        findings status)
  (if (or json? profile-json?)
    (let (report
          (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-report")
                (schemaVersion "1")
                (languageId +language-id+)
                (providerId +provider-id+)
                (status status)
                (scope scope)
                (changedPaths changed-paths)
                (files (length (project-index-files index)))
                (definitions (length (project-definitions index)))
                (agentRepair (agent-repair-report-json findings))
                (findings (map finding-json findings))))
      (when profile-json?
        (hash-put! report 'profile
                   (check-profile-json total-start-ms
                                       collect-profile
                                       type-phase
                                       policy-phase
                                       findings-phase)))
      (write-json-line report))
    (begin
      (displayln "[gerbil-check] status=" status
                 " scope=" scope
                 " files=" (length (project-index-files index))
                 " definitions=" (length (project-definitions index))
                 " findings=" (length findings))
      (display-agent-repair-summary findings)
      (for-each display-finding findings))))

;; : (-> Integer Boolean Boolean String (List String) ProjectIndex Json Json Json Json (List TypeFinding) String String)
(def (render-check-report total-start-ms json? profile-json? scope changed-paths
                          index collect-profile type-phase policy-phase findings-phase
                          findings status)
  (call-with-output-string ""
    (lambda (out)
      (parameterize ((current-output-port out))
        (emit-check-report total-start-ms json? profile-json? scope changed-paths
                           index collect-profile type-phase policy-phase findings-phase
                           findings status)))))

;; check-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `check-main args` runs the Gerbil harness policy check and returns a
;;       process-style status code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (check-main '("--workspace" "." "--full"))
;;       ;; => 0
;;       ```
;;     %
(def (check-main args)
  (if (flag? "--full" args)
    (emit-check-full-removed)
    (let* ((total-start-ms (monotonic-ms))
         (root (path-normalize (project-root args)))
         (json? (flag? "--json" args))
         (profile-json? (flag? "--profile-json" args))
         (scope (check-scope args))
         (whitelist-path (option "--whitelist" args))
         (cache-enabled? (and (equal? scope "full") (not profile-json?)))
         (cache-mode (check-output-mode json? profile-json?))
         (cache-path (and cache-enabled? (check-cache-path root cache-mode)))
         (existing-cache
          (and cache-enabled? (read-check-cache cache-path)))
         (cache-state
          (and cache-enabled?
               (check-cache-state root whitelist-path existing-cache)))
         (cache-fingerprint
          (and cache-state (check-cache-ref cache-state 'fingerprint)))
         (cache-hit
          (and cache-enabled?
               existing-cache
               (matching-check-cache existing-cache cache-fingerprint))))
    (if cache-hit
      (emit-cached-check cache-hit)
      (check-main/cache-miss total-start-ms
                             root
                             json?
                             profile-json?
                             scope
                             whitelist-path
                             cache-enabled?
                             cache-path
                             cache-state)))))

;; : (-> Integer)
(def (emit-check-full-removed)
  (displayln "[gerbil-check] status=error scope=full reason=removed-cli-full message=\"gslph check --full has been removed; use gxtest/library policy integration\"")
  2)

;; check-main/cache-miss
;;   : (-> Integer String Boolean Boolean String MaybePath Boolean MaybePath MaybeCacheState Integer)
;;   | doc m%
;;       Run the non-cached check path after argv parsing and cache lookup have
;;       finished.
;;
;;       Keeping the miss path separate makes the top-level `check-main`
;;       dispatch readable: parse/check cache, emit hit, or run this pipeline.
;;
;;       # Examples
;;
;;       ```scheme
;;       (check-main/cache-miss start "." #f #f "changed" #f #f #f #f)
;;       ;; => process status
;;       ```
;;     %
(def (check-main/cache-miss total-start-ms root json? profile-json? scope
                            whitelist-path cache-enabled? cache-path cache-state)
  (let* ((whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (changed-paths (if (equal? scope "changed")
                          (changed-project-paths root)
                          '()))
         ((values index collect-profile)
          (collect-project/check root scope changed-paths profile-json?))
         ((values type-findings type-phase)
          (timed-check-value
           "type-check"
           (lambda () (run-type-checks/whitelist index '() whitelist))))
         ((values policy-findings policy-phase)
          (timed-check-value
           "policy-check"
           (lambda () (run-policy-checks index))))
         ((values findings findings-phase)
          (timed-check-value
           "filter-findings"
           (lambda ()
             (check-main/filter-findings scope
                                         changed-paths
                                         type-findings
                                         policy-findings))))
         (status (type-status findings))
         (exit-status (if (equal? status "pass") 0 1))
         (output (render-check-report total-start-ms
                                      json?
                                      profile-json?
                                      scope
                                      changed-paths
                                      index
                                      collect-profile
                                      type-phase
                                      policy-phase
                                      findings-phase
                                      findings
                                      status)))
    (display output)
    (when cache-enabled?
      (write-check-cache cache-path cache-state exit-status output))
    exit-status))

;; : (-> String (List String) (List TypeFinding) (List TypeFinding) (List TypeFinding))
(def (check-main/filter-findings scope changed-paths type-findings policy-findings)
  (let (all-findings (append type-findings policy-findings))
    (deduplicate-findings
     (check-main/scope-findings scope changed-paths all-findings))))

;; : (-> String (List String) (List TypeFinding) (List TypeFinding))
(def (check-main/scope-findings scope changed-paths findings)
  (if (equal? scope "changed")
    (filter-changed-findings findings changed-paths)
    findings))
;; : (-> (List String) String)
(def (check-scope args)
  "changed")
;; : (-> String (List String))
(def (changed-project-paths root)
  (unique
   (append
    (git-paths root ["diff" "--name-only" "--" "."])
    (git-paths root ["diff" "--cached" "--name-only" "--" "."])
    (git-paths root ["ls-files" "--others" "--exclude-standard" "--" "."]))))
;; : (-> String (List String) (List String))
(def (git-paths root args)
  (let (output (git-output root (cons "git" args)))
    (if (string=? output "")
      '()
      (string-tokenize output))))
;; git-output
;;   : (-> String (List String) String)
;;   | doc m%
;;       `git-output root command` runs a git command in `root` and returns its
;;       output, or the empty string when git reports a non-zero status.
;;
;;       # Examples
;;
;;       ```scheme
;;       (git-output "." ["git" "status" "--short"])
;;       ;; => status text
;;       ```
;;     %
(def (git-output root command)
  (let (status 0)
    (with-catch
     (lambda (_) "")
     (lambda ()
       (let (output
             (run-process command
                          directory: root
                          stderr-redirection: #t
                          check-status:
                          (lambda (exit-status _settings)
                            (set! status exit-status))))
         (if (zero? status) output ""))))))
;; filter-changed-findings
;;   : (-> (List TypeFinding) ChangedPaths (List TypeFinding))
;;   | doc m%
;;       `filter-changed-findings findings changed-paths` keeps only findings
;;       whose source path is covered by the changed-path set.
;;
;;       # Examples
;;
;;       ```scheme
;;       (filter-changed-findings findings ["src/orders/core.ss"])
;;       ;; => changed-path findings
;;       ```
;;     %
(def (filter-changed-findings findings changed-paths)
  (filter (lambda (finding)
            (changed-path? (type-finding-path finding) changed-paths))
          findings))

;; deduplicate-findings
;;   : (-> (List TypeFinding) (List TypeFinding))
;;   | result first occurrence for each rule/path/selector/message key
;;   | doc m%
;;       `deduplicate-findings findings` keeps the first finding for each
;;       rule/path/selector/message key while preserving report order.
;;
;;       The reducer state is `[seen-keys reversed-output]`; reversing at the
;;       end preserves the input order without a handwritten recursive loop.
;;     %
(def (deduplicate-findings findings)
  (match (foldl deduplicate-finding-state [[] []] findings)
    ([seen out] (reverse out))))

;; : (-> TypeFinding DedupState DedupState)
(def (deduplicate-finding-state finding state)
  (match state
    ([seen out]
     (let (key (finding-dedup-key finding))
       (if (member key seen)
         state
         [(cons key seen) (cons finding out)])))))

;; : (-> TypeFinding (List String))
(def (finding-dedup-key finding)
  [(type-finding-rule-id finding)
   (type-finding-path finding)
   (type-finding-selector finding)
   (type-finding-message finding)])

;; changed-path?
;;   : (-> String ChangedPaths Boolean)
;;   | doc m%
;;       `changed-path? path changed-paths` returns `#t` when `path` is the
;;       changed file itself or the owner directory of a changed file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (changed-path? "src/orders" ["src/orders/core.ss"])
;;       ;; => #t
;;       ```
;;     %
(def (changed-path? path changed-paths)
  (ormap (lambda (changed-path)
           (or (string=? path changed-path)
               (string-prefix? (string-append path "/") changed-path)))
         changed-paths))
;; : (-> TypeFinding Unit)
(def (display-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (display-agent-repair finding)
  (display-finding-details finding))
;; display-agent-repair-summary
;;   : (-> (List TypeFinding) Unit)
;;   | doc m%
;;       `display-agent-repair-summary findings` emits the compact repair
;;       summary line when any finding carries agent repair guidance.
;;
;;       # Examples
;;
;;       ```scheme
;;       (display-agent-repair-summary [])
;;       ;; => (void)
;;       ```
;;     %
(def (display-agent-repair-summary findings)
  (display-check-parts-line "|agent-repair-info"
                            (agent-repair-summary-parts findings)))
;; display-agent-repair
;;   : (-> TypeFinding Unit)
;;   | doc m%
;;       `display-agent-repair finding` emits a repair metadata line when the
;;       finding carries actionable repair parts.
;;
;;       # Examples
;;
;;       ```scheme
;;       (display-agent-repair finding)
;;       ;; => (void)
;;       ```
;;     %
(def (display-agent-repair finding)
  (display-check-parts-line "|agent-repair"
                            (finding-agent-repair-parts finding)))
;; : (List Symbol)
(def +finding-detail-keys+
  '(advice next keepNamedLetWhen styleGuide styleCommand
    expectedCommentShape signatureShape expectedDocShape typedDocRequiredWhen
    typedDocMissing typedDocMissingCount typedDocMissingTargets
    repairAction guideCodeFlag searchExampleCommand repairCodeCommand codeShapeExemplar
    adapterRepairShape agentRepairStandard
    qualityFacets qualityFacetSteering requiredWitness rewriteScope
    evidence kind name selector
    declaredFileName actualFileName declaredNamespace))
;; display-finding-details
;;   : (-> TypeFinding Unit)
;;   | doc m%
;;       `display-finding-details finding` prints normalized detail fields and
;;       guide-oriented repair hints for a finding.
;;
;;       # Examples
;;
;;       ```scheme
;;       (display-finding-details finding)
;;       ;; => (void)
;;       ```
;;     %
(def (display-finding-details finding)
  (display-check-parts-line "|finding-detail"
                            (finding-detail-parts finding)))

;; display-check-parts-line
;;   : (-> String (List String) Unit)
;;   | doc m%
;;       `display-check-parts-line prefix parts` owns line-oriented metadata
;;       rendering for repair and detail fields. Callers pass normalized
;;       display strings so check output keeps one spacing and newline contract.
;;     %
(def (display-check-parts-line prefix parts)
  (when (and parts (pair? parts))
    (display prefix)
    (for-each (lambda (part)
                (display " ")
                (display part))
              parts)
    (newline)))

;; finding-detail-parts
;;   : (-> TypeFinding (List String))
;;   | doc m%
;;       `finding-detail-parts finding` projects optional rule details and
;;       guide hints into the ordered display fields used by check output.
;;     %
(def (finding-detail-parts finding)
  (let* ((details (type-finding-details finding))
         (parts (if details
                  (filter identity
                          (map (cut finding-detail-part details <>)
                               +finding-detail-keys+))
                  [])))
    (append parts (finding-guide-detail-parts finding))))

;; : (-> Details Key (U #f String))
(def (finding-detail-part details key)
  (let (value (finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (datum->display-string value)))))
;; finding-detail-value
;;   : (-> Details Key (U #f Datum))
;;   | doc m%
;;       `finding-detail-value details key` safely returns a detail value, using
;;       `#f` when the details map cannot provide the key.
;;
;;       # Examples
;;
;;       ```scheme
;;       (finding-detail-value details 'selector)
;;       ;; => "src/core.ss:10-12"
;;       ```
;;     %
(def (finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))
;; datum->display-string
;;   : (-> Datum String)
;;   | doc m%
;;       `datum->display-string value` renders any displayable datum into the
;;       compact field-value string used by check output.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->display-string '(typed doc))
;;       ;; => "(typed doc)"
;;       ```
;;     %
(def (datum->display-string value)
  (call-with-output-string "" (cut display value <>)))
