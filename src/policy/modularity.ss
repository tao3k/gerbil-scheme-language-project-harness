;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :parser/facade
        :policy/model
        :std/srfi/13
        :std/sugar
        :types/findings)

(export run-modularity-policy
        +max-source-line-count+
        +min-source-definition-count+
        facade-source-file?
        facade-implementation-finding
        sibling-file-dir-owner-collision-finding
        repeated-owner-entry-finding
        bin-entrypoint-implementation-finding
        source-leaf-bloat-finding)

(def +max-source-line-count+ 650)
(def +min-source-definition-count+ 40)
(def +default-test-directory+ "t")
(def +min-test-directory-policy-explanation-length+ 24)

(def (run-modularity-policy index)
  (append
   (sibling-file-dir-owner-collision-findings index)
   (repeated-owner-entry-findings index)
   (bin-entrypoint-implementation-findings index)
   (facade-implementation-findings index)
   (test-directory-layout-findings index)
   (source-leaf-bloat-findings index)))

(def (sibling-file-dir-owner-collision-findings index)
  (filter-map
   (lambda (file)
     (let* ((path (source-file-path file))
            (owner-prefix (sibling-owner-prefix index path)))
       (and owner-prefix
            (owner-prefix-has-child-source? index owner-prefix path)
            (sibling-file-dir-owner-collision-finding file owner-prefix))))
   (project-index-files index)))

(def (repeated-owner-entry-findings index)
  (filter-map
   (lambda (file)
     (and (repeated-owner-entry-path? index (source-file-path file))
          (repeated-owner-entry-finding file)))
   (project-index-files index)))

(def (bin-entrypoint-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (bin-entrypoint-source-file? file)
          (pair? (source-file-definitions file))
          (bin-entrypoint-implementation-finding file)))
   (project-index-files index)))

(def (facade-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (pair? (source-file-definitions file))
          (facade-implementation-finding file)))
   (project-index-files index)))

(def (facade-source-file? index file)
  (let* ((path (source-file-path file))
         (owner-prefix (owner-entry-prefix index path)))
    (and owner-prefix
         (owner-prefix-has-child-source? index owner-prefix path))))

(def (owner-prefix-has-child-source? index owner-prefix path)
  (ormap
   (lambda (candidate)
     (let (candidate-path (source-file-path candidate))
       (and (not (equal? candidate-path path))
            (project-gerbil-source-path? index candidate-path)
            (string-prefix? owner-prefix candidate-path))))
   (project-index-files index)))

(def (sibling-owner-prefix index path)
  (and (project-gerbil-source-path? index path)
       (string-append (path-without-extension path) "/")))

(def (owner-entry-prefix index path)
  (and (project-gerbil-source-path? index path)
       (facade-entry-path? index path)
       (path-parent-prefix path)))

(def (facade-entry-path? index path)
  (and (project-gerbil-source-path? index path)
       (equal? (path-stem path) "facade")
       (path-parent-prefix path)
       (not (source-root-parent-prefix? index (path-parent-prefix path)))))

(def (repeated-owner-entry-path? index path)
  (let ((parent (path-parent-prefix path))
        (stem (path-stem path)))
    (and parent
         (project-gerbil-source-path? index path)
         (not (source-root-parent-prefix? index parent))
         (equal? stem (path-parent-name parent)))))

(def (owner-entry-path? index path)
  (repeated-owner-entry-path? index path))

(def (project-gerbil-source-path? index path)
  (and (string-suffix? ".ss" path)
       (not (config-file-path? path))
       (ormap (lambda (root)
                (source-path-under-root? path root))
              (project-source-roots index))))

(def (config-file-path? path)
  (find (lambda (candidate) (string=? path candidate)) +config-files+))

(def (project-source-roots index)
  (let* ((package (project-index-package index))
         (policy (and package
                      (project-package-source-scope-policy package)))
         (roots (and policy (source-scope-policy-roots policy))))
    (cond
     ((and roots (pair? roots)) roots)
     ((and policy (pair? (source-scope-policy-runtime-roots policy)))
      (source-scope-policy-runtime-roots policy))
     (else ["src"]))))

(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (source-root-prefix root) path)))

(def (source-root-parent-prefix? index parent)
  (ormap (lambda (root)
           (equal? parent (source-root-prefix root)))
         (project-source-roots index)))

(def (source-root-prefix root)
  (cond
   ((equal? root ".") "")
   ((string-suffix? "/" root) root)
   (else (string-append root "/"))))

(def (bin-entrypoint-source-file? file)
  (let (path (source-file-path file))
    (and (string-prefix? "bin/" path)
         (string-suffix? ".ss" path))))

(def (non-t-test-directory-source-file file)
  (let* ((path (source-file-path file))
         (directory (non-t-test-directory-name path)))
    (and directory
         (string-suffix? ".ss" path)
         directory)))

(def (non-t-test-directory-name path)
  (cond
   ((path-contains-directory? path "test") "test")
   ((path-contains-directory? path "tests") "tests")
   (else #f)))

(def (path-contains-directory? path directory)
  (or (string-prefix? (string-append directory "/") path)
      (string-contains path (string-append "/" directory "/"))))

(def (path-without-extension path)
  (substring path 0 (- (string-length path) 3)))

(def (path-parent-prefix path)
  (let (slash (string-index-right path #\/))
    (and slash
         (substring path 0 (fx1+ slash)))))

(def (path-parent-name parent-prefix)
  (let* ((trimmed (substring parent-prefix 0 (fx1- (string-length parent-prefix))))
         (slash (string-index-right trimmed #\/)))
    (if slash
      (substring trimmed (fx1+ slash) (string-length trimmed))
      trimmed)))

(def (path-stem path)
  (let* ((stem-path (path-without-extension path))
         (slash (string-index-right stem-path #\/)))
    (if slash
      (substring stem-path (fx1+ slash) (string-length stem-path))
      stem-path)))

(def (facade-implementation-finding file)
  (let* ((definition (car (source-file-definitions file)))
         (selector (definition-selector definition)))
    (make-type-finding
     (policy-rule-id +modularity-facade-rule+)
     (policy-rule-severity +modularity-facade-rule+)
     (source-file-path file)
     (string-append "facade " (source-file-path file)
                    " contains implementation definitions")
     selector
     (hash (definition (definition-name definition))
           (selector selector)))))

(def (sibling-file-dir-owner-collision-finding file owner-prefix)
  (make-type-finding
   (policy-rule-id +modularity-owner-collision-rule+)
   (policy-rule-severity +modularity-owner-collision-rule+)
   (source-file-path file)
   (string-append (source-file-path file)
                  " and "
                  owner-prefix
                  " share the same owner name at one filesystem level")
   (source-file-path file)
   (hash (ownerDirectory owner-prefix))))

(def (repeated-owner-entry-finding file)
  (let* ((path (source-file-path file))
         (parent (path-parent-prefix path))
         (owner (and parent (path-parent-name parent))))
    (make-type-finding
     (policy-rule-id +modularity-repeated-owner-entry-rule+)
     (policy-rule-severity +modularity-repeated-owner-entry-rule+)
     path
     (string-append path
                    " repeats owner name "
                    owner
                    " inside its own directory")
     path
     (hash (owner owner)
           (replacement "facade.ss")))))

(def (bin-entrypoint-implementation-finding file)
  (let* ((definition (car (source-file-definitions file)))
         (selector (definition-selector definition)))
    (make-type-finding
     (policy-rule-id +modularity-bin-entrypoint-rule+)
     (policy-rule-severity +modularity-bin-entrypoint-rule+)
     (source-file-path file)
     (string-append "entrypoint "
                    (source-file-path file)
                    " contains implementation definition "
                    (definition-name definition))
     selector
     (hash (definition (definition-name definition))
           (selector selector)))))

(def (test-directory-layout-findings index)
  (filter-map
   (lambda (file)
     (let (actual-directory (non-t-test-directory-source-file file))
       (and actual-directory
            (not (test-directory-policy-allows? index actual-directory))
            (test-directory-layout-finding index file actual-directory))))
   (project-index-files index)))

(def (test-directory-policy-allows? index directory)
  (and (test-directory-policy-directory-listed? index directory)
       (test-directory-policy-explanation-clear? (project-test-directory-policy index))))

(def (test-directory-policy-directory-listed? index directory)
  (let (policy (project-test-directory-policy index))
    (and policy
         (member directory (test-directory-policy-allowed-directories policy)))))

(def (test-directory-policy-explanation-clear? policy)
  (and policy
       (let (explanation (test-directory-policy-explanation policy))
         (and explanation
              (fx>= (string-length (string-trim explanation))
                    +min-test-directory-policy-explanation-length+)))))

(def (project-test-directory-policy index)
  (and (project-index-package index)
       (project-package-test-directory-policy (project-index-package index))))

(def (test-directory-layout-finding index file actual-directory)
  (let* ((policy (project-test-directory-policy index))
         (listed? (test-directory-policy-directory-listed? index actual-directory))
         (explanation (and policy (test-directory-policy-explanation policy)))
         (reason (test-directory-policy-rejection-reason policy listed?)))
    (make-type-finding
     (policy-rule-id +modularity-test-directory-rule+)
     (policy-rule-severity +modularity-test-directory-rule+)
     (source-file-path file)
     (string-append "Gerbil unit test owner "
                    (source-file-path file)
                    " uses non-t "
                    actual-directory
                    "/ layout; use t/ unless gerbil.pkg policy explicitly allows this directory with a clear explanation ("
                    reason
                    ")")
     (source-file-path file)
     (hash (expectedDirectory +default-test-directory+)
           (actualDirectory actual-directory)
           (policyDirectoryAllowed listed?)
           (policyExplanation explanation)
           (policyExplanationMinimumChars
            +min-test-directory-policy-explanation-length+)))))

(def (test-directory-policy-rejection-reason policy listed?)
  (cond
   ((not policy) "no policy override")
   ((not listed?) "directory is not allowed by policy")
   (else "policy override is missing a clear explanation")))

(def (source-leaf-bloat-findings index)
  (filter-map
   (lambda (file)
     (and (project-gerbil-source-path? index (source-file-path file))
          (fx>= (source-file-line-count file) +max-source-line-count+)
          (fx>= (length (source-file-definitions file)) +min-source-definition-count+)
          (source-leaf-bloat-finding file)))
   (project-index-files index)))

(def (source-leaf-bloat-finding file)
  (make-type-finding
   (policy-rule-id +modularity-source-leaf-rule+)
   (policy-rule-severity +modularity-source-leaf-rule+)
   (source-file-path file)
   (string-append (source-file-path file)
                  " carries " (number->string (source-file-line-count file))
                  " lines and "
                  (number->string (length (source-file-definitions file)))
                  " definitions")
   (source-file-path file)
   (hash (lineCount (source-file-line-count file))
         (definitionCount (length (source-file-definitions file))))))
