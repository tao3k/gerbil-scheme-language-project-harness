;;; -*- Gerbil -*-
;;; Tiny gxtest adapter for downstream packages that depend on this harness.

(import :constants
        :parser/facade
        :policy/facade
        (only-in :std/test check test-case test-suite)
        :types/facade)

(export make-project-policy-test
        project-policy-findings
        project-policy-status
        project-policy-report
        display-project-policy-report)
;;; Boundary:
;;; - make-project-policy-test is the minimal gxtest bridge for package policy.
;;; - Policy ownership stays in gerbil.pkg and optional external config files.
;; TestSuite <- Root
(def (make-project-policy-test root)
  (test-suite "gerbil scheme project policy"
    (test-case "package policy passes"
      (let (report (project-policy-report root))
        (when (not (equal? (hash-get report 'status) "pass"))
          (display-project-policy-report report))
        (check (hash-get report 'status) => "pass")))))
;; (List TypeFinding) <- Root
(def (project-policy-findings root)
  (run-policy-checks (collect-project root)))
;; String <- Root
(def (project-policy-status root)
  (type-status (project-policy-findings root)))
;;; Boundary:
;;; - project-policy-report is the stable downstream gxtest data surface.
;;; - Findings stay as TypeFinding values so test code can inspect rich details.
;; Json <- Root
(def (project-policy-report root)
  (let* ((index (collect-project root))
         (findings (run-policy-checks index)))
    (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-gxtest-report")
          (schemaVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (status (type-status findings))
          (files (length (project-index-files index)))
          (definitions (length (project-definitions index)))
          (agentRepair (agent-repair-report-json findings))
          (findings findings))))
;;; Boundary:
;;; - display-project-policy-report mirrors check output for failing gxtest runs.
;;; - Keep the line protocol compact so downstream CI logs stay readable.
;; Unit <- PolicyReport
(def (display-project-policy-report report)
  (let (findings (hash-get report 'findings))
    (displayln "[gerbil-gxtest] status=" (hash-get report 'status)
               " files=" (hash-get report 'files)
               " definitions=" (hash-get report 'definitions)
               " findings=" (length findings))
    (display-project-policy-agent-repair-summary findings)
    (for-each display-project-policy-finding findings)))
;; Unit <- (List TypeFinding)
(def (display-project-policy-agent-repair-summary findings)
  (display-project-policy-line "|agent-repair-info"
                               (agent-repair-summary-parts findings)))
;;; Boundary:
;;; - Finding lines expose the same selector/message/detail fields as check.
;;; - Agent repair stays adjacent to the finding that triggered it.
;; Unit <- TypeFinding
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
;; Unit <- Prefix (List String)
(def (display-project-policy-line prefix parts)
  (when (and parts (pair? parts))
    (display prefix)
    (for-each (lambda (part)
                (display " ")
                (display part))
              parts)
    (newline)))
;; ConfigConstant
(def +project-policy-finding-detail-keys+
  '(advice next keepNamedLetWhen styleGuide styleCommand
    repairAction guideCodeFlag searchExampleCommand repairCodeCommand
    codeShapeExemplar adapterRepairShape agentRepairStandard
    qualityFacets qualityFacetSteering requiredWitness rewriteScope
    evidence kind name selector))
;;; Preserve detail key order with map, then filter absent policy-specific fields.
;;; This keeps compact output stable without forcing every finding to carry every detail slot.
;; (List String) <- TypeFinding
(def (project-policy-finding-detail-parts finding)
  (let (details (type-finding-details finding))
    (if details
      (filter (lambda (part) part)
              (map (lambda (key)
                     (project-policy-finding-detail-part details key))
                   +project-policy-finding-detail-keys+))
      [])))
;; MaybeString <- Details Key
(def (project-policy-finding-detail-part details key)
  (let (value (project-policy-finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (project-policy-datum->display-string value)))))
;;; Finding details are optional and policy-specific, so missing keys should not hide the original failure.
;;; The protected lookup keeps custom downstream reports usable across mixed harness versions.
;; MaybeDatum <- Details Key
(def (project-policy-finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))
;;; Use a display port conversion so symbols, lists, and strings keep their Scheme-readable shape.
;;; A one-argument port lambda keeps the resource scope local to the conversion.
;; String <- Datum
(def (project-policy-datum->display-string value)
  (call-with-output-string "" (lambda (port) (display value port))))
