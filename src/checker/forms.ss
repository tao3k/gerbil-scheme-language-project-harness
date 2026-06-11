;;; -*- Gerbil -*-
;;; Forbidden form checks over parser-owned top-level forms.

(import :checker/model
        :parser/facade
        :types/findings)

(export +forbidden-form-heads+
        run-forbidden-form-checks
        forbidden-form-finding)

(def +forbidden-form-heads+
  '("define-syntax" "syntax-case" "defsyntax" "defrules"))

(def (run-forbidden-form-checks index)
  (filter-map
   (lambda (form)
     (and (member (top-form-head form) +forbidden-form-heads+)
          (forbidden-form-finding form)))
   (apply append (map source-file-forms (project-index-files index)))))

(def (forbidden-form-finding form)
  (let ((head (top-form-head form))
        (selector (top-form-selector form)))
    (make-type-finding
     (checker-rule-id +forbidden-form-rule+)
     (checker-rule-severity +forbidden-form-rule+)
     (top-form-path form)
     (string-append "forbidden Scheme form " head
                    " is not allowed in generated code")
     selector
     (hash (form head)
           (selector selector)))))
