;;; -*- Gerbil -*-
;;; Agent-authored workflow helpers with nested conditional scaffolding.
(package: sample/dashboard)
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
  (let* ((owner-entry (assq 'owner dashboard))
         (state-entry (assq 'state dashboard))
         (ready-entry (assq 'ready dashboard))
         (retry-entry (assq 'retry dashboard)))
    (if owner-entry
      (if state-entry
        (if ready-entry
          (let ((owner (cdr owner-entry))
                (state (cdr state-entry))
                (ready? (cdr ready-entry))
                (retry? (and retry-entry (cdr retry-entry))))
            (if ready?
              (if (equal? state "ready")
                (if (equal? owner "agent") 'ready 'delegated)
                (if retry? 'retry 'blocked))
              'waiting))
          'missing-ready)
        'missing-state)
      'missing-owner)))

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
