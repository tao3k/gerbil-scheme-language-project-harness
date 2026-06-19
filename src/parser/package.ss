;;; -*- Gerbil -*-
;;; Parser-owned package metadata facts.

(import :gerbil/gambit
        (only-in :parser/support datum-list-items safe-cadr)
        (only-in :std/misc/list unique)
        (only-in :std/srfi/13 string-index))

(export read-project-package
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        project-package-macro-governance-policy
        project-package-source-scope-policy
        project-package-modularity-policy
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
        modularity-policy-disabled
        modularity-policy-enabled-rules
        modularity-policy-disabled-rules
        modularity-policy-max-source-line-count
        modularity-policy-max-test-line-count
        modularity-policy-min-source-definition-count
        modularity-policy-min-test-definition-count
        modularity-policy-max-test-case-count
        modularity-policy-max-test-definition-span
        modularity-policy-config-path
        modularity-policy-explanation
        agent-policy-disabled-rules
        agent-policy-explanation
        read-package-forms
        package-form?
        package-dependencies
        package-test-directory-policy
        package-macro-governance-policy
        package-source-scope-policy
        package-modularity-policy
        package-agent-policy)
;; TestDirectoryPolicyStruct
(defstruct test-directory-policy (allowed-directories explanation))
;; MacroGovernancePolicyStruct
(defstruct macro-governance-policy (allow-generated explanation witness))
;; SourceScopePolicyStruct
(defstruct source-scope-policy (roots runtime-roots exclude-directories explanation))
;; ModularityPolicyStruct
(defstruct modularity-policy
  (disabled enabled-rules disabled-rules max-source-line-count max-test-line-count min-source-definition-count min-test-definition-count max-test-case-count max-test-definition-span config-path explanation))
;; AgentPolicyStruct
(defstruct agent-policy (disabled-rules explanation))
;; ProjectPackageStruct
(defstruct project-package (path name dependencies manager test-directory-policy macro-governance-policy source-scope-policy modularity-policy agent-policy))
;;; Boundary:
;;; - read-project-package coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> String ParsedData )
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
                            (package-modularity-policy root package-form)
                            (package-agent-policy package-form)))
     (build-scope
      (make-project-package "build.ss"
                            #f
                            '()
                            "gxpkg"
                            #f
                            #f
                            build-scope
                            #f
                            #f))
     (else #f))))
;;; Boundary:
;;; - read-package-form composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> String ParsedData )
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
;; : (-> String String )
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
;; : (-> String Integer )
(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (next (read port))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))
;; : (-> Datum Boolean )
(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))
;;; Boundary:
;;; - package-dependencies is a field lookup plus dependency string projection.
;;; - Reuse package-field-value so package metadata traversal has one owner.
;; : (-> Datum Integer )
(def (package-dependencies datum)
  (let (deps (package-field-value datum 'depend:))
    (if deps
      (unique (filter-map datum->string (datum-list-items deps)))
      '())))
;; : (-> Datum PackageTestDirectoryPolicy )
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
;; : (-> Policy PolicyTestDirectoryEntry )
(def (policy-test-directory-entry policy)
  (if (test-directory-policy-form? policy)
    policy
    (find test-directory-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (test-directory-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(test-directory-layout test-directory-policy))))
;; : (-> Datum PackageMacroGovernancePolicy )
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
;; : (-> Policy PolicyMacroGovernanceEntry )
(def (policy-macro-governance-entry policy)
  (if (macro-governance-policy-form? policy)
    policy
    (find macro-governance-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (macro-governance-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(macro-governance macro-policy))))
;; : (-> Datum String )
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
;; : (-> Policy String )
(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-scope))))
;; : (-> Root Datum PackageModularityPolicy )
(def (package-modularity-policy root datum)
  (let* ((policy (package-field-value datum 'policy:))
         (entry (and policy (policy-modularity-entry policy)))
         (inline-policy (and entry (modularity-policy-entry->policy entry #f)))
         (config-policy
          (and inline-policy
               (modularity-policy-config-path inline-policy)
               (read-modularity-policy-config
                root
                (modularity-policy-config-path inline-policy)))))
    (merge-modularity-policies inline-policy config-policy)))
;;; Boundary:
;;; - policy-modularity-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyModularityEntry )
(def (policy-modularity-entry policy)
  (if (modularity-policy-form? policy)
    policy
    (find modularity-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (modularity-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(modularity modularity-policy modularity-rules))))
;;; Boundary:
;;; - modularity-policy-entry->policy owns package field normalization.
;;; - Keep threshold aliases and config-file semantics visible here.
;; : (-> Datum MaybePath PackageModularityPolicy )
(def (modularity-policy-entry->policy entry config-path)
  (make-modularity-policy
   (or (policy-boolean-field entry 'disabled:)
       (policy-boolean-field entry 'disable:))
   (or (policy-string-list-field entry 'enabled-rules:)
       (policy-string-list-field entry 'enable:)
       '())
   (or (policy-string-list-field entry 'disabled-rules:)
       (policy-string-list-field entry 'disable:)
       '())
   (policy-integer-field*
    entry
    '(max-source-lines: max-source-line-count: source-max-lines:))
   (policy-integer-field*
    entry
    '(max-test-lines: max-test-line-count: test-max-lines:))
   (policy-integer-field*
    entry
    '(min-source-definitions: min-source-definition-count:))
   (policy-integer-field*
    entry
    '(min-test-definitions: min-test-definition-count:))
   (policy-integer-field*
    entry
    '(max-test-cases: max-test-case-count: test-case-max:))
   (policy-integer-field*
    entry
    '(max-test-definition-span: test-definition-span-max:))
   (or (policy-string-field entry 'config:)
       (policy-string-field entry 'config-file:)
       (policy-string-field entry 'path:)
       config-path)
   (policy-string-field entry 'explanation:)))
;;; Boundary:
;;; - read-modularity-policy-config reads the package-selected external file.
;;; - Missing or malformed config stays a package-policy absence, not a fallback.
;; : (-> Root ConfigPath PackageModularityPolicy )
(def (read-modularity-policy-config root config-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand config-path root))
            (forms (read-package-forms path))
            (entry (find modularity-policy-form? forms)))
       (and entry
            (modularity-policy-entry->policy entry config-path))))))
;;; Boundary:
;;; - merge-modularity-policies lets gerbil.pkg override shared config values.
;;; - Keep list overrides explicit so agent-facing rule filters stay readable.
;; : (-> MaybePolicy MaybePolicy PackageModularityPolicy )
(def (merge-modularity-policies inline-policy config-policy)
  (cond
   ((and inline-policy config-policy)
    (make-modularity-policy
     (or (modularity-policy-disabled inline-policy)
         (modularity-policy-disabled config-policy))
     (policy-list-override
      (modularity-policy-enabled-rules inline-policy)
      (modularity-policy-enabled-rules config-policy))
     (policy-list-override
      (modularity-policy-disabled-rules inline-policy)
      (modularity-policy-disabled-rules config-policy))
     (or (modularity-policy-max-source-line-count inline-policy)
         (modularity-policy-max-source-line-count config-policy))
     (or (modularity-policy-max-test-line-count inline-policy)
         (modularity-policy-max-test-line-count config-policy))
     (or (modularity-policy-min-source-definition-count inline-policy)
         (modularity-policy-min-source-definition-count config-policy))
     (or (modularity-policy-min-test-definition-count inline-policy)
         (modularity-policy-min-test-definition-count config-policy))
     (or (modularity-policy-max-test-case-count inline-policy)
         (modularity-policy-max-test-case-count config-policy))
     (or (modularity-policy-max-test-definition-span inline-policy)
         (modularity-policy-max-test-definition-span config-policy))
     (or (modularity-policy-config-path inline-policy)
         (modularity-policy-config-path config-policy))
     (or (modularity-policy-explanation inline-policy)
         (modularity-policy-explanation config-policy))))
   (inline-policy inline-policy)
   (else config-policy)))
;;; Boundary:
;;; - policy-list-override keeps rule-list precedence separate from scalars.
;;; - Empty primary lists intentionally fall through to the config file list.
;; : (-> (List String) (List String) (List String) )
(def (policy-list-override primary fallback)
  (if (and primary (pair? primary))
    primary
    (or fallback '())))
;;; Boundary:
;;; Package forms have at most one build script declaration for harness scope.
;;; The find combinator makes that single-owner lookup explicit and leaves the
;;; target value decoder responsible for quoted/list/string normalization.
;; : (-> (List String) BuildScriptTargets )
(def (build-script-targets forms)
  (let (form (find build-script-form? forms))
    (if form
      (build-script-target-value (safe-cadr form))
      '())))
;; : (-> Datum Boolean )
(def (build-script-form? datum)
  (and (pair? datum) (eq? (car datum) 'defbuild-script)))
;;; Boundary:
;;; - build-script-target-value composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum BuildScriptTargetValue )
(def (build-script-target-value datum)
  (cond
   ((not datum) '())
   ((quoted-datum? datum) (build-script-target-value (safe-cadr datum)))
   ((or (string? datum) (symbol? datum)) [(datum->string datum)])
   (else (filter-map datum->string (datum-list-items datum)))))
;; : (-> Datum Boolean )
(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))
;;; Boundary:
;;; - build-target-source-roots composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Targets (List String) )
(def (build-target-source-roots targets)
  (unique (filter-map build-target-source-root targets)))
;; : (-> Target BuildTargetSourceRoot )
(def (build-target-source-root target)
  (let (slash (and target (string-index target #\/)))
    (cond
     ((not target) #f)
     ((not slash) ".")
     ((fx= slash 0) ".")
     (else (substring target 0 slash)))))
;; : (-> Datum PackageAgentPolicy )
(def (package-agent-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-agent-entry policy))
           (and entry
                (make-agent-policy
                 (or (policy-string-list-field entry 'disabled-rules:)
                     (policy-string-list-field entry 'disable:)
                     '())
                 (policy-string-field entry 'explanation:)))))))
;;; Boundary:
;;; - policy-agent-entry composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Policy PolicyAgentEntry )
(def (policy-agent-entry policy)
  (if (agent-policy-form? policy)
    policy
    (find agent-policy-form? (datum-list-items policy))))
;; : (-> Datum Boolean )
(def (agent-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(agent-policy policy-rules))))
;; : (-> Datum PolicyDirectoryList )
(def (policy-directory-list datum)
  (or (policy-string-list-field datum 'allowed-directories:)
      (policy-string-list-field datum 'allow-directories:)
      (policy-string-list-field datum 'allow:)
      '()))
;;; Boundary:
;;; - policy-string-list-field composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> Datum String String )
(def (policy-string-list-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((not value) #f)
     ((or (string? value) (symbol? value)) [(datum->string value)])
     (else (unique (filter-map datum->string (datum-list-items value)))))))
;; : (-> Datum String String )
(def (policy-string-field datum field)
  (let (value (package-field-value datum field))
    (and value (datum->string value))))
;; : (-> Datum String PolicyBooleanField )
(def (policy-boolean-field datum field)
  (let (value (package-field-value datum field))
    (truthy-policy-value? value)))
;;; Boundary:
;;; - policy-integer-field* checks aliases in declared precedence order.
;;; - Use parser-owned package fields instead of string scanning.
;; : (-> Datum (List Symbol) Integer )
(def (policy-integer-field* datum fields)
  (ormap (cut policy-integer-field datum <>) fields))
;;; Boundary:
;;; - policy-integer-field normalizes numeric package policy values.
;;; - Keep invalid or absent values false so callers can use defaults.
;; : (-> Datum Symbol Integer )
(def (policy-integer-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((not value) #f)
     ((integer? value) value)
     (else
      (let (parsed (string->number (datum->string value)))
        (and (integer? parsed) parsed))))))
;; : (-> PolicyValue Boolean )
(def (truthy-policy-value? value)
  (if (or (eq? value #t)
          (member (datum->string value) '("true" "yes" "allow" "allowed")))
    #t
    #f))
;; package-field-value
;;   : (-> Datum Symbol (U #f Datum))
;;   | doc m%
;;       `package-field-value datum field` returns the datum immediately after a
;;       package field marker, or `#f` when the field is absent.
;;
;;       # Examples
;;
;;       ```scheme
;;       (package-field-value '(package: name "demo") 'name)
;;       ;; => "demo"
;;       ```
;;     %
(def (package-field-value datum field)
  (let (tail (member field (datum-list-items datum)))
    (and tail
         (pair? (cdr tail))
         (cadr tail))))
;; datum->string
;;   : (-> Obj (U #f String))
;;   | doc m%
;;       `datum->string obj` converts package datums into comparable string
;;       values, preserving `#f` for absent data.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->string 'allow)
;;       ;; => "allow"
;;       ```
;;     %
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))
