;;; -*- Gerbil -*-
;;; Native policy rule model.

(export make-policy-rule
        policy-rule-id
        policy-rule-severity
        +modularity-facade-rule+
        +modularity-source-leaf-rule+
        +agent-intent-rule+
        +agent-generic-owner-rule+
        +agent-export-conflict-rule+)

(defstruct policy-rule (id severity))

(def +modularity-facade-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R001" "warning"))

(def +modularity-source-leaf-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R002" "warning"))

(def +agent-intent-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R001" "warning"))

(def +agent-generic-owner-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R002" "warning"))

(def +agent-export-conflict-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R003" "warning"))
