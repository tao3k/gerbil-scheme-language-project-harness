;;; -*- Gerbil -*-
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
        +agent-functional-idiom-advice-rule+)

(defstruct policy-rule (id severity))

(def +modularity-facade-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R001" "warning"))

(def +modularity-source-leaf-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R002" "warning"))

(def +modularity-owner-collision-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R003" "warning"))

(def +modularity-repeated-owner-entry-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R004" "warning"))

(def +modularity-bin-entrypoint-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R005" "warning"))

(def +modularity-test-directory-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R006" "warning"))

(def +agent-intent-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R001" "warning"))

(def +agent-generic-owner-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R002" "warning"))

(def +agent-export-conflict-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R003" "warning"))

(def +agent-vague-definition-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R004" "warning"))

(def +agent-top-level-executable-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R005" "warning"))

(def +agent-poo-direct-writeenv-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R006" "warning"))

(def +agent-poo-io-runtime-witness-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R007" "warning"))

(def +agent-poo-method-shape-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R008" "warning"))

(def +agent-functional-idiom-advice-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R009" "warning"))
