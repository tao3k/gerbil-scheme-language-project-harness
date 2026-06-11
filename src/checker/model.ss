;;; -*- Gerbil -*-
;;; Native checker rule and evidence model.

(export make-checker-rule
        checker-rule-id
        checker-rule-severity
        make-checker-evidence
        checker-evidence-callee
        checker-evidence-expected
        checker-evidence-actual
        checker-evidence-selector
        checker-evidence-signature
        +arity-rule+
        +whitelist-rule+
        +forbidden-form-rule+)

(defstruct checker-rule (id severity))
(defstruct checker-evidence (callee expected actual selector signature))

(def +arity-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-A001" "error"))

(def +whitelist-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-W001" "error"))

(def +forbidden-form-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-W002" "error"))
