;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :parser
        :policy/model
        :std/srfi/13
        :types/findings)

(export run-modularity-policy
        +max-source-line-count+
        +min-source-definition-count+
        facade-source-file?
        facade-implementation-finding
        source-leaf-bloat-finding)

(def +max-source-line-count+ 650)
(def +min-source-definition-count+ 40)

(def (run-modularity-policy index)
  (append
   (facade-implementation-findings index)
   (source-leaf-bloat-findings index)))

(def (facade-implementation-findings index)
  (filter-map
   (lambda (file)
     (and (facade-source-file? index file)
          (pair? (source-file-definitions file))
          (facade-implementation-finding file)))
   (project-index-files index)))

(def (facade-source-file? index file)
  (let* ((path (source-file-path file))
         (owner-prefix (facade-owner-prefix path)))
    (and owner-prefix
         (ormap
          (lambda (candidate)
            (string-prefix? owner-prefix (source-file-path candidate)))
          (project-index-files index)))))

(def (facade-owner-prefix path)
  (and (string-prefix? "src/" path)
       (string-suffix? ".ss" path)
       (let (tail (substring path 4 (string-length path)))
         (and (not (string-contains tail "/"))
              (string-append (substring path 0 (- (string-length path) 3))
                             "/")))))

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
