;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :commands/bench
        :parser/facade
        :snapshot/facade
        :std/misc/ports
        :std/sugar
        (only-in :std/text/json read-json)
        :types/facade)
(export self-apply-test)
;; ConfigConstant
(def +self-apply-finding-budgets+
  '())
;; SelfApplyDebtViolations <- (List XX)
(def (self-apply-debt-violations findings)
  (let (counts (finding-rule-counts findings))
    (append (unexpected-self-apply-rule-violations counts)
            (over-budget-self-apply-rule-violations counts))))
;; Integer <- (List TypeFinding)
(def (finding-rule-counts findings)
  (foldl (lambda (finding counts)
           (increment-rule-count counts (type-finding-rule-id finding)))
         '()
         findings))
;; Integer <- Counts RuleId
(def (increment-rule-count counts rule-id)
  (cond
   ((null? counts) (list (list rule-id 1)))
   ((equal? rule-id (rule-count-rule (car counts)))
    (cons (list rule-id (+ 1 (rule-count-count (car counts))))
          (cdr counts)))
   (else
    (cons (car counts)
          (increment-rule-count (cdr counts) rule-id)))))
;; Integer <- Entry
(def (rule-count-rule entry)
  (car entry))
;; Integer <- Entry
(def (rule-count-count entry)
  (cadr entry))
;; UnexpectedSelfApplyRuleViolations <- Counts
(def (unexpected-self-apply-rule-violations counts)
  (filter-map
   (lambda (entry)
     (let (rule-id (rule-count-rule entry))
       (and (not (self-apply-budget-limit rule-id))
            (list 'unexpectedRule rule-id (rule-count-count entry)))))
   counts))
;; OverBudgetSelfApplyRuleViolations <- Counts
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
;; Integer <- RuleId
(def (self-apply-budget-limit rule-id)
  (self-apply-budget-limit* rule-id +self-apply-finding-budgets+))
;; Integer <- RuleId Budgets
(def (self-apply-budget-limit* rule-id budgets)
  (cond
   ((null? budgets) #f)
   ((equal? rule-id (car (car budgets))) (cadr (car budgets)))
   (else (self-apply-budget-limit* rule-id (cdr budgets)))))
;; Json
(def (bench-json-packet)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status
                  (bench-main ["--json" "--iterations" "1" "--max-total-ms" "60000" "--max-interface-ms" "60000" "."])))))))
    (check status => 0)
    (call-with-input-string output read-json)))
;; SelfApplyTest
(def self-apply-test
  (test-suite "gerbil scheme harness self apply"
    (test-case "current harness findings match snapshot and debt budgets"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (self-apply-findings-snapshot findings))
             (expected (snapshot-load "t/snapshots/self-apply-findings.ss")))
        (check (self-apply-debt-violations findings) => '())
        (check snapshot => expected)))
    (test-case "current harness check report matches snapshot"
      (let* ((index (collect-project "."))
             (findings (run-type-checks index))
             (snapshot (check-report-snapshot index findings))
             (expected (snapshot-load "t/snapshots/self-apply-check-report.ss")))
        (check snapshot => expected)))
    (test-case "current harness bench report matches snapshot"
      (let* ((packet (bench-json-packet))
             (snapshot (bench-report-snapshot packet))
             (expected (snapshot-load "t/snapshots/self-apply-bench-report.ss")))
        (check snapshot => expected)))))
