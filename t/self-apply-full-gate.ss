;;; -*- Gerbil -*-
;;; Explicit slow self-apply policy gate for this harness.

(import :std/test
        :parser/facade
        :snapshot/facade
        :std/sugar
        :types/facade)
(export self-apply-full-test)

;; ConfigConstant
(def +self-apply-finding-budgets+
  '())
;; SelfApplyIndexCache
(def +self-apply-index-cache+ #f)
;; SelfApplyFindingsCache
(def +self-apply-findings-cache+ #f)
;; : (-> ProjectIndex )
(def (self-apply-index)
  (or +self-apply-index-cache+
      (let (index (collect-project "."))
        (set! +self-apply-index-cache+ index)
        index)))
;; : (-> (List TypeFinding) )
(def (self-apply-findings)
  (or +self-apply-findings-cache+
      (let (findings (run-type-checks (self-apply-index)))
        (set! +self-apply-findings-cache+ findings)
        findings)))
;; : (-> (List XX) SelfApplyDebtViolations )
(def (self-apply-debt-violations findings)
  (let (counts (finding-rule-counts findings))
    (append (unexpected-self-apply-rule-violations counts)
            (over-budget-self-apply-rule-violations counts))))
;; : (-> (List TypeFinding) Integer )
(def (finding-rule-counts findings)
  (foldl (lambda (finding counts)
           (increment-rule-count counts (type-finding-rule-id finding)))
         '()
         findings))
;; : (-> Counts RuleId Integer )
(def (increment-rule-count counts rule-id)
  (cond
   ((null? counts) (list (list rule-id 1)))
   ((equal? rule-id (rule-count-rule (car counts)))
    (cons (list rule-id (+ 1 (rule-count-count (car counts))))
          (cdr counts)))
   (else
    (cons (car counts)
          (increment-rule-count (cdr counts) rule-id)))))
;; : (-> Entry Integer )
(def (rule-count-rule entry)
  (car entry))
;; : (-> Entry Integer )
(def (rule-count-count entry)
  (cadr entry))
;; : (-> Counts UnexpectedSelfApplyRuleViolations )
(def (unexpected-self-apply-rule-violations counts)
  (filter-map
   (lambda (entry)
     (let (rule-id (rule-count-rule entry))
       (and (not (self-apply-budget-limit rule-id))
            (list 'unexpectedRule rule-id (rule-count-count entry)))))
   counts))
;; : (-> Counts OverBudgetSelfApplyRuleViolations )
(def (over-budget-self-apply-rule-violations counts)
  (filter-map
   (lambda (entry)
     (let* ((rule-id (rule-count-rule entry))
            (count (rule-count-count entry))
            (limit (self-apply-budget-limit rule-id)))
       (and limit
            (> count limit)
            (list 'overBudget rule-id count limit))))
   counts))
;; : (-> RuleId Integer )
(def (self-apply-budget-limit rule-id)
  (self-apply-budget-limit* rule-id +self-apply-finding-budgets+))
;; : (-> RuleId Budgets Integer )
(def (self-apply-budget-limit* rule-id budgets)
  (cond
   ((null? budgets) #f)
   ((equal? rule-id (car (car budgets))) (cadr (car budgets)))
   (else (self-apply-budget-limit* rule-id (cdr budgets)))))
;; : (-> (List TypeFinding) Boolean )
(def (self-apply-debt-clear? findings)
  (let (violations (self-apply-debt-violations findings))
    (check violations => '())
    (null? violations)))

;; SelfApplyFullTest
(def self-apply-full-test
  (test-suite "gerbil scheme harness full self apply"
    (test-case "current harness findings match snapshot and debt budgets"
      (let* ((findings (self-apply-findings))
             (debt-clear? (self-apply-debt-clear? findings)))
        (when debt-clear?
          (let ((snapshot (self-apply-findings-snapshot findings))
                (expected (snapshot-load "t/snapshots/self-apply-findings.ss")))
            (check snapshot => expected)))))
    (test-case "current harness check report matches snapshot"
      (let* ((index (self-apply-index))
             (findings (self-apply-findings))
             (debt-clear? (null? (self-apply-debt-violations findings))))
        (when debt-clear?
          (let ((snapshot (check-report-snapshot index findings))
                (expected (snapshot-load "t/snapshots/self-apply-check-report.ss")))
            (check snapshot => expected)))))))
