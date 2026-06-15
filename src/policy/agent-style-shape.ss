;;; -*- Gerbil -*-
;;; Agent-facing branch-shape and predicate-family style policy checks.

(import :parser/facade
        :policy/agent-support
        :policy/model
        (only-in :std/sugar cut filter filter-map foldl hash ormap)
        :support/list
        :types/findings)

(export controlled-branch-shape-findings
        controlled-branch-shape-finding
        predicate-family-combinator-findings
        predicate-family-combinator-finding)

;;; Branch-shape entrypoint:
;;; - Emit findings only after parser-owned control-flow facts group repeated shapes.
;;; - Keep style repair bounded to one source owner at a time.
;; (List TypeFinding) <- ProjectIndex
(def (controlled-branch-shape-findings index)
  (apply append
         (map (cut file-controlled-branch-shape-findings index <>)
              (project-index-files index))))

;;; Predicate-family entrypoint:
;;; - Require native predicateFamilyFacts before suggesting helper extraction.
;;; - Preserve public predicate names unless the owning policy later changes.
;; (List TypeFinding) <- ProjectIndex
(def (predicate-family-combinator-findings index)
  (apply append
         (map (cut file-predicate-family-combinator-findings index <>)
              (project-index-files index))))

;;; Policy gate: repeated predicates must be parser-owned before agent style repair can touch them.
;; (List TypeFinding) <- ProjectIndex SourceFile
(def (file-predicate-family-combinator-findings index file)
  (if (index-source-runtime-file-path? index (source-file-path file))
    (filter-map (cut predicate-family-combinator-finding file <>)
                (source-file-predicate-family-facts file))
    '()))

;; TypeFinding <- SourceFile PredicateFamilyFact
(def (predicate-family-combinator-finding file fact)
  (and (>= (predicate-family-fact-predicate-count fact) 3)
       (make-type-finding
        (policy-rule-id +agent-predicate-family-combinator-rule+)
        (policy-rule-severity +agent-predicate-family-combinator-rule+)
        (source-file-path file)
        (predicate-family-combinator-message fact)
        (predicate-family-fact-selector fact)
        (predicate-family-combinator-details file fact))))

;; Message <- PredicateFamilyFact
(def (predicate-family-combinator-message fact)
  (string-append
   "predicate family over "
   (predicate-family-fact-subject fact)
   " repeats field/role condition helpers; keep repair policy-driven, extract selector helpers or a bounded predicate combinator before editing for style or performance"))

;;; Details deliberately preserve both the family fact and the field-access
;;; facts: the model sees why a helper/combinator rewrite is allowed, while the
;;; policy remains agnostic about exact helper names.
;; PolicyDetails <- SourceFile PredicateFamilyFact
(def (predicate-family-combinator-details file fact)
  (hash (styleGuide "predicate-family-combinator")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style")
        (qualityReference "gerbil-utils")
        (evidenceSource "parser-owned predicateFamilyFacts plus fieldAccessPatternFacts")
        (subject (predicate-family-fact-subject fact))
        (predicateCount (predicate-family-fact-predicate-count fact))
        (predicateNames
         (take-at-most (predicate-family-fact-predicate-names fact) 8))
        (fieldKeys (predicate-family-fact-field-keys fact))
        (repeatedCallees (predicate-family-fact-repeated-callees fact))
        (conditionCount (predicate-family-fact-condition-count fact))
        (qualityFacets (predicate-family-fact-quality-facets fact))
        (fieldAccessPatterns
         (take-at-most
          (map field-access-pattern-repair-evidence
               (source-file-field-access-pattern-facts file))
          6))
        (agentRepairStandard "rewrite toward gerbil-utils style: keep predicate names stable, extract role/field selector helpers, and compose small expression-returning predicates")
        (agentRepairEnvelope
         (hash (flexibility "agent may choose helper names, role-set tables, or predicate combinator shape")
               (constraints ["preserve public predicate behavior"
                             "stay in the same owner unless exports require a facade change"
                             "do not rewrite IO/runtime/macro boundaries without witness"])))
        (next "guide --code --rule GERBIL-SCHEME-AGENT-R016 --intent style")))

;; RepairEvidence <- FieldAccessPatternFact
(def (field-access-pattern-repair-evidence fact)
  (hash (fieldKey (field-access-pattern-fact-field-key fact))
        (accessCount (field-access-pattern-fact-access-count fact))
        (accessors (field-access-pattern-fact-accessors fact))
        (callers (take-at-most (field-access-pattern-fact-callers fact) 8))
        (selector (field-access-pattern-fact-selector fact))
        (advice (field-access-pattern-fact-advice fact))))

;;; Runtime-source gate:
;;; - Only source-runtime owners participate in branch-shape repair.
;;; - Test and generated owners can still expose facts without style findings.
;; (List TypeFinding) <- ProjectIndex SourceFile
(def (file-controlled-branch-shape-findings index file)
  (if (index-source-runtime-file-path? index (source-file-path file))
    (filter-map (cut controlled-branch-shape-finding file <>)
                (controlled-branch-shape-groups
                 (filter controlled-branch-shape-control-flow?
                         (source-file-control-flow-forms file))))
    '()))

;; Boolean <- ControlFlowFact
(def (pattern-branch-control-flow? fact)
  (equal? (control-flow-fact-role fact) "pattern-branch"))

;; Boolean <- ControlFlowFact
(def (manual-loop-control-flow? fact)
  (equal? (control-flow-fact-role fact) "manual-loop"))

;;; Shape classifier:
;;; - Keep the branch/loop predicate list explicit so policies can add roles safely.
;;; - Avoid broad style findings when parser facts have not classified control flow.
;; Boolean <- ControlFlowFact
(def (controlled-branch-shape-control-flow? fact)
  (ormap (lambda (predicate) (predicate fact))
         [pattern-branch-control-flow?
          manual-loop-control-flow?]))

;;; Grouping reducer:
;;; - Fold by caller so repeated branch shapes are repaired within one behavior boundary.
;;; - Preserve all facts for the later message and details packet.
;; (List ControlFlowGroup) <- (List ControlFlowFact)
(def (controlled-branch-shape-groups facts)
  (foldl (lambda (fact groups)
           (add-control-flow-shape-group groups fact))
         '()
         facts))

;; (List ControlFlowGroup) <- (List ControlFlowGroup) ControlFlowFact
(def (add-control-flow-shape-group groups fact)
  (let* ((key (control-flow-shape-group-key fact))
         (prior (assoc key groups)))
    (if prior
      (cons (cons key (cons fact (cdr prior)))
            (remove-control-flow-shape-group key groups))
      (cons (cons key [fact]) groups))))

;;; Group replacement helper:
;;; - Remove the prior caller group before consing the updated group.
;;; - This keeps foldl output deterministic without mutating the accumulator.
;; (List ControlFlowGroup) <- ControlFlowCaller (List ControlFlowGroup)
(def (remove-control-flow-shape-group key groups)
  (filter (lambda (group) (not (equal? (car group) key))) groups))

;; (List ControlFlowFact) <- ControlFlowFact
(def (control-flow-shape-group-key fact)
  (or (control-flow-fact-caller fact) "<top-level>"))

;;; Shape decision:
;;; - Repeated pattern branches and stateful selector loops are distinct repairs.
;;; - Return #f for single-branch or low-evidence groups so advice stays quiet.
;; String <- ControlFlowGroup
(def (controlled-branch-shape-kind group)
  (let* ((facts (cdr group))
         (pattern-facts (filter pattern-branch-control-flow? facts))
         (manual-loop-facts (filter state-selector-manual-loop? facts)))
    (cond
     ((> (length pattern-facts) 1) "repeated-pattern-branch")
     ((and (pair? pattern-facts) (pair? manual-loop-facts))
      "pattern-branch-with-manual-loop")
     (else #f))))

;; Boolean <- ControlFlowFact
(def (state-selector-manual-loop? fact)
  (and (manual-loop-control-flow? fact)
       (>= (control-flow-fact-binding-count fact) 4)
       (<= (control-flow-fact-line-span fact) 24)))

;; Integer <- ControlFlowFact
(def (control-flow-fact-line-span fact)
  (fx1+ (- (control-flow-fact-end fact)
           (control-flow-fact-start fact))))

;;; Finding assembly:
;;; - Use the earliest control-flow fact as selector anchor for stable repair.
;;; - Preserve all grouped facts in details instead of choosing rewrite shape here.
;; TypeFinding <- SourceFile ControlFlowGroup
(def (controlled-branch-shape-finding file group)
  (let (shape-kind (controlled-branch-shape-kind group))
    (and shape-kind
         (let* ((caller (car group))
                (facts (cdr group))
                (pattern-facts (filter pattern-branch-control-flow? facts))
                (manual-loop-facts (filter state-selector-manual-loop? facts))
                (first-fact (earliest-control-flow-fact facts)))
           (make-type-finding
            (policy-rule-id +agent-controlled-branch-shape-rule+)
            (policy-rule-severity +agent-controlled-branch-shape-rule+)
            (source-file-path file)
            (controlled-branch-shape-message caller shape-kind)
            (control-flow-fact-selector first-fact)
            (controlled-branch-shape-details
             caller
             shape-kind
             pattern-facts
             manual-loop-facts
             first-fact))))))

;; PolicyDetails <- String String ControlFlowFacts ControlFlowFacts ControlFlowFact
(def (controlled-branch-shape-details caller shape-kind pattern-facts manual-loop-facts first-fact)
  (hash (caller caller)
        (shape shape-kind)
        (matchCount (length pattern-facts))
        (manualLoopCount (length manual-loop-facts))
        (selector (control-flow-fact-selector first-fact))
        (evidence "parser-owned controlFlowFacts role=pattern-branch plus manual-loop bindingCount>=4")
        (advice "do not refactor opportunistically; wait for this policy finding, preserve behavior, and use guide code for controlled branch shape")
        (styleGuide "controlled-branch-shape")
        (styleCommand "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")
        (rewriteScope "same caller or extracted helper only")
        (qualityReference "gerbil-utils")
        (functionShape "small selector/predicate/helper first; keep match branches shallow and expression-returning")
        (agentRepairStandard "rewrite toward gerbil-utils style: extract branch selectors, replace stateful named-let with fold/filter-map when pure, keep IO/state drivers explicit")
        (expressionLevelRewrite "turn repeated match plus accumulator shape into a named predicate/mapper/reducer pipeline before changing behavior")
        (next "guide --code --rule GERBIL-SCHEME-AGENT-R014 --intent style")))

;; Message <- String String
(def (controlled-branch-shape-message caller shape-kind)
  (cond
   ((equal? shape-kind "pattern-branch-with-manual-loop")
    (string-append "caller " caller
                   " combines match state destructuring with a named-let loop; keep the repair policy-driven, split the selector/update step or use a bounded pipeline before editing for style or performance"))
   (else
    (string-append "caller " caller
                   " has repeated match branches; keep the repair policy-driven, split nested branch logic into named helpers or a bounded selector pipeline before editing for style or performance"))))

;;; Earliest selector reducer:
;;; - The first source span is the least surprising repair anchor for an agent.
;;; - The fold preserves the full grouped evidence for details.
;; ControlFlowFact <- (NonEmptyList ControlFlowFact)
(def (earliest-control-flow-fact facts)
  (foldl (lambda (fact earliest)
           (if (< (control-flow-fact-start fact)
                  (control-flow-fact-start earliest))
             fact
             earliest))
         (car facts)
         (cdr facts)))
