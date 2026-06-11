;;; -*- Gerbil -*-
;;; Check command adapter.

(import :checker
        :constants
        :parser
        :protocol/json
        :support/args)

(export check-main)

(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (index (collect-project root))
         (findings (run-checks index))
         (status (project-status findings)))
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
            (displayln "|finding rule=" (finding-rule-id finding)
                       " severity=" (finding-severity finding)
                       " path=" (finding-path finding)
                       " message=" (finding-message finding)))
          findings)))
    (if (null? findings) 0 1)))
