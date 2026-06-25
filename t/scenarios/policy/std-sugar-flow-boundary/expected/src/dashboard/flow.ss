;;; -*- Gerbil -*-
;;; Boundary:
;;; - Required workflow fields use `if-let` as the early-failure boundary.
;;; - The status projection stays linear with `chain`.
;;; - Resource-scoped output flow stays explicit and is not rewritten into
;;;   expression sugar.
(package: sample/dashboard)
(import (only-in :std/sugar chain if-let))
(export workflow-status
        workflow-audit-status)

;; workflow-status
;;   : (-> Dashboard WorkflowDecision)
;;   | type Dashboard = HashTable
;;   | type WorkflowDecision = Symbol
;;   | doc m%
;;       `workflow-status dashboard` projects the dashboard workflow state.
;;     %
(def (workflow-status dashboard)
  (if-let ((owner-entry (assq 'owner dashboard))
           (state-entry (assq 'state dashboard))
           (ready-entry (assq 'ready dashboard)))
    (chain (cdr state-entry)
      (state (and (cdr ready-entry) state))
      (state (cond
              ((not state) 'waiting)
              ((equal? (cdr owner-entry) "agent") 'ready)
              ((assq 'retry dashboard) 'retry)
              ((equal? state "ready") 'delegated)
              (else 'blocked))))
    'missing-workflow-field))

;; workflow-audit-status
;;   : (-> Dashboard PathString WorkflowDecision)
;;   | type Dashboard = HashTable
;;   | type PathString = String
;;   | type WorkflowDecision = Symbol
;;   | doc m%
;;       `workflow-audit-status dashboard audit-path` records the workflow
;;       decision as part of an output-resource boundary.
;;     %
(def (workflow-audit-status dashboard audit-path)
  (let* ((owner-entry (assq 'owner dashboard))
         (event-entry (assq 'event dashboard)))
    (if owner-entry
      (call-with-output-file audit-path
        (lambda (out)
          (if event-entry
            (begin
              (display (cdr event-entry) out)
              (if (equal? (cdr owner-entry) "agent")
                'recorded
                'delegated))
            'missing-event)))
      'missing-owner)))
