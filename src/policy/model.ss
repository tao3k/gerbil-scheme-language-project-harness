;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Native policy rule model.

(export make-policy-rule
        policy-rule-id
        policy-rule-severity
        +modularity-facade-rule+
        +modularity-source-leaf-rule+
        +modularity-owner-collision-rule+
        +modularity-repeated-owner-entry-rule+
        +modularity-bin-entrypoint-rule+
        +modularity-test-directory-rule+
        +agent-intent-rule+
        +agent-generic-owner-rule+
        +agent-export-conflict-rule+
        +agent-vague-definition-rule+
        +agent-top-level-executable-rule+
        +agent-poo-direct-writeenv-rule+
        +agent-poo-io-runtime-witness-rule+
        +agent-poo-method-shape-rule+
        +agent-functional-idiom-advice-rule+
        +agent-poo-object-model-rule+
        +agent-macro-runtime-source-witness-rule+
        +agent-protocol-evidence-rule+
        +agent-typed-combinator-style-rule+
        +agent-controlled-branch-shape-rule+
        +agent-comment-quality-rule+)
;; PolicyRuleStruct
(defstruct policy-rule (id severity))
;; Integer
(def +modularity-facade-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R001" "warning"))
;; Integer
(def +modularity-source-leaf-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R002" "warning"))
;; Integer
(def +modularity-owner-collision-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R003" "warning"))
;; Integer
(def +modularity-repeated-owner-entry-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R004" "warning"))
;; Integer
(def +modularity-bin-entrypoint-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R005" "warning"))
;; Integer
(def +modularity-test-directory-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R006" "warning"))
;; ConfigConstant
(def +agent-intent-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R001" "warning"))
;; ConfigConstant
(def +agent-generic-owner-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R002" "warning"))
;; ConfigConstant
(def +agent-export-conflict-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R003" "warning"))
;; ConfigConstant
(def +agent-vague-definition-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R004" "warning"))
;; ConfigConstant
(def +agent-top-level-executable-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R005" "warning"))
;; ConfigConstant
(def +agent-poo-direct-writeenv-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R006" "warning"))
;; ConfigConstant
(def +agent-poo-io-runtime-witness-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R007" "warning"))
;; ConfigConstant
(def +agent-poo-method-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R008" "warning"))
;; String
(def +agent-functional-idiom-advice-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R009" "warning"))
;; ConfigConstant
(def +agent-poo-object-model-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R010" "warning"))
;; ConfigConstant
(def +agent-macro-runtime-source-witness-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R011" "warning"))
;; String
(def +agent-protocol-evidence-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R012" "warning"))
;; TypeSpec
(def +agent-typed-combinator-style-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R013" "warning"))
;; ConfigConstant
(def +agent-controlled-branch-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R014" "warning"))
;; ConfigConstant
(def +agent-comment-quality-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R015" "warning"))
