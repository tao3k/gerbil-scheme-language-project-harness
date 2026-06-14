;;; -*- Gerbil -*-
;;; Parser-owned package metadata facts.

(import :gerbil/gambit
        :std/srfi/13)

(export read-project-package
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        project-package-macro-governance-policy
        project-package-source-scope-policy
        project-package-agent-policy
        test-directory-policy-allowed-directories
        test-directory-policy-explanation
        macro-governance-policy-allow-generated
        macro-governance-policy-explanation
        macro-governance-policy-witness
        source-scope-policy-roots
        source-scope-policy-runtime-roots
        source-scope-policy-exclude-directories
        source-scope-policy-explanation
        agent-policy-enabled-rules
        agent-policy-disabled-rules)
;; TestDirectoryPolicyStruct
(defstruct test-directory-policy (allowed-directories explanation))
;; MacroGovernancePolicyStruct
(defstruct macro-governance-policy (allow-generated explanation witness))
;; SourceScopePolicyStruct
(defstruct source-scope-policy (roots runtime-roots exclude-directories explanation))
;; AgentPolicyStruct
(defstruct agent-policy (enabled-rules disabled-rules))
;; ProjectPackageStruct
(defstruct project-package (path name dependencies manager test-directory-policy macro-governance-policy source-scope-policy agent-policy))
;;; Boundary:
;;; - read-project-package coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; ParsedData <- String
(def (read-project-package root)
  (let* ((package-form (read-package-form root))
         (build-scope (read-build-source-scope-policy root)))
    (cond
     (package-form
      (make-project-package "gerbil.pkg"
                            (datum->string (safe-cadr package-form))
                            (package-dependencies package-form)
                            "gxpkg"
                            (package-test-directory-policy package-form)
                            (package-macro-governance-policy package-form)
                            (or (package-source-scope-policy package-form)
                                build-scope)
                            (package-agent-policy package-form)))
     (build-scope
      (make-project-package "build.ss"
                            #f
                            '()
                            "gxpkg"
                            #f
                            #f
                            build-scope
                            #f))
     (else #f))))
;;; Boundary:
;;; - read-package-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ParsedData <- String
(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))
;;; Boundary:
;;; - read-build-source-scope-policy composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- String
(def (read-build-source-scope-policy root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "build.ss" root))
            (forms (read-package-forms path))
            (targets (build-script-targets forms))
            (runtime-roots (build-target-source-roots targets)))
       (and (pair? runtime-roots)
            (make-source-scope-policy
             '()
             runtime-roots
             '()
             "Inferred from build.ss defbuild-script targets."))))))
;;; Boundary:
;;; - read-package-forms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- String
(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (next (read port))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))
;; Boolean <- Datum
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))
;;; Boundary:
;;; - package-dependencies is a field lookup plus dependency string projection.
;;; - Reuse package-field-value so package metadata traversal has one owner.
;; Integer <- Datum
(def (package-dependencies datum)
  (let (deps (package-field-value datum 'depend:))
    (if deps
      (dedupe (filter-map datum->string (datum-list-items deps)))
      '())))
;; PackageTestDirectoryPolicy <- Datum
(def (package-test-directory-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-test-directory-entry policy))
           (and entry
                (make-test-directory-policy
                 (policy-directory-list entry)
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-test-directory-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PolicyTestDirectoryEntry <- Policy
(def (policy-test-directory-entry policy)
  (if (test-directory-policy-form? policy)
    policy
    (find test-directory-policy-form? (datum-list-items policy))))
;; Boolean <- Datum
(def (test-directory-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(test-directory-layout test-directory-policy))))
;; PackageMacroGovernancePolicy <- Datum
(def (package-macro-governance-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-macro-governance-entry policy))
           (and entry
                (make-macro-governance-policy
                 (policy-boolean-field entry 'allow-generated:)
                 (policy-string-field entry 'explanation:)
                 (policy-string-field entry 'witness:)))))))
;;; Boundary:
;;; - policy-macro-governance-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PolicyMacroGovernanceEntry <- Policy
(def (policy-macro-governance-entry policy)
  (if (macro-governance-policy-form? policy)
    policy
    (find macro-governance-policy-form? (datum-list-items policy))))
;; Boolean <- Datum
(def (macro-governance-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(macro-governance macro-policy))))
;; String <- Datum
(def (package-source-scope-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-source-scope-entry policy))
           (and entry
                (make-source-scope-policy
                 (or (policy-string-list-field entry 'roots:)
                     (policy-string-list-field entry 'source-roots:)
                     (policy-string-list-field entry 'source-root:)
                     '())
                 (or (policy-string-list-field entry 'runtime-roots:)
                     (policy-string-list-field entry 'runtime-root:)
                     '())
                 (or (policy-string-list-field entry 'exclude-directories:)
                     (policy-string-list-field entry 'excluded-directories:)
                     (policy-string-list-field entry 'ignore-directories:)
                     '())
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-source-scope-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Policy
(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))
;; Boolean <- Datum
(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-scope))))
;;; Boundary:
;;; Package forms have at most one build script declaration for harness scope.
;;; The find combinator makes that single-owner lookup explicit and leaves the
;;; target value decoder responsible for quoted/list/string normalization.
;; BuildScriptTargets <- (List String)
(def (build-script-targets forms)
  (let (form (find build-script-form? forms))
    (if form
      (build-script-target-value (safe-cadr form))
      '())))
;; Boolean <- Datum
(def (build-script-form? datum)
  (and (pair? datum) (eq? (car datum) 'defbuild-script)))
;;; Boundary:
;;; - build-script-target-value composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; BuildScriptTargetValue <- Datum
(def (build-script-target-value datum)
  (cond
   ((not datum) '())
   ((quoted-datum? datum) (build-script-target-value (safe-cadr datum)))
   ((or (string? datum) (symbol? datum)) [(datum->string datum)])
   (else (filter-map datum->string (datum-list-items datum)))))
;; Boolean <- Datum
(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))
;;; Boundary:
;;; - build-target-source-roots composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- Targets
(def (build-target-source-roots targets)
  (dedupe-strings
   (filter-map build-target-source-root targets)))
;; BuildTargetSourceRoot <- Target
(def (build-target-source-root target)
  (let (slash (and target (string-index target #\/)))
    (cond
     ((not target) #f)
     ((not slash) ".")
     ((fx= slash 0) ".")
     (else (substring target 0 slash)))))
;; PackageAgentPolicy <- Datum
(def (package-agent-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-agent-entry policy))
           (and entry
                (make-agent-policy
                 (or (policy-string-list-field entry 'enabled-rules:)
                     (policy-string-list-field entry 'enable:)
                     '())
                 (or (policy-string-list-field entry 'disabled-rules:)
                     (policy-string-list-field entry 'disable:)
                     '())))))))
;;; Boundary:
;;; - policy-agent-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; PolicyAgentEntry <- Policy
(def (policy-agent-entry policy)
  (if (agent-policy-form? policy)
    policy
    (find agent-policy-form? (datum-list-items policy))))
;; Boolean <- Datum
(def (agent-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(agent-policy policy-rules))))
;; PolicyDirectoryList <- Datum
(def (policy-directory-list datum)
  (or (policy-string-list-field datum 'allowed-directories:)
      (policy-string-list-field datum 'allow-directories:)
      (policy-string-list-field datum 'allow:)
      '()))
;;; Boundary:
;;; - policy-string-list-field composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Datum String
(def (policy-string-list-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((not value) #f)
     ((or (string? value) (symbol? value)) [(datum->string value)])
     (else (dedupe (filter-map datum->string (datum-list-items value)))))))
;; String <- Datum String
(def (policy-string-field datum field)
  (let (value (package-field-value datum field))
    (and value (datum->string value))))
;; PolicyBooleanField <- Datum String
(def (policy-boolean-field datum field)
  (let (value (package-field-value datum field))
    (truthy-policy-value? value)))
;; Boolean <- PolicyValue
(def (truthy-policy-value? value)
  (if (or (eq? value #t)
          (member (datum->string value) '("true" "yes" "allow" "allowed")))
    #t
    #f))
;;; Invariant:
;;; - package-field-value owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; PackageFieldValue <- Datum String
(def (package-field-value datum field)
  (let (tail (member field (datum-list-items datum)))
    (and tail
         (pair? (cdr tail))
         (cadr tail))))
;;; Invariant:
;;; - datum-list-items owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- Obj
(def (datum-list-items obj)
  (let ((rest obj)
        (out '()))
    (while (pair? rest)
      (set! out (cons (car rest) out))
      (set! rest (cdr rest)))
    (reverse out)))
;; SafeCadr <- Obj
(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))
;;; Boundary:
;;; - datum->string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Obj
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))
;;; Invariant:
;;; - dedupe owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Dedupe <- (List XX)
(def (dedupe items)
  (let (state
        (foldl (lambda (item state)
                 (let ((seen (car state))
                       (out (cdr state)))
                   (if (member item seen)
                     state
                     (cons (cons item seen) (cons item out)))))
               (cons '() '())
               items))
    (reverse (cdr state))))
;;; Invariant:
;;; - dedupe-strings owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List String) <- (List String)
(def (dedupe-strings items)
  (let (state
        (foldl (lambda (item state)
                 (let ((seen (car state))
                       (out (cdr state)))
                   (if (string-list-member? item seen)
                     state
                     (cons (cons item seen) (cons item out)))))
               (cons '() '())
               items))
    (reverse (cdr state))))
;;; Boundary:
;;; - string-list-member? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- Item (List XX)
(def (string-list-member? item items)
  (find (lambda (candidate) (string=? item candidate)) items))
