;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Check command adapter.

(import :gerbil/gambit
        :checker/facade
        :constants
        :parser/facade
        :policy/core
        :policy/repair
        :protocol/json
        (only-in :std/misc/process run-process)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-prefix? string-tokenize)
        (only-in :std/sugar cut filter ormap)
        :support/args
        (only-in :types/core
                 run-type-checks/whitelist
                 type-status)
        :types/findings)

(export check-main)
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
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (scope (check-scope args))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (changed-paths (if (equal? scope "changed")
                          (changed-project-paths root)
                          '()))
         (index (if (equal? scope "changed")
                  (collect-project/files root changed-paths)
                  (collect-project root)))
         (all-findings (append
                        (run-type-checks/whitelist index '() whitelist)
                        (run-policy-checks index)))
         (findings (deduplicate-findings
                    (if (equal? scope "changed")
                      (filter-changed-findings all-findings changed-paths)
                      all-findings)))
         (status (type-status findings)))
    (if json?
      (write-json-line
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
      (begin
        (displayln "[gerbil-check] status=" status
                   " scope=" scope
                   " files=" (length (project-index-files index))
                   " definitions=" (length (project-definitions index))
                   " findings=" (length findings))
        (display-agent-repair-summary findings)
        (for-each display-finding findings)))
    (if (equal? status "pass") 0 1)))
;; : (-> (List TypeFinding) String )
(def (check-scope args)
  (if (and (flag? "--changed" args)
           (not (flag? "--full" args)))
    "changed"
    "full"))
;; : (-> String String )
(def (changed-project-paths root)
  (unique
   (append
    (git-paths root ["diff" "--name-only" "--" "."])
    (git-paths root ["diff" "--cached" "--name-only" "--" "."])
    (git-paths root ["ls-files" "--others" "--exclude-standard" "--" "."]))))
;; : (-> String (List String) String )
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

;;; State invariant: the reducer carries parser-owned dedup keys separately
;;; from the reversed output so duplicate suppression stays a pure transform.
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
;; : (-> TypeFinding TypeFinding )
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
  (let (parts (agent-repair-summary-parts findings))
    (when (pair? parts)
      (display "|agent-repair-info")
      (for-each (lambda (part)
                  (display " ")
                  (display part))
                parts)
      (newline))))
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
  (let (parts (finding-agent-repair-parts finding))
    (when (pair? parts)
      (display "|agent-repair")
      (for-each (lambda (part)
                  (display " ")
                  (display part))
                parts)
      (newline))))
;; ConfigConstant
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
  (let* ((details (type-finding-details finding))
         (parts (and details
                     (filter identity
                             (map (cut finding-detail-part details <>)
                                  +finding-detail-keys+))))
         (guide-parts (finding-guide-detail-parts finding))
         (all-parts (append (or parts []) guide-parts)))
    (when (and all-parts (pair? all-parts))
      (display "|finding-detail")
      (for-each (lambda (part)
                  (display " ")
                  (display part))
                all-parts)
      (newline))))
;; : (-> Details Key FindingDetailPart )
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
