;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :gerbil/gambit
        :parser/facade
        :policy/model
        :std/misc/ports
        :std/srfi/13
        :std/sugar
        :types/findings)

(export run-modularity-policy
        +max-source-line-count+
        +max-test-line-count+
        +min-source-definition-count+
        +min-test-definition-count+
        facade-source-file?
        facade-implementation-finding
        sibling-file-dir-owner-collision-finding
        repeated-owner-entry-finding
        bin-entrypoint-implementation-finding
        source-leaf-bloat-finding
        test-leaf-bloat-finding)
;; Integer
(def +max-source-line-count+ 650)
;; Integer
(def +max-test-line-count+ 650)
;; Integer
(def +min-source-definition-count+ 40)
;; Integer
(def +min-test-definition-count+ 1)
;; ConfigConstant
(def +default-test-directory+ "t")
;; Integer
(def +min-test-directory-policy-explanation-length+ 24)
;;; Boundary:
;;; - project-modularity-policy is the only package policy lookup for this rule family.
;;; - Keep root/package ownership separate from per-file policy decisions.
;; PackageModularityPolicy <- ProjectIndex
(def (project-modularity-policy index)
  (and (project-index-package index)
       (project-package-modularity-policy (project-index-package index))))
;; Boolean <- MaybePolicy
(def (modularity-policy-disabled? policy)
  (and policy (modularity-policy-disabled policy)))
;;; Boundary:
;;; - filter-enabled-modularity-findings applies package rule lists after detection.
;;; - Detector coverage stays project-wide even when gerbil.pkg filters output.
;; (List TypeFinding) <- MaybePolicy (List TypeFinding)
(def (filter-enabled-modularity-findings policy findings)
  (if policy
    (filter (cut modularity-finding-enabled? policy <>)
            findings)
    findings))
;; Boolean <- Policy TypeFinding
(def (modularity-finding-enabled? policy finding)
  (let ((rule-id (type-finding-rule-id finding))
        (enabled (modularity-policy-enabled-rules policy))
        (disabled (modularity-policy-disabled-rules policy)))
    (and (or (null? enabled) (member rule-id enabled))
         (not (member rule-id disabled)))))
;;; Boundary:
;;; - sibling-file-dir-owner-collision-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (sibling-file-dir-owner-collision-findings index)
  (filter-map
   (lambda (file)
     (let* ((path (source-file-path file))
            (owner-prefix (sibling-owner-prefix index path)))
       (and owner-prefix
            (owner-prefix-has-child-source? index owner-prefix path)
            (sibling-file-dir-owner-collision-finding file owner-prefix))))
   (project-index-files index)))
;;; Boundary:
;;; - repeated-owner-entry-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (repeated-owner-entry-findings index)
  (filter-map
   (lambda (file)
     (and (repeated-owner-entry-path? index (source-file-path file))
          (repeated-owner-entry-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - bin-entrypoint-implementation-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (bin-entrypoint-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (bin-entrypoint-source-file? file)
          (pair? (source-file-definitions file))
          (bin-entrypoint-implementation-finding file)))
   (project-index-files index)))
;;; Boundary:
;;; - facade-implementation-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (facade-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (pair? (source-file-definitions file))
          (facade-implementation-finding file)))
   (project-index-files index)))
;; Boolean <- ProjectIndex SourceFile
(def (facade-source-file? index file)
  (let* ((path (source-file-path file))
         (owner-prefix (owner-entry-prefix index path)))
    (and owner-prefix
         (owner-prefix-has-child-source? index owner-prefix path))))
;;; Boundary:
;;; - owner-prefix-has-child-source? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex OwnerPrefix String
(def (owner-prefix-has-child-source? index owner-prefix path)
  (ormap
   (lambda (candidate)
     (let (candidate-path (source-file-path candidate))
       (and (not (equal? candidate-path path))
            (project-gerbil-source-path? index candidate-path)
            (string-prefix? owner-prefix candidate-path))))
   (project-index-files index)))
;; String <- ProjectIndex String
(def (sibling-owner-prefix index path)
  (and (project-gerbil-source-path? index path)
       (string-append (path-without-extension path) "/")))
;; String <- ProjectIndex String
(def (owner-entry-prefix index path)
  (and (project-gerbil-source-path? index path)
       (facade-entry-path? index path)
       (path-parent-prefix path)))
;; Boolean <- ProjectIndex String
(def (facade-entry-path? index path)
  (and (project-gerbil-source-path? index path)
       (equal? (path-stem path) "facade")
       (path-parent-prefix path)
       (not (source-root-parent-prefix? index (path-parent-prefix path)))))
;; Boolean <- ProjectIndex String
(def (repeated-owner-entry-path? index path)
  (let ((parent (path-parent-prefix path))
        (stem (path-stem path)))
    (and parent
         (project-gerbil-source-path? index path)
         (not (source-root-parent-prefix? index parent))
         (equal? stem (path-parent-name parent)))))
;; Boolean <- ProjectIndex String
(def (owner-entry-path? index path)
  (repeated-owner-entry-path? index path))
;;; Boundary:
;;; - project-gerbil-source-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex String
(def (project-gerbil-source-path? index path)
  (and (string-suffix? ".ss" path)
       (not (config-file-path? path))
       (ormap (lambda (root)
                (source-path-under-root? path root))
              (project-source-roots index))))
;;; Boundary:
;;; - config-file-path? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (config-file-path? path)
  (find (lambda (candidate) (string=? path candidate)) +config-files+))
;; (List String) <- ProjectIndex
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
;; Boolean <- String String
(def (source-path-under-root? path root)
  (or (equal? root ".")
      (equal? path root)
      (string-prefix? (source-root-prefix root) path)))
;;; Boundary:
;;; - source-root-parent-prefix? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- ProjectIndex Parent
(def (source-root-parent-prefix? index parent)
  (ormap (lambda (root)
           (equal? parent (source-root-prefix root)))
         (project-source-roots index)))
;; String <- String
(def (source-root-prefix root)
  (cond
   ((equal? root ".") "")
   ((string-suffix? "/" root) root)
   (else (string-append root "/"))))
;; Boolean <- SourceFile
(def (bin-entrypoint-source-file? file)
  (let (path (source-file-path file))
    (and (string-prefix? "bin/" path)
         (string-suffix? ".ss" path))))
;; SourceFile <- SourceFile
(def (non-t-test-directory-source-file file)
  (let* ((path (source-file-path file))
         (directory (non-t-test-directory-name path)))
    (and directory
         (string-suffix? ".ss" path)
         directory)))
;; NonTTestDirectoryName <- String
(def (non-t-test-directory-name path)
  (cond
   ((path-contains-directory? path "test") "test")
   ((path-contains-directory? path "tests") "tests")
   (else #f)))
;; Boolean <- String Directory
(def (path-contains-directory? path directory)
  (or (string-prefix? (string-append directory "/") path)
      (string-contains path (string-append "/" directory "/"))))
;; String <- String
(def (path-without-extension path)
  (substring path 0 (- (string-length path) 3)))
;; String <- String
(def (path-parent-prefix path)
  (let (slash (string-index-right path #\/))
    (and slash
         (substring path 0 (fx1+ slash)))))
;; String <- ParentPrefix
(def (path-parent-name parent-prefix)
  (let* ((trimmed (substring parent-prefix 0 (fx1- (string-length parent-prefix))))
         (slash (string-index-right trimmed #\/)))
    (if slash
      (substring trimmed (fx1+ slash) (string-length trimmed))
      trimmed)))
;; String <- String
(def (path-stem path)
  (let* ((stem-path (path-without-extension path))
         (slash (string-index-right stem-path #\/)))
    (if slash
      (substring stem-path (fx1+ slash) (string-length stem-path))
      stem-path)))
;; TypeFinding <- SourceFile
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
;; TypeFinding <- SourceFile OwnerPrefix
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
;; TypeFinding <- SourceFile
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
;; TypeFinding <- SourceFile
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
;;; Boundary:
;;; - test-directory-layout-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex
(def (test-directory-layout-findings index)
  (filter-map
   (lambda (file)
     (let (actual-directory (non-t-test-directory-source-file file))
       (and actual-directory
            (not (test-directory-policy-allows? index actual-directory))
            (test-directory-layout-finding index file actual-directory))))
   (project-index-files index)))
;; Boolean <- ProjectIndex Directory
(def (test-directory-policy-allows? index directory)
  (and (test-directory-policy-directory-listed? index directory)
       (test-directory-policy-explanation-clear? (project-test-directory-policy index))))
;; Boolean <- ProjectIndex Directory
(def (test-directory-policy-directory-listed? index directory)
  (let (policy (project-test-directory-policy index))
    (and policy
         (member directory (test-directory-policy-allowed-directories policy)))))
;; Boolean <- Policy
(def (test-directory-policy-explanation-clear? policy)
  (and policy
       (let (explanation (test-directory-policy-explanation policy))
         (and explanation
              (fx>= (string-length (string-trim explanation))
                    +min-test-directory-policy-explanation-length+)))))
;; ProjectTestDirectoryPolicy <- ProjectIndex
(def (project-test-directory-policy index)
  (and (project-index-package index)
       (project-package-test-directory-policy (project-index-package index))))
;; TypeFinding <- ProjectIndex SourceFile ActualDirectory
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
;; String <- Policy Listed
(def (test-directory-policy-rejection-reason policy listed?)
  (cond
   ((not policy) "no policy override")
   ((not listed?) "directory is not allowed by policy")
   (else "policy override is missing a clear explanation")))
;;; Boundary:
;;; - source-leaf-bloat-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex MaybePolicy
(def (source-leaf-bloat-findings index policy)
  (let ((max-line-count (modularity-max-source-line-count policy))
        (min-definition-count (modularity-min-source-definition-count policy)))
    (filter-map
     (lambda (file)
       (let (effective-line-count (source-leaf-effective-line-count index file))
         (and (project-gerbil-source-path? index (source-file-path file))
              (not (project-gerbil-test-path? (source-file-path file)))
              (fx>= effective-line-count max-line-count)
              (fx>= (length (source-file-definitions file)) min-definition-count)
              (source-leaf-bloat-finding
               file
               effective-line-count
               max-line-count
               min-definition-count))))
     (project-index-files index))))
;;; Boundary:
;;; - test-leaf-bloat-findings covers package-local t/ owners explicitly.
;;; - Keep it separate from runtime source bloat so agents can read the rule intent.
;; (List TypeFinding) <- ProjectIndex MaybePolicy
(def (test-leaf-bloat-findings index policy)
  (let ((max-line-count (modularity-max-test-line-count policy))
        (min-definition-count (modularity-min-test-definition-count policy)))
    (filter-map
     (lambda (file)
       (let (effective-line-count (source-leaf-effective-line-count index file))
         (and (project-gerbil-test-path? (source-file-path file))
              (fx>= effective-line-count max-line-count)
              (fx>= (length (source-file-definitions file)) min-definition-count)
              (test-leaf-bloat-finding
               file
               effective-line-count
               max-line-count
               min-definition-count
               policy))))
     (project-index-files index))))
;;; Boundary:
;;; - modularity-max-source-line-count resolves package thresholds.
;;; - Defaults remain provider-owned when gerbil.pkg does not opt in.
;; Integer <- MaybePolicy
(def (modularity-max-source-line-count policy)
  (or (and policy (modularity-policy-max-source-line-count policy))
      +max-source-line-count+))
;; Integer <- MaybePolicy
(def (modularity-max-test-line-count policy)
  (or (and policy (modularity-policy-max-test-line-count policy))
      +max-test-line-count+))
;; Integer <- MaybePolicy
(def (modularity-min-source-definition-count policy)
  (or (and policy (modularity-policy-min-source-definition-count policy))
      +min-source-definition-count+))
;; Integer <- MaybePolicy
(def (modularity-min-test-definition-count policy)
  (or (and policy (modularity-policy-min-test-definition-count policy))
      +min-test-definition-count+))
;;; Boundary:
;;; - run-modularity-policy composes project-wide findings, then policy filters.
;;; - Do not narrow coverage by folder before package policy has been resolved.
;; Integer <- ProjectIndex
(def (run-modularity-policy index)
  (let (policy (project-modularity-policy index))
    (if (modularity-policy-disabled? policy)
      '()
      (filter-enabled-modularity-findings
       policy
       (append
        (sibling-file-dir-owner-collision-findings index)
        (repeated-owner-entry-findings index)
        (bin-entrypoint-implementation-findings index)
        (facade-implementation-findings index)
        (test-directory-layout-findings index)
        (source-leaf-bloat-findings index policy)
        (test-leaf-bloat-findings index policy))))))
;; Boolean <- String
(def (project-gerbil-test-path? path)
  (equal? (source-path-class path) "test"))
;;; Boundary:
;;; - source-leaf-effective-line-count composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- ProjectIndex SourceFile
(def (source-leaf-effective-line-count index file)
  (with-catch
   (lambda (_) (source-file-line-count file))
   (lambda ()
     (typed-ledger-effective-line-count
      (read-file-lines
       (path-expand (source-file-path file)
                    (project-index-root index)))))))
;;; Invariant:
;;; - typed-ledger-effective-line-count owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- (List String)
(def (typed-ledger-effective-line-count lines)
  (car
   (foldl (lambda (line state)
            (let ((count (car state))
                  (ledger? (cdr state)))
              (cond
               (ledger? state)
               ((equal? (string-trim line) ";;; typed-combinator-style ledger")
                (cons count #t))
               (else (cons (+ count 1) #f)))))
          (cons 0 #f)
          lines)))
;; TypeFinding <- SourceFile EffectiveLineCount MaybeLimit MaybeLimit
(def (source-leaf-bloat-finding file effective-line-count . maybe-limits)
  (let ((max-line-count (if (pair? maybe-limits)
                          (car maybe-limits)
                          +max-source-line-count+))
        (min-definition-count (if (and (pair? maybe-limits)
                                       (pair? (cdr maybe-limits)))
                                (cadr maybe-limits)
                                +min-source-definition-count+)))
    (make-type-finding
     (policy-rule-id +modularity-source-leaf-rule+)
     (policy-rule-severity +modularity-source-leaf-rule+)
     (source-file-path file)
     (string-append (source-file-path file)
                    " carries " (number->string effective-line-count)
                    " effective lines and "
                    (number->string (length (source-file-definitions file)))
                    " definitions")
     (source-file-path file)
     (hash (lineCount effective-line-count)
           (lineCountLimit max-line-count)
           (physicalLineCount (source-file-line-count file))
           (definitionCount (length (source-file-definitions file)))
           (definitionCountMinimum min-definition-count)))))
;; TypeFinding <- SourceFile EffectiveLineCount LineLimit DefinitionLimit MaybePolicy
(def (test-leaf-bloat-finding file effective-line-count max-line-count min-definition-count policy)
  (make-type-finding
   (policy-rule-id +modularity-test-leaf-rule+)
   (policy-rule-severity +modularity-test-leaf-rule+)
   (source-file-path file)
   (string-append (source-file-path file)
                  " carries " (number->string effective-line-count)
                  " effective test lines and "
                  (number->string (length (source-file-definitions file)))
                  " definitions; split the test owner or raise max-test-lines through gerbil.pkg modularity-policy when the package has a clear reason")
   (source-file-path file)
   (hash (sourceClass (source-path-class (source-file-path file)))
         (lineCount effective-line-count)
         (lineCountLimit max-line-count)
         (physicalLineCount (source-file-line-count file))
         (definitionCount (length (source-file-definitions file)))
         (definitionCountMinimum min-definition-count)
         (policyConfigPath (and policy (modularity-policy-config-path policy)))
         (policyExplanation (and policy (modularity-policy-explanation policy))))))
