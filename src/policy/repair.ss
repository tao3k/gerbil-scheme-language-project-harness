;;; -*- Gerbil -*-
;;; Agent repair metadata derived from policy findings.

(import :policy/catalog
        (only-in :std/misc/list unique)
        (only-in :std/srfi/1 take)
        :types/findings)

(export repairable-finding?
        repairable-findings
        agent-repair-report-json
        agent-repair-summary-parts
        finding-agent-repair-json
        finding-agent-repair-parts
        finding-guide-detail-parts)

;; : (-> TypeFinding Boolean )
(def (repairable-finding? finding)
  (and (finding-agent-repair-json finding) #t))

;;; Boundary:
;;; - repairable-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) (List TypeFinding) )
(def (repairable-findings findings)
  (filter repairable-finding? findings))

;; : (-> (List TypeFinding) Json )
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
          (findingGroups (finding-groups-json repairable))
	         (repairPlan (repair-plan-json repairable))
         (instruction
           "policy findings are repair triggers; follow the primary findingGroup.repairPlan.nextCommand for code-shape evidence, edit the owner, then rerun check"))))

;; : (-> (List TypeFinding) (List RepairSummaryPart) )
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
	       (string-append "repairGroups="
	                      (number->string (length (finding-groups repairable))))
       "next=follow-primary-findingGroup-repairPlan-nextCommand"
       "action=apply-policy-triggered-repair"])))

;; : (-> (List TypeFinding) Json )
(def (repair-plan-json findings)
  (let (groups (finding-groups-json findings))
    (hash (status (if (null? groups) "none" "active"))
          (groupCount (length groups))
          (primaryGroups (take groups (min 4 (length groups))))
          (strategy "repair once per owner/function selector; structural/style repairs run before comment rationale repairs")
          (requires ["parser-owned functionQualityProfiles when available"
                     "findingGroup primary rule guide"
                     "check/self-apply/bench after grouped repair"]))))

;;; Finding groups are the agent-facing repair unit.
;;; Mapping after grouping prevents repeated warnings from becoming repeated
;;; repair instructions for the same selector.
;; : (-> (List TypeFinding) Json )
(def (finding-groups-json findings)
  (map finding-group-json (finding-groups findings)))

;;; Group findings by selector when possible, then path. This is intentionally
;;; independent from functionQualityProfiles so retired policy findings still get
;;; a repair plan while parser-level profiles come online.
;; : (-> (List TypeFinding) (List FindingGroup) )
(def (finding-groups findings)
  (reverse
   (foldl add-finding-to-group '() findings)))

;; : (-> TypeFinding (List FindingGroup) (List FindingGroup) )
(def (add-finding-to-group finding groups)
  (let* ((key (finding-group-key finding))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons finding (cdr prior)))
            (remove-finding-group key groups))
      (cons (cons key [finding]) groups))))

;;; Removing the prior group keeps fold state immutable.
;;; The replacement group is consed by add-finding-to-group with the new finding
;;; at the front, then reversed during JSON projection.
;; : (-> GroupKey (List FindingGroup) (List FindingGroup) )
(def (remove-finding-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; : (-> TypeFinding GroupKey )
(def (finding-group-key finding)
  (string-append (type-finding-path finding)
                 "|"
                 (or (type-finding-selector finding) "")))

;;; Group JSON preserves both the primary rule and suppressed dependents.
;;; Agents get one next command plus the repair order, so comment polish does
;;; not race ahead of structural/style fixes.
;; : (-> FindingGroup Json )
(def (finding-group-json group)
  (let* ((findings (reverse (cdr group)))
         (primary (primary-finding findings))
         (rules (map type-finding-rule-id findings))
         (suppressed (suppressed-dependent-rules rules))
         (repair-order (repair-order-rules rules primary suppressed))
         (strategy (repair-strategy rules suppressed))
         (phases (repair-phases repair-order suppressed))
         (next (or (agent-rule-guide-next-command
                    (type-finding-rule-id primary))
                   "")))
    (hash (ownerPath (type-finding-path primary))
          (selector (or (type-finding-selector primary) ""))
          (definitionName (finding-group-definition-name findings))
          (rules rules)
          (severityMax (finding-group-severity findings))
          (primaryRule (type-finding-rule-id primary))
          (multiPolicy (repair-multi-policy-group? rules))
          (repairStrategy strategy)
          (primaryRepairClass
           (or (agent-rule-topic (type-finding-rule-id primary))
               "policy-finding"))
          (suppressedRules suppressed)
          (requiredWitnesses (finding-group-required-witnesses rules))
          (repairOrder repair-order)
          (repairPlan
	          (hash (nextCommand next)
	                (triggerSource (string-append "policy-" (finding-group-severity findings)))
	                (action "apply-policy-triggered-repair")
	                (guideCodeFlag "--code")
                  (strategy strategy)
                  (repairPhases phases)
	                (instruction
	                  "treat this policy finding group as the edit trigger: run the primary guide --code command for code-shape evidence, apply one grouped repair, preserve listed witnesses, then rerun check")
	                (commentRepairOrder
	                  "comment-quality repairs run after structural/style repairs when both hit the same group")))
          (agentInstruction
           "treat this group as one function-level repair boundary, not independent warning spam"))))

;;; Primary finding selects the strongest repair class in a group.
;;; Lower numeric priority wins so structural drift controls comment-only noise.
;; : (-> (List TypeFinding) TypeFinding )
(def (primary-finding findings)
  (foldl (lambda (finding best)
           (if (< (rule-repair-priority (type-finding-rule-id finding))
                  (rule-repair-priority (type-finding-rule-id best)))
             finding
             best))
         (car findings)
         (cdr findings)))

;; : (-> RuleId Integer )
(def (rule-repair-priority rule-id)
  (cond
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R017") 8)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R016") 10)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R014") 20)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R013") 30)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R015") 40)
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R011") 45)
   (else 90)))

;;; Definition names are best-effort metadata for repair receipts.
;;; The group key remains selector/path based when parser facts do not expose a
;;; definition name.
;; : (-> (List TypeFinding) String )
(def (finding-group-definition-name findings)
  (or (ormap finding-definition-name findings)
      ""))

;; : (-> TypeFinding String )
(def (finding-definition-name finding)
  (or (finding-detail-field finding 'definition)
      (finding-detail-field finding 'target)
      (finding-detail-field finding 'subject)
      (finding-detail-field finding 'targetName)))

;; : (-> TypeFinding Field Value )
(def (finding-detail-field finding field)
  (let (details (type-finding-details finding))
    (and details
         (hash-key? details field)
         (hash-get details field))))

;;; Group severity is a max over member severities.
;;; Any error makes the whole repair boundary error-level for CI reporting.
;; : (-> (List TypeFinding) Severity )
(def (finding-group-severity findings)
  (if (ormap (lambda (finding)
               (equal? (type-finding-severity finding) "error"))
             findings)
    "error"
    "warning"))

;;; Suppression keeps dependent comment warnings visible but non-primary.
;;; When stronger shape rules are present, agents repair structure first and
;;; revisit comments after code shape stabilizes.
;; : (-> (List RuleId) (List RuleId) )
(def (suppressed-dependent-rules rules)
  (if (and (member "GERBIL-SCHEME-AGENT-R015" rules)
           (ormap (cut member <> rules)
                  ["GERBIL-SCHEME-AGENT-R013"
                   "GERBIL-SCHEME-AGENT-R014"
                   "GERBIL-SCHEME-AGENT-R016"
                   "GERBIL-SCHEME-AGENT-R017"]))
    ["GERBIL-SCHEME-AGENT-R015"]
    []))

;;; Required witnesses merge rule needs into a deduped checklist.
;;; The apply/map shape keeps the witness catalog rule-owned while the group
;;; owns aggregation.
;; : (-> (List RuleId) (List Witness) )
(def (finding-group-required-witnesses rules)
  (unique
   (apply append
          (map rule-required-witnesses rules))))

;; : (-> RuleId (List Witness) )
(def (rule-required-witnesses rule-id)
  (cond
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R017")
    ["dependencyAdapterQualityFacts" "moduleImportFacts" "genericContractTestWitness"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R016")
    ["predicateFamilyFacts" "fieldAccessPatternFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R014")
    ["controlFlowFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R013")
    ["typedContractFacts" "higherOrderFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R015")
    ["commentQualityFacts" "functionQualityProfile"])
   ((equal? rule-id "GERBIL-SCHEME-AGENT-R011")
    ["runtimeSourceMacroWitness"])
   (else ["policyFinding"])))

;;; Repair order starts with the primary rule and appends suppressed rules last.
;;; This sequence gives the agent a deterministic one-pass repair plan.
;; : (-> (List RuleId) TypeFinding (List RuleId) (List RuleId) )
(def (repair-order-rules rules primary suppressed)
  (unique
   (append [(type-finding-rule-id primary)]
           (filter (lambda (rule) (not (member rule suppressed)))
                   rules)
           suppressed)))

;;; Strategy names are derived from group shape, not from one rule id.
;;; Multi-policy groups with suppressed comment rules require shape-first repair,
;;; while simple groups keep the single guide command contract.
;; : (-> (List RuleId) (List RuleId) RepairStrategy )
(def (repair-strategy rules suppressed)
  (cond
   ((and (repair-multi-policy-group? rules) (pair? suppressed))
    "multi-policy-structural-first")
   ((repair-multi-policy-group? rules)
    "multi-policy-single-edit")
   (else "single-policy-guide")))

;;; Boolean output is JSON-visible, so agents can distinguish grouped repairs
;;; from independent one-rule warnings without re-parsing rule arrays.
;; : (-> (List RuleId) Boolean )
(def (repair-multi-policy-group? rules)
  (> (length (unique rules)) 1))

;;; Repair phases turn a grouped rule list into an ordered action packet.
;;; Suppressed comment rules become an explicit second phase instead of hidden
;;; warning noise, preserving structure-first repair.
;; : (-> (List RuleId) (List RuleId) (List RepairPhase) )
(def (repair-phases repair-order suppressed)
  (let ((primary-rules (filter (lambda (rule) (not (member rule suppressed)))
                               repair-order)))
    (filter identity
            [(and (pair? primary-rules)
                  (repair-phase
                   "primary-shape"
                   primary-rules
                   "apply-policy-triggered-repair"
                   "apply the primary structural/style repair once because this policy group fired"))
             (and (pair? suppressed)
                  (repair-phase
                   "dependent-comment-rationale"
                   suppressed
                   "repair-comment-rationale-after-shape"
                   "update engineering comments after the code shape is stable"))])))

;;; Phase packets are intentionally small: name, rules, action, instruction.
;;; The rule ids still route to the central guide catalog.
;; : (-> String (List RuleId) Action Instruction RepairPhase )
(def (repair-phase name rules action instruction)
  (hash (name name)
        (rules rules)
        (action action)
        (instruction instruction)))

;;; Boundary:
;;; - count-finding-severity composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Severity Integer )
(def (count-finding-severity findings severity)
  (length
   (filter (lambda (finding)
             (equal? (type-finding-severity finding) severity))
           findings)))

;; : (-> Warnings Errors RepairTrigger )
(def (repair-trigger warnings errors)
  (cond
   ((and (> warnings 0) (> errors 0)) "warning-or-error")
   ((> errors 0) "error")
   ((> warnings 0) "warning")
   (else "none")))

;; : (-> TypeFinding Json )
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
	               (action "apply-policy-triggered-repair")
	               (guideCodeFlag "--code")
	               (nextCommand (caddr route))
	               (instruction "policy-finding-triggers-edit-with-guide-code-evidence")))))

;; : (-> TypeFinding FindingAgentRepairParts )
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
	       (string-append "action=" (hash-get repair 'action))
	       (string-append "guideCodeFlag=" (hash-get repair 'guideCodeFlag))
	       (string-append "nextCommand=" (hash-get repair 'nextCommand))
	       (string-append "instruction=" (hash-get repair 'instruction))]
      [])))

;; : (-> TypeFinding String )
(def (finding-guide-detail-parts finding)
  (let (repair (finding-agent-repair-json finding))
    (if repair
	      [(string-append "guideTopic=" (hash-get repair 'guideTopic))
	       (string-append "guideIntent=" (hash-get repair 'guideIntent))
	       (string-append "action=" (hash-get repair 'action))
	       (string-append "guideCodeFlag=" (hash-get repair 'guideCodeFlag))
	       (string-append "nextCommand=" (hash-get repair 'nextCommand))]
      [])))

;;; Boundary:
;;; - finding-guide-route reads the central agent rule catalog.
;;; - Keep packet shape and invariants stable.
;; : (-> Rule GuideRoute )
(def (finding-guide-route rule)
  (agent-rule-guide-route rule))
