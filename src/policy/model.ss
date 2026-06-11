;;; -*- Gerbil -*-
;;; Native policy rule model.

(export make-policy-rule
        policy-rule-id
        policy-rule-severity
        +modularity-facade-rule+
        +agent-intent-rule+)

(defstruct policy-rule (id severity))

(def +modularity-facade-rule+
  (make-policy-rule "GERBIL-SCHEME-MOD-R001" "warning"))

(def +agent-intent-rule+
  (make-policy-rule "GERBIL-SCHEME-AGENT-R001" "warning"))
