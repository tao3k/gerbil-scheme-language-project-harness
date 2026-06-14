;;; -*- Gerbil -*-
;;; Agent repair metadata derived from policy findings.

(import :types/findings)

(export repairable-finding?
        repairable-findings
        agent-repair-report-json
        agent-repair-summary-parts
        finding-agent-repair-json
        finding-agent-repair-parts
        finding-guide-detail-parts)

;; Boolean <- TypeFinding
(def (repairable-finding? finding)
  (and (finding-agent-repair-json finding) #t))

;;; Boundary:
;;; - repairable-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- (List TypeFinding)
(def (repairable-findings findings)
  (filter repairable-finding? findings))

;; Json <- (List XX)
(def (agent-repair-report-json findings)
  (let* ((repairable (repairable-findings findings))
         (warnings (count-finding-severity repairable "warning"))
         (errors (count-finding-severity repairable "error"))
         (count (length repairable)))
    (hash (status (if (zero? count) "none" "active"))
          (repairableFindings count)
          (repairableWarnings warnings)
          (repairableErrors errors)
          (trigger (repair-trigger warnings errors))
          (instruction
           "follow each finding.agentRepair.nextCommand before editing"))))

;; (List RepairSummaryPart) <- (List TypeFinding)
(def (agent-repair-summary-parts findings)
  (let* ((repairable (repairable-findings findings))
         (warnings (count-finding-severity repairable "warning"))
         (errors (count-finding-severity repairable "error"))
         (count (length repairable)))
    (if (zero? count)
      []
      [(string-append "status=active")
       (string-append "repairableFindings=" (number->string count))
       (string-append "repairableWarnings=" (number->string warnings))
       (string-append "repairableErrors=" (number->string errors))
       (string-append "trigger=" (repair-trigger warnings errors))
       "next=follow-per-finding-agent-repair-nextCommand"])))

;;; Boundary:
;;; - count-finding-severity composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- (List TypeFinding) Severity
(def (count-finding-severity findings severity)
  (length
   (filter (lambda (finding)
             (equal? (type-finding-severity finding) severity))
           findings)))

;; RepairTrigger <- Warnings Errors
(def (repair-trigger warnings errors)
  (cond
   ((and (> warnings 0) (> errors 0)) "warning-or-error")
   ((> errors 0) "error")
   ((> warnings 0) "warning")
   (else "none")))

;; Json <- TypeFinding
(def (finding-agent-repair-json finding)
  (let (route (finding-guide-route (type-finding-rule-id finding)))
    (and route
         (hash (active #t)
               (repairable #t)
               (trigger (type-finding-severity finding))
               (reason "policy-finding")
               (ruleId (type-finding-rule-id finding))
               (severity (type-finding-severity finding))
               (guideTopic (car route))
               (guideIntent (cadr route))
               (nextCommand (caddr route))
               (instruction "run-guide-code-before-edit")))))

;; FindingAgentRepairParts <- TypeFinding
(def (finding-agent-repair-parts finding)
  (let (repair (finding-agent-repair-json finding))
    (if repair
      [(string-append "rule=" (hash-get repair 'ruleId))
       (string-append "severity=" (hash-get repair 'severity))
       "repairable=true"
       "active=true"
       (string-append "trigger=" (hash-get repair 'trigger))
       (string-append "reason=" (hash-get repair 'reason))
       (string-append "guideTopic=" (hash-get repair 'guideTopic))
       (string-append "guideIntent=" (hash-get repair 'guideIntent))
       (string-append "nextCommand=" (hash-get repair 'nextCommand))
       (string-append "instruction=" (hash-get repair 'instruction))]
      [])))

;; String <- TypeFinding
(def (finding-guide-detail-parts finding)
  (let (repair (finding-agent-repair-json finding))
    (if repair
      [(string-append "guideTopic=" (hash-get repair 'guideTopic))
       (string-append "guideIntent=" (hash-get repair 'guideIntent))
       (string-append "nextCommand=" (hash-get repair 'nextCommand))]
      [])))

;;; Boundary:
;;; - finding-guide-route coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; GuideRoute <- Rule
(def (finding-guide-route rule)
  (cond
   ((equal? rule "GERBIL-SCHEME-AGENT-R009")
    ["functional-data-transform"
     "repair"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair"])
   ((equal? rule "GERBIL-SCHEME-AGENT-R011")
    ["macro-runtime-source"
     "witness"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R011 --intent witness"])
   ((equal? rule "GERBIL-SCHEME-AGENT-R013")
    ["typed-combinator-style"
     "style"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R013 --intent style"])
   ((equal? rule "GERBIL-SCHEME-AGENT-R014")
    ["controlled-branch-shape"
     "style"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style"])
   ((equal? rule "GERBIL-SCHEME-AGENT-R015")
    ["engineering-comment-quality"
     "style"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R015 --intent style"])
   ((or (equal? rule "GERBIL-SCHEME-AGENT-R008")
        (equal? rule "GERBIL-SCHEME-AGENT-R012"))
    ["poo-policy"
     "repair"
     (string-append "asp gerbil-scheme guide --code --rule " rule " --intent repair")])
   (else #f)))
