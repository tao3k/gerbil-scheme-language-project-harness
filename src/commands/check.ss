;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Check command adapter.

(import :gerbil/gambit
        :checker/facade
        :constants
        :parser/facade
        :policy/repair
        :protocol/json
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-prefix? string-tokenize)
        (only-in :std/sugar cut filter ormap)
        :support/args
        :support/list
        :types/facade)

(export check-main)
;;; Boundary:
;;; - check-main composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; CheckMain <- (List TypeFinding)
(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (scope (check-scope args))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (index (collect-project root))
         (all-findings (run-type-checks/whitelist index '() whitelist))
         (changed-paths (if (equal? scope "changed")
                          (changed-project-paths root)
                          '()))
         (findings (if (equal? scope "changed")
                     (filter-changed-findings all-findings changed-paths)
                     all-findings))
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
;; String <- (List TypeFinding)
(def (check-scope args)
  (if (and (flag? "--changed" args)
           (not (flag? "--full" args)))
    "changed"
    "full"))
;; String <- String
(def (changed-project-paths root)
  (dedupe
   (append
    (git-paths root ["diff" "--name-only" "--" "."])
    (git-paths root ["ls-files" "--others" "--exclude-standard" "--" "."]))))
;; String <- String (List String)
(def (git-paths root args)
  (let (output (git-output root (cons "git" args)))
    (if (string=? output "")
      '()
      (string-tokenize output))))
;;; Boundary:
;;; - git-output composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; GitOutput <- String String
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
;;; Boundary:
;;; - filter-changed-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- (List TypeFinding) ChangedPaths
(def (filter-changed-findings findings changed-paths)
  (filter (lambda (finding)
            (changed-path? (type-finding-path finding) changed-paths))
          findings))
;;; Boundary:
;;; - changed-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String ChangedPaths
(def (changed-path? path changed-paths)
  (ormap (lambda (changed-path)
           (or (string=? path changed-path)
               (string-prefix? (string-append path "/") changed-path)))
         changed-paths))
;; TypeFinding <- TypeFinding
(def (display-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (display-agent-repair finding)
  (display-finding-details finding))
;;; Boundary:
;;; - display-agent-repair-summary composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- (List TypeFinding)
(def (display-agent-repair-summary findings)
  (let (parts (agent-repair-summary-parts findings))
    (when (pair? parts)
      (display "|agent-repair-info")
      (for-each (lambda (part)
                  (display " ")
                  (display part))
                parts)
      (newline))))
;;; Boundary:
;;; - display-agent-repair composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- TypeFinding
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
    repairAction guideCodeFlag searchExampleCommand repairCodeCommand codeShapeExemplar
    adapterRepairShape agentRepairStandard
    qualityFacets qualityFacetSteering requiredWitness rewriteScope
    evidence kind name selector))
;;; Boundary:
;;; - display-finding-details composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Unit <- TypeFinding
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
;; FindingDetailPart <- Details Key
(def (finding-detail-part details key)
  (let (value (finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (datum->display-string value)))))
;;; Boundary:
;;; - finding-detail-value composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; FindingDetailValue <- Details Key
(def (finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))
;;; Boundary:
;;; - datum->display-string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Datum
(def (datum->display-string value)
  (call-with-output-string "" (cut display value <>)))
