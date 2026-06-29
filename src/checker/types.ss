;;; -*- Gerbil -*-
;;; Type mismatch checks over parser-owned calls and native type environments.

(import (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar cut filter-map find iota)
        :checker/model
        :parser/model
        (only-in :parser/selectors
                 call-fact-selector
                 project-calls)
        :types/env
        :types/findings
        :types/model
        :types/signatures
        (only-in :types/validation type-compatible?))

(export run-type-mismatch-checks
        call-type-mismatch-findings)

;; ArgumentTypeSlot
(defstruct argument-type-slot (name expected type-name index))

;; run-type-mismatch-checks
;;   : (-> ProjectIndex
;;         NativeSignatures
;;         (List TypeFinding))
;;   | doc m%
;;       `run-type-mismatch-checks index signatures` checks every parser-owned
;;       call fact against native signature and parameter type evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-type-mismatch-checks empty-index empty-signatures)
;;       ;; => ()
;;       ```
;;     %
(def (run-type-mismatch-checks index signatures)
  (let (param-env (build-param-type-env/signatures index signatures))
    (append-map (cut call-type-mismatch-findings <> signatures param-env)
                (project-calls index))))
;; call-type-mismatch-findings
;;   : (-> CallFact NativeSignatures ParamEnv (List TypeFinding) )
;;   | doc m%
;;       `call-type-mismatch-findings call signatures param-env` checks one
;;       parser-owned call fact against native function signatures and caller
;;       parameter type bindings.
;;
;;       # Examples
;;       ```scheme
;;       (call-type-mismatch-findings call [] [])
;;       ;; => ()
;;       ```
;;     %
(def (call-type-mismatch-findings call signatures param-env)
  (let (signature (signature-type-for (call-fact-callee call) signatures))
    (if (and signature (eq? (type-kind signature) 'function))
      (call-function-type-mismatch-findings call signature param-env)
      '())))
;; : (-> CallFact NativeSignatures ParamEnv (List TypeFinding) )
(def (call-function-type-mismatch-findings call signature param-env)
  (let ((expected-types (type-params signature))
        (arg-names (call-fact-arguments call))
        (arg-type-names (call-fact-argument-types call)))
    (if (fx= (length expected-types) (call-fact-arity call))
      (argument-type-findings call expected-types arg-names arg-type-names param-env)
      '())))

;; argument-type-findings
;;   : (-> CallFact
;;         ExpectedTypes
;;         ArgNames
;;         ArgTypeNames
;;         ParamEnv
;;         (List TypeFinding))
;;   | doc m%
;;       `argument-type-findings call expected-types arg-names arg-type-names param-env`
;;       aligns expected and actual argument slots, then returns mismatch
;;       findings for incompatible slots.
;;
;;       # Examples
;;
;;       ```scheme
;;       (argument-type-findings call [] [] [] [])
;;       ;; => ()
;;       ```
;;     %
(def (argument-type-findings call expected-types arg-names arg-type-names param-env)
  (filter-map (cut argument-type-slot-finding call param-env <>)
              (argument-type-slots expected-types arg-names arg-type-names)))

;;; Alignment boundary:
;;; - Expected types drive the slot count.
;;; - Missing parser arg-type facts become empty slots, not shifted positions.
;; : (-> ExpectedTypes ArgNames ArgTypeNames (List ArgumentTypeSlot) )
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

;; : (-> ArgTypeNames Index MaybeArgTypeName )
(def (argument-type-name-at arg-type-names index)
  (and (< index (length arg-type-names))
       (list-ref arg-type-names index)))

;; : (-> CallFact ParamEnv ArgumentTypeSlot MaybeTypeFinding )
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

;; : (-> CallFact ArgName ArgTypeName ParamEnv TypeSpec )
(def (argument-type call arg-name arg-type-name param-env)
  (or (argument-param-type call arg-name param-env)
      (literal-argument-type arg-type-name)))
;; : (-> CallFact ArgName ParamEnv TypeSpec )
(def (argument-param-type call arg-name param-env)
  (and (call-fact-caller call)
       (valid-argument-name? arg-name)
       (let (binding (find-param-binding (call-fact-caller call) arg-name param-env))
         (and binding (type-param-binding-type binding)))))
;; : (-> ArgTypeName TypeSpec )
(def (literal-argument-type arg-type-name)
  (and arg-type-name (make-type-base arg-type-name)))
;; find-param-binding
;;   : (-> FunctionName
;;         ArgName
;;         ParamEnv
;;         MaybeTypeParamBinding)
;;   | doc m%
;;       `find-param-binding function-name arg-name param-env` returns the
;;       parameter type binding for the caller argument when one is known.
;;
;;       # Examples
;;
;;       ```scheme
;;       (find-param-binding "order-total" "order" [])
;;       ;; => #f
;;       ```
;;     %
(def (find-param-binding function-name arg-name param-env)
  (find (lambda (binding)
          (and (equal? (type-param-binding-function-name binding) function-name)
               (equal? (type-param-binding-name binding) arg-name)))
        param-env))
;; : (-> ArgName Boolean )
(def (valid-argument-name? arg-name)
  (and arg-name (not (string-contains arg-name " "))))
;; : (-> CallFact ArgName ProjectIndex Expected Actual TypeFinding )
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
