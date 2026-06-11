;;; -*- Gerbil -*-
;;; Modularity policy checks over parser-owned source-file facts.

(import :parser
        :policy/model
        :std/srfi/13
        :types/findings)

(export run-modularity-policy
        facade-source-file?
        facade-implementation-finding)

(def (run-modularity-policy index)
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
