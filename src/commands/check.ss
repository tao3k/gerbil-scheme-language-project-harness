;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Check command adapter.

(import :gerbil/gambit
        :checker/facade
        :constants
        :parser/facade
        (only-in :parser/package read-project-package project-package-name)
        :policy/core
        :policy/repair
        :protocol/json
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/misc/process run-process)
        (only-in :std/misc/list unique)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-tokenize)
        (only-in :std/sugar cut filter ormap)
        :support/args
        :support/time
        (only-in :types/core
                 run-type-checks/whitelist
                 type-status)
        :types/findings)

(export check-main)

(def +check-cache-version+ "check-full-output-cache.v1")

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
      (let* ((collect-report (collect-project/profile root))
             (index (hash-get collect-report 'index))
             (profile (hash-get collect-report 'profile)))
        (values index profile)))
   ((equal? scope "changed")
    (timed-check-value "collect-project/files"
                       (lambda ()
                         (collect-project/files root changed-paths))))
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

;; : (-> String String)
(def (check-cache-dir root)
  (path-expand ".cache/agent-semantic-protocol/gerbil-scheme/check" root))

;; : (-> String String String)
(def (check-cache-path root mode)
  (path-expand (string-append mode ".sexp") (check-cache-dir root)))

;; : (-> String Void)
(def (trim-trailing-slashes path)
  (let loop ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (loop (- end 1))
      (substring path 0 end))))

;; : (-> String Void)
(def (ensure-directory* path)
  (when path
    (let (dir (trim-trailing-slashes path))
      (unless (or (string=? dir "")
                  (string=? dir ".")
                  (file-exists? dir))
        (let (parent (path-directory dir))
          (when (and parent
                     (not (string=? parent dir)))
            (ensure-directory* parent)))
        (unless (file-exists? dir)
          (create-directory dir))))))

;; : (-> String String (List Datum))
(def (check-cache-file-fingerprint root path)
  (with-catch
   (lambda (_) [path 'missing])
   (lambda ()
     (let* ((fullpath (path-expand path root))
            (info (file-info fullpath)))
       [path
        (file-info-size info)
        (time->seconds (file-info-last-modification-time info))]))))

;; : (-> String (U #f String) (U #f Datum) (List Pair))
(def (check-cache-state root whitelist-path existing-cache)
  (let ((inputs (check-cache-ref existing-cache 'inputs))
        (directories (check-cache-ref existing-cache 'directories)))
    (if (and (list? inputs) (list? directories))
      (check-cache-state/from-inputs root inputs directories)
      (check-cache-state/from-source root whitelist-path))))

;; : (-> String (U #f String) (List Pair))
(def (check-cache-state/from-source root whitelist-path)
  (let* ((package (read-project-package root))
         (files (sort (collect-source-files root package) string<?))
         (inputs (sort (if whitelist-path
                         (cons whitelist-path files)
                         files)
                       string<?))
         (directories (check-cache-input-directories inputs)))
    (check-cache-state/from-inputs root inputs directories)))

;; : (-> String (List String) (List String) (List Pair))
(def (check-cache-state/from-inputs root inputs directories)
  (let (fingerprint
    (call-with-output-string ""
      (lambda (out)
        (write [version: +check-cache-version+
                mode: "source-inputs"
                inputs: (map (cut check-cache-file-fingerprint root <>) inputs)
                directories: (map (cut check-cache-file-fingerprint root <>) directories)]
               out))))
    (list (cons 'fingerprint fingerprint)
          (cons 'inputs inputs)
          (cons 'directories directories))))

;; : (-> (List String) (List String))
(def (check-cache-input-directories inputs)
  (let loop ((rest inputs) (directories []))
    (if (null? rest)
      (sort (unique directories) string<?)
      (loop (cdr rest)
            (append (check-cache-path-directories (car rest)) directories)))))

;; : (-> String (List String))
(def (check-cache-path-directories path)
  (let loop ((dir (trim-trailing-slashes (or (path-directory path) ".")))
             (directories []))
    (cond
     ((or (string=? dir "") (string=? dir ".") (string=? dir "./"))
      (cons "." directories))
     (else
      (let (parent (trim-trailing-slashes (or (path-directory dir) ".")))
        (if (or (string=? parent dir)
                (string=? parent "")
                (string=? parent ".")
                (string=? parent "./"))
          (cons "." (cons dir directories))
          (loop parent (cons dir directories))))))))

;; : (-> String (U #f Datum))
(def (read-check-cache cache-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (file-exists? cache-path)
          (call-with-input-file cache-path read)))))

;; : (-> Symbol (List Pair) (U #f Datum))
(def (check-cache-ref cache key)
  (let (entry (and (pair? cache) (assq key cache)))
    (and entry (cdr entry))))

;; : (-> Datum String (U #f Datum))
(def (matching-check-cache cache fingerprint)
  (and cache
       (equal? (check-cache-ref cache 'version) +check-cache-version+)
       (equal? (check-cache-ref cache 'fingerprint) fingerprint)
       cache))

;; : (-> String (List Pair) Integer String Boolean)
(def (write-check-cache cache-path cache-state status output)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ensure-directory* (path-directory cache-path))
     (call-with-output-file cache-path
       (lambda (out)
         (write (list (cons 'version +check-cache-version+)
                      (cons 'fingerprint (check-cache-ref cache-state 'fingerprint))
                      (cons 'inputs (check-cache-ref cache-state 'inputs))
                      (cons 'directories (check-cache-ref cache-state 'directories))
                      (cons 'status status)
                      (cons 'output output))
                out)))
     #t)))

;; : (-> Datum Integer)
(def (emit-cached-check cache)
  (let ((output (check-cache-ref cache 'output))
        (status (check-cache-ref cache 'status)))
    (when output
      (display output))
    (if (integer? status) status 1)))

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
                 (let (all-findings (append type-findings policy-findings))
                   (deduplicate-findings
                    (if (equal? scope "changed")
                      (filter-changed-findings all-findings changed-paths)
                      all-findings))))))
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
        exit-status))))
;; : (-> (List String) String)
(def (check-scope args)
  (if (and (flag? "--changed" args)
           (not (flag? "--full" args)))
    "changed"
    "full"))
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
    expectedCommentShape signatureShape typedCommentMigrationNeeded
    typedCommentMigration expectedDocShape typedDocRequiredWhen
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
