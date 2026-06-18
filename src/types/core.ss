;;; -*- Gerbil -*-
;;; Type-check dispatch for Gerbil source projects.

(import :checker/facade
        :parser/facade
        :policy/facade
        (only-in :std/sugar hash ormap)
        :types/env
        :types/findings)

(export type-status
        run-type-checks
        run-type-checks/signatures
        run-type-checks/whitelist
        source-file-type-findings)
;;; Boundary:
;;; - type-status composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) Status )
(def (type-status findings)
  (if (ormap non-info-finding? findings) "fail" "pass"))
;; : (-> TypeFinding Boolean )
(def (non-info-finding? finding)
  (not (equal? (type-finding-severity finding) "info")))
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-type-checks index)
  (run-type-checks/signatures index '()))
;; : (-> ProjectIndex NativeSignatures (List TypeFinding) )
(def (run-type-checks/signatures index signatures)
  (run-type-checks/whitelist index signatures '()))
;;; Boundary:
;;; - run-type-checks/whitelist composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> ProjectIndex NativeSignatures Whitelist (List TypeFinding) )
(def (run-type-checks/whitelist index signatures whitelist)
  (append
   (apply append (map source-file-type-findings (project-index-files index)))
   (type-env-findings (build-type-env/signatures index signatures))
   (run-checker-checks/whitelist index signatures whitelist)
   (run-policy-checks index)))
;; : (-> SourceFile (List TypeFinding) )
(def (source-file-type-findings file)
  (let (error (source-file-parse-error file))
    (if error
      [(make-type-finding "GERBIL-SCHEME-READ-R001"
                          "error"
                          (source-file-path file)
                          error
                          (read-error-selector file)
                          (read-error-diagnostic-details file error))]
      '())))

;;; Read errors block every downstream parser fact, so the finding has to be
;;; usable by an agent without re-reading the whole file.  The selector is a
;;; conservative file range until native reader exceptions expose exact columns.
;; : (-> SourceFile Selector )
(def (read-error-selector file)
  (let ((path (source-file-path file))
        (line-count (source-file-line-count file)))
    (if (> line-count 0)
      (string-append path ":1-" (number->string line-count))
      path)))

;;; Diagnostic projection boundary:
;;; - This layer formats reader failures for agents; it does not reinterpret
;;;   Gerbil syntax or retry parsing.
;;; - `file-range-fallback` is explicit so a later native line/column extractor
;;;   can tighten the location without changing the packet contract.
;; : (-> SourceFile String Json )
(def (read-error-diagnostic-details file error)
  (let* ((path (source-file-path file))
         (line-count (source-file-line-count file))
         (line-end (if (> line-count 0) line-count 1))
         (selector (read-error-selector file)))
    (hash (schema "gerbil-read-diagnostic-v1")
          (diagnosticKind "read-error")
          (category "syntax")
          (source "native-reader-exception")
          (path path)
          (selector selector)
          (location
           (hash (path path)
                 (lineStart 1)
                 (lineEnd line-end)
                 (columnStart 1)
                 (columnEnd #f)
                 (precision "file-range-fallback")))
          (rawMessage error)
          (agentInstruction
           "read errors block parser facts; repair this syntax issue before semantic checks")
          (nextAction "open selector and fix reader syntax")
          (successCriteria ["parse-source-file returns no parse-error"
                            "asp gerbil-scheme check reports no GERBIL-SCHEME-READ-R001"]))))
;;; Boundary:
;;; - type-env-findings composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List TypeFinding) (List TypeFinding) )
(def (type-env-findings bindings)
  (map duplicate-binding-finding (duplicate-type-bindings bindings)))
;; : (-> Duplicate TypeFinding )
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
