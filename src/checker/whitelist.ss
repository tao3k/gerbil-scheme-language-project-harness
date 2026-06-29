;;; -*- Gerbil -*-
;;; Native call whitelist checks over parser-owned call facts.

(import :checker/model
        :parser/model
        (only-in :parser/selectors
                 call-fact-selector
                 project-calls
                 project-definitions)
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13 string-empty? string-prefix? string-trim)
        (only-in :std/sugar filter-map)
        :types/findings)

(export load-call-whitelist
        run-whitelist-checks
        call-whitelist-finding)
;; load-call-whitelist
;;   : (-> String (List String))
;;   | doc m%
;;       `load-call-whitelist path` reads non-empty, non-comment whitelist
;;       entries from a line-oriented whitelist file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (load-call-whitelist ".asp-call-whitelist")
;;       ;; => allowed callees
;;       ```
;;     %
(def (load-call-whitelist path)
  (filter-map whitelist-line-entry (read-file-lines path)))

;; : (-> SourceLine MaybeWhitelistEntry )
(def (whitelist-line-entry line)
  (let (trimmed (string-trim line))
    (and (not (or (string-empty? trimmed)
                  (string-prefix? ";" trimmed)))
         trimmed)))

;; run-whitelist-checks
;;   : (-> ProjectIndex (List String) (List TypeFinding))
;;   | doc m%
;;       `run-whitelist-checks index whitelist` reports calls whose callee is
;;       neither whitelisted nor defined in the current project.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-whitelist-checks index whitelist)
;;       ;; => whitelist findings
;;       ```
;;     %
(def (run-whitelist-checks index whitelist)
  (let (allowed (append whitelist (project-definition-names index)))
    (filter-map
     (lambda (call)
       (and (not (allowed-callee? (call-fact-callee call) allowed))
            (call-whitelist-finding call)))
     (project-calls index))))
;; project-definition-names
;;   : (-> ProjectIndex (List String))
;;   | doc m%
;;       `project-definition-names index` returns every definition name known to
;;       the project index.
;;
;;       # Examples
;;
;;       ```scheme
;;       (project-definition-names index)
;;       ;; => ("main" "helper")
;;       ```
;;     %
(def (project-definition-names index)
  (map definition-name (project-definitions index)))
;; : (-> Callee Allowed Boolean )
(def (allowed-callee? callee allowed)
  (member callee allowed))
;; : (-> CallFact TypeFinding )
(def (call-whitelist-finding call)
  (let (selector (call-fact-selector call))
    (make-type-finding
     (checker-rule-id +whitelist-rule+)
     (checker-rule-severity +whitelist-rule+)
     (call-fact-path call)
     (string-append "call to " (call-fact-callee call)
                    " is not in the native call whitelist")
     selector
     (hash (callee (call-fact-callee call))
           (selector selector)))))
