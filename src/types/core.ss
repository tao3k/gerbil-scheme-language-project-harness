;;; -*- Gerbil -*-
;;; Type-check dispatch for Gerbil source projects.

(import :parser
        :types/env
        :types/findings)

(export type-status
        run-type-checks
        source-file-type-findings)

(def (type-status findings)
  (if (null? findings) "pass" "fail"))

(def (run-type-checks index)
  (append
   (apply append (map source-file-type-findings (project-index-files index)))
   (type-env-findings (build-type-env index))))

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

(def (type-env-findings bindings)
  (map duplicate-binding-finding (duplicate-type-bindings bindings)))

(def (duplicate-binding-finding duplicate)
  (let ((binding (car duplicate))
        (prior (cadr duplicate)))
    (make-type-finding "GERBIL-SCHEME-TYPE-E001"
                       "error"
                       (type-binding-path binding)
                       (string-append "duplicate type binding for " (type-binding-name binding))
                       (type-binding-selector binding)
                       (hash (firstSelector (type-binding-selector prior))
                             (duplicateSelector (type-binding-selector binding))))))
