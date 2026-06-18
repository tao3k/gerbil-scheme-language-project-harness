;;; -*- Gerbil -*-
;;; Forbidden form checks over parser-owned top-level forms.

(import :checker/model
        :parser/facade
        (only-in :std/srfi/13 string-contains string-prefix? string-trim)
        (only-in :std/sugar filter-map)
        :types/findings)

(export +macro-governance-form-heads+
        +forbidden-form-heads+
        +macro-governance-policy-explanation-min-length+
        +macro-governance-policy-witness-min-length+
        run-macro-governance-checks
        macro-governance-finding
        run-forbidden-form-checks
        forbidden-form-finding)
;; ConfigConstant
(def +macro-governance-form-heads+
  '("define-syntax" "syntax-case" "defsyntax" "defrules"))
;; String
(def +forbidden-form-heads+ +macro-governance-form-heads+)
;; Integer
(def +macro-governance-policy-explanation-min-length+ 32)
;; Integer
(def +macro-governance-policy-witness-min-length+ 8)
;; run-macro-governance-checks
;;   : (-> ProjectIndex (List TypeFinding))
;;   | doc m%
;;       `run-macro-governance-checks index` reports constrained-source macro
;;       forms when package policy has not supplied the required governance
;;       explanation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-macro-governance-checks index)
;;       ;; => macro governance findings
;;       ```
;;     %
(def (run-macro-governance-checks index)
  (filter-map
   (lambda (form)
     (and (macro-governance-form? form)
          (macro-governance-constrained-source? form)
          (not (macro-governance-policy-allows? index))
          (macro-governance-finding index form)))
   (apply append (map source-file-forms (project-index-files index)))))
;; : (-> ProjectIndex String )
(def (run-forbidden-form-checks index)
  (run-macro-governance-checks index))
;; : (-> Form Boolean )
(def (macro-governance-form? form)
  (member (top-form-head form) +macro-governance-form-heads+))
;; : (-> Form Boolean )
(def (macro-governance-constrained-source? form)
  (or (generated-source-path? (top-form-path form))
      (agent-generated-source-path? (top-form-path form))))
;; : (-> String Boolean )
(def (generated-source-path? path)
  (or (string-prefix? "generated/" path)
      (string-contains path "/generated/")))
;; : (-> String Boolean )
(def (agent-generated-source-path? path)
  (or (string-prefix? "agent-generated/" path)
      (string-contains path "/agent-generated/")))
;; : (-> ProjectIndex Boolean )
(def (macro-governance-policy-allows? index)
  (let (policy (project-macro-governance-policy index))
    (and policy
         (macro-governance-policy-allow-generated policy)
         (macro-governance-policy-explanation-clear? policy)
         (macro-governance-policy-witness-clear? policy))))
;; : (-> Policy Boolean )
(def (macro-governance-policy-explanation-clear? policy)
  (and (macro-governance-policy-explanation policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-explanation policy)))
             +macro-governance-policy-explanation-min-length+)))
;; : (-> Policy Boolean )
(def (macro-governance-policy-witness-clear? policy)
  (and (macro-governance-policy-witness policy)
       (fx>= (string-length
              (string-trim (macro-governance-policy-witness policy)))
             +macro-governance-policy-witness-min-length+)))
;; : (-> ProjectIndex ProjectMacroGovernancePolicy )
(def (project-macro-governance-policy index)
  (and (project-index-package index)
       (project-package-macro-governance-policy (project-index-package index))))
;; : (-> Form String )
(def (macro-governance-source-kind form)
  (cond
   ((generated-source-path? (top-form-path form)) "generated-code")
   ((agent-generated-source-path? (top-form-path form)) "agent-generated-code")
   (else "harness-source")))
;;; Boundary:
;;; - macro-governance-finding coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> ProjectIndex Form TypeFinding )
(def (macro-governance-finding index form)
  (let ((head (top-form-head form))
        (selector (top-form-selector form))
        (policy (and index (project-macro-governance-policy index))))
    (make-type-finding
     (checker-rule-id +macro-governance-rule+)
     (checker-rule-severity +macro-governance-rule+)
     (top-form-path form)
     (string-append "macro form " head
                    " in "
                    (macro-governance-source-kind form)
                    " requires POO macro-governance policy with clear user explanation and witness")
     selector
     (hash (form head)
           (selector selector)
           (sourceKind (macro-governance-source-kind form))
           (policyProtocol "poo/macro-governance")
           (requiredWitness "macro-expansion-test-or-user-policy-explanation")
           (policyExplanation
            (and policy (macro-governance-policy-explanation policy)))
           (policyWitness
            (and policy (macro-governance-policy-witness policy)))
           (policyExplanationMinimumChars
            +macro-governance-policy-explanation-min-length+)
           (policyWitnessMinimumChars
            +macro-governance-policy-witness-min-length+)))))
;; : (-> Form String )
(def (forbidden-form-finding form)
  (macro-governance-finding #f form))
