;;; -*- Gerbil -*-
;;; Native call whitelist checks over parser-owned call facts.

(import :checker/model
        :parser/facade
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13 string-empty? string-prefix? string-trim)
        (only-in :std/sugar filter-map)
        :types/findings)

(export load-call-whitelist
        run-whitelist-checks
        call-whitelist-finding)
;;; Boundary:
;;; - load-call-whitelist composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ParsedData <- String
(def (load-call-whitelist path)
  (filter-map whitelist-line-entry (read-file-lines path)))

;; MaybeWhitelistEntry <- SourceLine
(def (whitelist-line-entry line)
  (let (trimmed (string-trim line))
    (and (not (or (string-empty? trimmed)
                  (string-prefix? ";" trimmed)))
         trimmed)))

;;; Boundary:
;;; - run-whitelist-checks composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypeFinding) <- ProjectIndex Whitelist
(def (run-whitelist-checks index whitelist)
  (let (allowed (append whitelist (project-definition-names index)))
    (filter-map
     (lambda (call)
       (and (not (allowed-callee? (call-fact-callee call) allowed))
            (call-whitelist-finding call)))
     (project-calls index))))
;;; Boundary:
;;; - project-definition-names composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List String) <- ProjectIndex
(def (project-definition-names index)
  (map definition-name (project-definitions index)))
;; Boolean <- Callee Allowed
(def (allowed-callee? callee allowed)
  (member callee allowed))
;; TypeFinding <- CallFact
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
