;;; -*- Gerbil -*-
;;; Checker-owned facts and rules for Gerbil source projects.

(import :parser)

(export finding-rule-id
        finding-severity
        finding-path
        finding-message
        finding-selector
        finding-details
        project-status
        run-checks
        source-file-findings)

(defstruct finding (rule-id severity path message selector details))

(def (project-status findings)
  (if (null? findings) "pass" "fail"))

(def (run-checks index)
  (apply append (map source-file-findings (project-index-files index))))

(def (source-file-findings file)
  (let (error (source-file-parse-error file))
    (if error
      [(make-finding "GERBIL-SCHEME-READ-R001"
                     "error"
                     (source-file-path file)
                     error
                     (source-file-path file)
                     #f)]
      '())))
