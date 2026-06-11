;;; -*- Gerbil -*-
;;; Type mismatch checks over parser-owned calls and native type environments.

(import :std/srfi/13
        :checker/model
        :parser/facade
        :types/env
        :types/findings
        :types/model
        :types/signatures)

(export run-type-mismatch-checks
        call-type-mismatch-findings)

(def (run-type-mismatch-checks index signatures)
  (let (param-env (build-param-type-env/signatures index signatures))
    (append-map (cut call-type-mismatch-findings <> signatures param-env)
                (project-calls index))))

(def (call-type-mismatch-findings call signatures param-env)
  (let (signature (signature-type-for (call-fact-callee call) signatures))
    (if (and signature (eq? (type-kind signature) 'function))
      (call-function-type-mismatch-findings call signature param-env)
      '())))

(def (call-function-type-mismatch-findings call signature param-env)
  (let ((expected-types (type-params signature))
        (arg-names (call-fact-arguments call))
        (arg-type-names (call-fact-argument-types call)))
    (if (fx= (length expected-types) (call-fact-arity call))
      (argument-type-findings call expected-types arg-names arg-type-names param-env 0 '())
      '())))

(def (argument-type-findings call expected-types arg-names arg-type-names param-env index out)
  (cond
   ((or (null? expected-types) (null? arg-names)) (reverse out))
   (else
    (let* ((arg-name (car arg-names))
           (arg-type-name (and (pair? arg-type-names) (car arg-type-names)))
           (expected-type (car expected-types))
           (actual-type (argument-type call arg-name arg-type-name param-env))
           (finding (and actual-type
                         (not (type-compatible? actual-type expected-type))
                         (type-mismatch-finding call arg-name index expected-type actual-type))))
      (argument-type-findings call
                              (cdr expected-types)
                              (cdr arg-names)
                              (if (pair? arg-type-names) (cdr arg-type-names) '())
                              param-env
                              (fx1+ index)
                              (if finding (cons finding out) out))))))

(def (argument-type call arg-name arg-type-name param-env)
  (or (argument-param-type call arg-name param-env)
      (literal-argument-type arg-type-name)))

(def (argument-param-type call arg-name param-env)
  (and (call-fact-caller call)
       (valid-argument-name? arg-name)
       (let (binding (find-param-binding (call-fact-caller call) arg-name param-env))
         (and binding (type-param-binding-type binding)))))

(def (literal-argument-type arg-type-name)
  (and arg-type-name (make-type-base arg-type-name)))

(def (find-param-binding function-name arg-name param-env)
  (find (lambda (binding)
          (and (equal? (type-param-binding-function-name binding) function-name)
               (equal? (type-param-binding-name binding) arg-name)))
        param-env))

(def (valid-argument-name? arg-name)
  (and arg-name (not (string-contains arg-name " "))))

(def (type-compatible? actual expected)
  (or (member (type-kind actual) '(unknown any))
      (member (type-kind expected) '(unknown any))
      (type=? actual expected)
      (and (eq? (type-kind expected) 'union)
           (any-type-compatible? actual (type-union-members expected)))))

(def (any-type-compatible? actual expected-members)
  (cond
   ((null? expected-members) #f)
   ((type-compatible? actual (car expected-members)) #t)
   (else (any-type-compatible? actual (cdr expected-members)))))

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

(def (append-map fn items)
  (let lp ((rest items) (out '()))
    (match rest
      ([] (reverse out))
      ([item . more]
       (lp more (append-reverse (fn item) out))))))

(def (append-reverse items out)
  (let lp ((rest items) (acc out))
    (match rest
      ([] acc)
      ([item . more] (lp more (cons item acc))))))
