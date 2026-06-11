;;; -*- Gerbil -*-
;;; Check command adapter.

(import :constants
        :parser
        :protocol/json
        :support/args
        :types)

(export check-main)

(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (index (collect-project root))
         (findings (run-type-checks index))
         (status (type-status findings)))
    (if json?
      (write-json-line
       (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-report")
             (schemaVersion "1")
             (languageId +language-id+)
             (providerId +provider-id+)
             (status status)
             (files (length (project-index-files index)))
             (definitions (length (project-definitions index)))
             (findings (map finding-json findings))))
      (begin
        (displayln "[gerbil-check] status=" status
                   " files=" (length (project-index-files index))
                   " definitions=" (length (project-definitions index))
                   " findings=" (length findings))
        (for-each
          (lambda (finding)
            (displayln "|finding rule=" (type-finding-rule-id finding)
                       " severity=" (type-finding-severity finding)
                       " path=" (type-finding-path finding)
                       " message=" (type-finding-message finding)))
          findings)))
    (if (null? findings) 0 1)))
