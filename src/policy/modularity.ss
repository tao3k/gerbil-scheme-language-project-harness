;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :parser/facade
        :policy/model
        :std/srfi/13
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

(def (run-modularity-policy index)
  (append
   (sibling-file-dir-owner-collision-findings index)
   (repeated-owner-entry-findings index)
   (bin-entrypoint-implementation-findings index)
   (facade-implementation-findings index)
   (source-leaf-bloat-findings index)))

(def (sibling-file-dir-owner-collision-findings index)
  (filter-map
   (lambda (file)
     (let* ((path (source-file-path file))
            (owner-prefix (sibling-owner-prefix path)))
       (and owner-prefix
            (owner-prefix-has-child-source? index owner-prefix path)
            (sibling-file-dir-owner-collision-finding file owner-prefix))))
   (project-index-files index)))

(def (repeated-owner-entry-findings index)
  (filter-map
   (lambda (file)
     (and (repeated-owner-entry-path? (source-file-path file))
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
         (owner-prefix (owner-entry-prefix path)))
    (and owner-prefix
         (owner-prefix-has-child-source? index owner-prefix path))))

(def (owner-prefix-has-child-source? index owner-prefix path)
  (ormap
   (lambda (candidate)
     (let (candidate-path (source-file-path candidate))
       (and (not (equal? candidate-path path))
            (gerbil-source-path? candidate-path)
            (string-prefix? owner-prefix candidate-path))))
   (project-index-files index)))

(def (sibling-owner-prefix path)
  (and (gerbil-source-path? path)
       (string-append (path-without-extension path) "/")))

(def (owner-entry-prefix path)
  (and (gerbil-source-path? path)
       (facade-entry-path? path)
       (path-parent-prefix path)))

(def (facade-entry-path? path)
  (and (gerbil-source-path? path)
       (equal? (path-stem path) "facade")
       (path-parent-prefix path)
       (not (equal? (path-parent-prefix path) "src/"))))

(def (repeated-owner-entry-path? path)
  (let ((parent (path-parent-prefix path))
        (stem (path-stem path)))
    (and parent
         (not (equal? parent "src/"))
         (equal? stem (path-parent-name parent)))))

(def (owner-entry-path? path)
  (repeated-owner-entry-path? path))

(def (gerbil-source-path? path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)))

(def (bin-entrypoint-source-file? file)
  (let (path (source-file-path file))
    (and (string-prefix? "bin/" path)
         (string-suffix? ".ss" path))))

(def (path-without-extension path)
  (substring path 0 (- (string-length path) 3)))

(def (path-parent-prefix path)
  (let (slash (last-index-of path #\/))
    (and slash
         (substring path 0 (fx1+ slash)))))

(def (path-parent-name parent-prefix)
  (let* ((trimmed (substring parent-prefix 0 (fx1- (string-length parent-prefix))))
         (slash (last-index-of trimmed #\/)))
    (if slash
      (substring trimmed (fx1+ slash) (string-length trimmed))
      trimmed)))

(def (path-stem path)
  (let* ((stem-path (path-without-extension path))
         (slash (last-index-of stem-path #\/)))
    (if slash
      (substring stem-path (fx1+ slash) (string-length stem-path))
      stem-path)))

(def (last-index-of text ch)
  (let lp ((index (fx1- (string-length text))))
    (cond
     ((fx< index 0) #f)
     ((char=? (string-ref text index) ch) index)
     (else (lp (fx1- index))))))

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

(def (source-leaf-bloat-findings index)
  (filter-map
   (lambda (file)
     (and (fx>= (source-file-line-count file) +max-source-line-count+)
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
