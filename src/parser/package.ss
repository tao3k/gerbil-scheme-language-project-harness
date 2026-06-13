;;; -*- Gerbil -*-
;;; Parser-owned package metadata facts.

(import :gerbil/gambit)

(export read-project-package
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        project-package-macro-governance-policy
        test-directory-policy-allowed-directories
        test-directory-policy-explanation
        macro-governance-policy-allow-generated
        macro-governance-policy-explanation
        macro-governance-policy-witness)

(defstruct test-directory-policy (allowed-directories explanation))
(defstruct macro-governance-policy (allow-generated explanation witness))
(defstruct project-package (path name dependencies manager test-directory-policy macro-governance-policy))

(def (read-project-package root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (forms (read-package-forms path))
            (package-form (find package-form? forms)))
       (and package-form
            (make-project-package "gerbil.pkg"
                                  (datum->string (safe-cadr package-form))
                                  (package-dependencies package-form)
                                  "gxpkg"
                                  (package-test-directory-policy package-form)
                                  (package-macro-governance-policy package-form)))))))

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
