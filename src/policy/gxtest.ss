;;; -*- Gerbil -*-
;;; Tiny gxtest adapter for downstream packages that depend on this harness.

(import :gerbil/gambit
        :build-api/source-coverage
        :constants
        (for-syntax :gerbil/expander
                    :std/stxutil)
        :parser/facade
        :policy/facade
        (only-in :std/test check test-case test-suite)
        :types/facade)

(export make-policy-test
        make-file-policy-test
        make-gxtest-policy-test
        policy-findings
        policy-status
        policy-report
        make-project-policy-test
        project-policy-findings
        project-policy-status
        project-policy-report
        display-project-policy-report)

;;; Macro boundary:
;;; - Downstream gxtest aggregators call this inside their normal test suite.
;;; - The expansion captures the file that owns the gxtest policy entry, so the
;;;   policy check runs as one ordinary gxtest test instead of a build-target
;;;   pre-pass over the same scope.
;; make-gxtest-policy-test
;;   : (-> Syntax Syntax)
;;   | doc m%
;;       Expand into a gxtest policy test rooted at the supplied project root.
;;
;;       # Examples
;;
;;       ```scheme
;;       (test-suite "project tests"
;;         (make-gxtest-policy-test ".")
;;         project-unit-tests)
;;       ;; => TestSuite
;;       ```
;;     %
(defsyntax (make-gxtest-policy-test stx)
  (let* ((form (syntax->datum stx))
         (root (and (pair? (cdr form)) (cadr form)))
         (source (stx-source stx))
         (file (and source (vector-ref source 0))))
    (cond
     ((not (and (pair? form) (pair? (cdr form)) (null? (cddr form))))
      (error "bad make-gxtest-policy-test syntax"))
     ((not (string? file))
      (error "make-gxtest-policy-test requires a file-backed source location"))
     (else
      (datum->syntax (stx-car stx)
                     `(gslph/src/policy/gxtest#make-file-policy-test
                       ,root
                       ,file))))))

;;; Boundary:
;;; - make-policy-test is the default gxtest bridge for downstream packages.
;;; - The caller supplies target files explicitly; build/test owners should pass
;;;   their internal test scope here instead of relying on process argv.
;; : (-> Root (List Path) TestSuite )
(def (make-policy-test root files)
  (test-suite "gerbil scheme scoped policy"
    (test-case "package policy passes for test scope"
      (let (report (policy-report root files))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))

;; : (-> Root Path TestSuite )
(def (make-file-policy-test root file)
  (make-policy-test root [file]))

;;; Boundary:
;;; - make-project-policy-test is the explicit full-project gate.
;;; - Regular gxtest targets should use make-policy-test with their file scope.
;; : (-> Root TestSuite )
(def (make-project-policy-test root)
  (test-suite "gerbil scheme project policy"
    (test-case "package policy passes"
      (let (report (project-policy-report root))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))

;; : (-> Root (List Path) (List TypeFinding) )
(def (policy-findings root files)
  (run-policy-checks (collect-test-source-scope root files)))

;; : (-> Root (List Path) String )
(def (policy-status root files)
  (type-status (policy-findings root files)))

;;; Boundary:
;;; - policy-report is the stable files-scoped downstream gxtest data surface.
;;; - Package metadata is read for policy configuration, but execution only
;;;   parses files supplied by the test runner.
;; : (-> Root (List Path) Json )
(def (policy-report root files)
  (let* ((index (collect-test-source-scope root files))
         (findings (run-policy-checks index)))
    (project-policy-report-json index findings "files" files)))

;; : (-> Root (List TypeFinding) )
(def (project-policy-findings root)
  (run-policy-checks (project-policy-index root)))
;; : (-> Root String )
(def (project-policy-status root)
  (type-status (project-policy-findings root)))
;;; Boundary:
;;; - project-policy-report is the stable downstream gxtest data surface.
;;; - Coverage follows the build.ss source coverage declaration instead of a
;;;   separate whole-repository scan.
;; : (-> Root Json )
(def (project-policy-report root)
  (let* ((index (project-policy-index root))
         (findings (run-policy-checks index)))
    (project-policy-report-json index findings "project" #f)))

;; : (-> Root ProjectIndex)
(def (project-policy-index root)
  (collect-source-scope root (gslph-source-coverage-files root)))

;; : (-> ProjectIndex (List TypeFinding) String MaybePaths Json )
(def (project-policy-report-json index findings scope requested-files)
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-gxtest-report")
          (schemaVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (scope scope)
          (requestedFiles (or requested-files []))
          (status (type-status findings))
          (files (length (project-index-files index)))
          (definitions (length (project-definitions index)))
          (agentRepair (agent-repair-report-json findings))
          (findings findings)))
;;; Boundary:
;;; - display-project-policy-report mirrors check output for failing gxtest runs.
;;; - Keep the line protocol compact so downstream CI logs stay readable.
;; : (-> PolicyReport Unit )
(def (display-project-policy-report report)
  (let (findings (hash-get report 'findings))
    (displayln "[gerbil-gxtest] status=" (hash-get report 'status)
               " files=" (hash-get report 'files)
               " definitions=" (hash-get report 'definitions)
               " findings=" (length findings))
    (display-project-policy-agent-repair-summary findings)
    (for-each display-project-policy-finding findings)))
;; : (-> (List TypeFinding) Unit )
(def (display-project-policy-agent-repair-summary findings)
  (display-project-policy-line "|agent-repair-info"
                               (agent-repair-summary-parts findings)))
;;; Boundary:
;;; - Finding lines expose the same selector/message/detail fields as check.
;;; - Agent repair stays adjacent to the finding that triggered it.
;; : (-> TypeFinding Unit )
(def (display-project-policy-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (display-project-policy-line "|agent-repair"
                               (finding-agent-repair-parts finding))
  (display-project-policy-line
   "|finding-detail"
   (append (project-policy-finding-detail-parts finding)
           (finding-guide-detail-parts finding))))
;;; Render each part with a shared prefix so gxtest failure logs stay line-oriented.
;;; The one-argument lambda is safe because repair/detail parts are already display-ready strings.
;; : (-> Prefix (List String) Unit )
(def (display-project-policy-line prefix parts)
  (when (and parts (pair? parts))
    (display prefix)
    (for-each (lambda (part)
                (display " ")
                (display part))
              parts)
    (newline)))
;; : (List Key)
(def +project-policy-finding-detail-keys+
  '(advice next keepNamedLetWhen styleGuide styleCommand
    expectedCommentShape signatureShape typedCommentMigrationNeeded
    typedCommentMigration
    expectedDocShape typedDocRequiredWhen typedDocMissing
    typedDocMissingCount typedDocMissingTargets
    repairAction guideCodeFlag searchExampleCommand repairCodeCommand
    codeShapeExemplar adapterRepairShape agentRepairStandard
    qualityFacets qualityFacetSteering requiredWitness rewriteScope
    evidence kind name selector))
;;; Preserve detail key order with map, then filter absent policy-specific fields.
;;; This keeps compact output stable without forcing every finding to carry every detail slot.
;; : (-> TypeFinding (List String) )
(def (project-policy-finding-detail-parts finding)
  (let (details (type-finding-details finding))
    (if details
      (filter (lambda (part) part)
              (map (lambda (key)
                     (project-policy-finding-detail-part details key))
                   +project-policy-finding-detail-keys+))
      [])))
;; : (-> Details Key MaybeString )
(def (project-policy-finding-detail-part details key)
  (let (value (project-policy-finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (project-policy-datum->display-string value)))))
;;; Finding details are optional and policy-specific, so missing keys should not hide the original failure.
;;; The protected lookup keeps custom downstream reports usable across mixed harness versions.
;; : (-> Details Key MaybeDatum )
(def (project-policy-finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))
;;; Use a display port conversion so symbols, lists, and strings keep their Scheme-readable shape.
;;; A one-argument port lambda keeps the resource scope local to the conversion.
;; : (-> Datum String )
(def (project-policy-datum->display-string value)
  (call-with-output-string "" (lambda (port) (display value port))))
