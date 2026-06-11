;;; -*- Gerbil -*-
;;; Check command adapter.

(import :constants
        :parser
        :protocol/json
        :support/args)

(export check-main)

(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (index (collect-project root))
         (errors (filter source-file-parse-error (project-index-files index)))
         (status (if (null? errors) "pass" "fail")))
    (if json?
      (write-json-line
       (hash (schemaId "agent.semantic-protocols.gerbil-scheme-harness-report")
             (schemaVersion "1")
             (languageId +language-id+)
             (providerId +provider-id+)
             (status status)
             (files (length (project-index-files index)))
             (definitions (length (project-definitions index)))
             (findings (map parse-error-json errors))))
      (begin
        (displayln "[gerbil-check] status=" status
                   " files=" (length (project-index-files index))
                   " definitions=" (length (project-definitions index))
                   " findings=" (length errors))
        (for-each
          (lambda (file)
            (displayln "|finding rule=GERBIL-SCHEME-READ-R001 path="
                       (source-file-path file)
                       " message=" (source-file-parse-error file)))
          errors)))
    (if (null? errors) 0 1)))
