;;; -*- Gerbil -*-
;;; Type mismatch checks over parser-owned calls and native type environments.

(import (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar append-map cut filter-map find iota)
        :checker/model
        :parser/facade
        :types/env
        :types/findings
        :types/model
        :types/signatures)

(export run-type-mismatch-checks
        call-type-mismatch-findings)

;; ArgumentTypeSlot
(defstruct argument-type-slot (name expected type-name index))

;;; Boundary:
;;; - run-type-mismatch-checks composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex NativeSignatures
(def (run-type-mismatch-checks index signatures)
  (let (param-env (build-param-type-env/signatures index signatures))
    (append-map (cut call-type-mismatch-findings <> signatures param-env)
                (project-calls index))))
;; (List TypeFinding) <- CallFact NativeSignatures ParamEnv
(def (call-type-mismatch-findings call signatures param-env)
  (let (signature (signature-type-for (call-fact-callee call) signatures))
    (if (and signature (eq? (type-kind signature) 'function))
      (call-function-type-mismatch-findings call signature param-env)
      '())))
;; (List TypeFinding) <- CallFact NativeSignatures ParamEnv
(def (call-function-type-mismatch-findings call signature param-env)
  (let ((expected-types (type-params signature))
        (arg-names (call-fact-arguments call))
        (arg-type-names (call-fact-argument-types call)))
    (if (fx= (length expected-types) (call-fact-arity call))
      (argument-type-findings call expected-types arg-names arg-type-names param-env)
      '())))

;;; Boundary:
;;; - argument-type-findings composes first-class procedures over indexed slots.
;;; - Slot construction owns list alignment.
;;; - Finding construction owns type compatibility checks.
;;; - Keep the call fact intact so selector and caller evidence stay parser-owned.
;; (List TypeFinding) <- CallFact ExpectedTypes ArgNames ArgTypeNames ParamEnv
(def (argument-type-findings call expected-types arg-names arg-type-names param-env)
  (filter-map (cut argument-type-slot-finding call param-env <>)
              (argument-type-slots expected-types arg-names arg-type-names)))

;;; Alignment boundary:
;;; - Expected types drive the slot count.
;;; - Missing parser arg-type facts become empty slots, not shifted positions.
;; (List ArgumentTypeSlot) <- ExpectedTypes ArgNames ArgTypeNames
(def (argument-type-slots expected-types arg-names arg-type-names)
  (map (lambda (arg-name expected-type index)
         (make-argument-type-slot
          arg-name
          expected-type
          (argument-type-name-at arg-type-names index)
          index))
       arg-names
       expected-types
       (iota (length expected-types))))

;; MaybeArgTypeName <- ArgTypeNames Index
(def (argument-type-name-at arg-type-names index)
  (and (< index (length arg-type-names))
       (list-ref arg-type-names index)))

;; MaybeTypeFinding <- CallFact ParamEnv ArgumentTypeSlot
(def (argument-type-slot-finding call param-env slot)
  (let (actual-type
        (argument-type call
                       (argument-type-slot-name slot)
                       (argument-type-slot-type-name slot)
                       param-env))
    (and actual-type
         (not (type-compatible? actual-type
                                (argument-type-slot-expected slot)))
         (type-mismatch-finding call
                                (argument-type-slot-name slot)
                                (argument-type-slot-index slot)
                                (argument-type-slot-expected slot)
                                actual-type))))

;; TypeSpec <- CallFact ArgName ArgTypeName ParamEnv
(def (argument-type call arg-name arg-type-name param-env)
  (or (argument-param-type call arg-name param-env)
      (literal-argument-type arg-type-name)))
;; TypeSpec <- CallFact ArgName ParamEnv
(def (argument-param-type call arg-name param-env)
  (and (call-fact-caller call)
       (valid-argument-name? arg-name)
       (let (binding (find-param-binding (call-fact-caller call) arg-name param-env))
         (and binding (type-param-binding-type binding)))))
;; TypeSpec <- ArgTypeName
(def (literal-argument-type arg-type-name)
  (and arg-type-name (make-type-base arg-type-name)))
;;; Boundary:
;;; - find-param-binding composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; FindParamBinding <- FunctionName ArgName ParamEnv
(def (find-param-binding function-name arg-name param-env)
  (find (lambda (binding)
          (and (equal? (type-param-binding-function-name binding) function-name)
               (equal? (type-param-binding-name binding) arg-name)))
        param-env))
;; Boolean <- ArgName
(def (valid-argument-name? arg-name)
  (and arg-name (not (string-contains arg-name " "))))
;; Boolean <- Actual Expected
(def (type-compatible? actual expected)
  (or (member (type-kind actual) '(unknown any))
      (member (type-kind expected) '(unknown any))
      (type=? actual expected)
      (and (eq? (type-kind expected) 'union)
           (any-type-compatible? actual (type-union-members expected)))))
;; Boolean <- Actual ExpectedMembers
(def (any-type-compatible? actual expected-members)
  (cond
   ((null? expected-members) #f)
   ((type-compatible? actual (car expected-members)) #t)
   (else (any-type-compatible? actual (cdr expected-members)))))
;; TypeFinding <- CallFact ArgName ProjectIndex Expected Actual
(def (type-mismatch-finding call arg-name index expected actual)
  (make-type-finding
   (checker-rule-id +type-mismatch-rule+)
   (checker-rule-severity +type-mismatch-rule+)
   (call-fact-path call)
   (string-append "type mismatch for " (call-fact-callee call)
                  " argument " (number->string index)
                  ": expected " (type->string expected)
                  ", got " (type->string actual))
   (call-fact-selector call)
   (hash (callee (call-fact-callee call))
         (caller (call-fact-caller call))
         (argument arg-name)
         (argumentIndex index)
         (expectedType (type->string expected))
         (actualType (type->string actual)))))
;;; Invariant:
;;; - append-map owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- (YY <- XX) (List XX)
(def (append-map fn items)
  (foldr (lambda (item out) (append (fn item) out)) '() items))
