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
        +type-mismatch-rule+
        +whitelist-rule+
        +macro-governance-rule+
        +forbidden-form-rule+)
;; CheckerRuleStruct
(defstruct checker-rule (id severity))
;; CheckerEvidenceStruct
(defstruct checker-evidence (callee expected actual selector signature))
;; Integer
(def +arity-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-A001" "error"))
;; TypeSpec
(def +type-mismatch-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-T001" "error"))
;; ConfigConstant
(def +whitelist-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-W001" "error"))
;; ConfigConstant
(def +macro-governance-rule+
  (make-checker-rule "GERBIL-SCHEME-CHECKER-W002" "error"))
;; String
(def +forbidden-form-rule+ +macro-governance-rule+)
