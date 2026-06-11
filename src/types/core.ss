;;; -*- Gerbil -*-
;;; Type-check dispatch for Gerbil source projects.

(import :parser
        :types/findings)

(export type-status
        run-type-checks
        source-file-type-findings)

(def (type-status findings)
  (if (null? findings) "pass" "fail"))

(def (run-type-checks index)
  (apply append (map source-file-type-findings (project-index-files index))))

(def (source-file-type-findings file)
  (let (error (source-file-parse-error file))
    (if error
      [(make-type-finding "GERBIL-SCHEME-READ-R001"
                          "error"
                          (source-file-path file)
                          error
                          (source-file-path file)
                          #f)]
      '())))
