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

(defstruct test-directory-policy (allowed-directories explanation))
(defstruct macro-governance-policy (allow-generated explanation witness))
(defstruct source-scope-policy (roots runtime-roots exclude-directories explanation))
(defstruct agent-policy (enabled-rules disabled-rules))
(defstruct project-package (path name dependencies manager test-directory-policy macro-governance-policy source-scope-policy agent-policy))

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

(def (read-package-form root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path)))
       (find package-form? forms)))))

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

(def (read-package-forms path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (next (read port))
          (if (eof-object? next)
            (reverse out)
            (lp (cons next out))))))))

(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))

(def (package-dependencies datum)
  (let lp ((rest (datum-list-items datum)))
    (match rest
      (['depend: deps . _]
       (dedupe (filter-map datum->string (datum-list-items deps))))
      ([_ . more] (lp more))
      (else '()))))

(def (package-test-directory-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-test-directory-entry policy))
           (and entry
                (make-test-directory-policy
                 (policy-directory-list entry)
                 (policy-string-field entry 'explanation:)))))))

(def (policy-test-directory-entry policy)
  (if (test-directory-policy-form? policy)
    policy
    (find test-directory-policy-form? (datum-list-items policy))))

(def (test-directory-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(test-directory-layout test-directory-policy))))

(def (package-macro-governance-policy datum)
  (let (policy (package-field-value datum 'policy:))
    (and policy
         (let (entry (policy-macro-governance-entry policy))
           (and entry
                (make-macro-governance-policy
                 (policy-boolean-field entry 'allow-generated:)
                 (policy-string-field entry 'explanation:)
                 (policy-string-field entry 'witness:)))))))

(def (policy-macro-governance-entry policy)
  (if (macro-governance-policy-form? policy)
    policy
    (find macro-governance-policy-form? (datum-list-items policy))))

(def (macro-governance-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(macro-governance macro-policy))))

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

(def (policy-source-scope-entry policy)
  (if (source-scope-policy-form? policy)
    policy
    (find source-scope-policy-form? (datum-list-items policy))))

(def (source-scope-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(source-scope source-policy project-scope))))

(def (build-script-targets forms)
  (let (form (find build-script-form? forms))
    (if form
      (build-script-target-value (safe-cadr form))
      '())))

(def (build-script-form? datum)
  (and (pair? datum) (eq? (car datum) 'defbuild-script)))

(def (build-script-target-value datum)
  (cond
   ((not datum) '())
   ((quoted-datum? datum) (build-script-target-value (safe-cadr datum)))
   ((or (string? datum) (symbol? datum)) [(datum->string datum)])
   (else (filter-map datum->string (datum-list-items datum)))))

(def (quoted-datum? datum)
  (and (pair? datum) (eq? (car datum) 'quote)))

(def (build-target-source-roots targets)
  (dedupe-strings
   (filter-map build-target-source-root targets)))

(def (build-target-source-root target)
  (let (slash (and target (string-index target #\/)))
    (cond
     ((not target) #f)
     ((not slash) ".")
     ((fx= slash 0) ".")
     (else (substring target 0 slash)))))

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

(def (policy-agent-entry policy)
  (if (agent-policy-form? policy)
    policy
    (find agent-policy-form? (datum-list-items policy))))

(def (agent-policy-form? datum)
  (and (pair? datum)
       (member (car datum) '(agent-policy policy-rules))))

(def (policy-directory-list datum)
  (or (policy-string-list-field datum 'allowed-directories:)
      (policy-string-list-field datum 'allow-directories:)
      (policy-string-list-field datum 'allow:)
      '()))

(def (policy-string-list-field datum field)
  (let (value (package-field-value datum field))
    (cond
     ((not value) #f)
     ((or (string? value) (symbol? value)) [(datum->string value)])
     (else (dedupe (filter-map datum->string (datum-list-items value)))))))

(def (policy-string-field datum field)
  (let (value (package-field-value datum field))
    (and value (datum->string value))))

(def (policy-boolean-field datum field)
  (let (value (package-field-value datum field))
    (truthy-policy-value? value)))

(def (truthy-policy-value? value)
  (if (or (eq? value #t)
          (member (datum->string value) '("true" "yes" "allow" "allowed")))
    #t
    #f))

(def (package-field-value datum field)
  (let lp ((rest (datum-list-items datum)))
    (match rest
      ([key value . _]
       (if (eq? key field)
         value
         (lp (cdr rest))))
      (else #f))))

(def (datum-list-items obj)
  (let lp ((rest obj) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((pair? rest) (lp (cdr rest) (cons (car rest) out)))
     (else (reverse out)))))

(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))

(def (dedupe items)
  (let lp ((rest items) (seen '()) (out '()))
    (match rest
      ([item . more]
       (if (member item seen)
         (lp more seen out)
         (lp more (cons item seen) (cons item out))))
      (else (reverse out)))))

(def (dedupe-strings items)
  (let lp ((rest items) (seen '()) (out '()))
    (match rest
      ([item . more]
       (if (string-list-member? item seen)
         (lp more seen out)
         (lp more (cons item seen) (cons item out))))
      (else (reverse out)))))

(def (string-list-member? item items)
  (find (lambda (candidate) (string=? item candidate)) items))
