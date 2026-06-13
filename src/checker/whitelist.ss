;;; -*- Gerbil -*-
;;; Native call whitelist checks over parser-owned call facts.

(import :checker/model
        :parser/facade
        :std/srfi/13
        :std/sugar
        :types/findings)

(export load-call-whitelist
        run-whitelist-checks
        call-whitelist-finding)

(def (load-call-whitelist path)
  (call-with-input-file path
    (lambda (port)
      (let lp ((out '()))
        (let (line (read-line port))
          (if (eof-object? line)
            (reverse out)
            (let (trimmed (string-trim line))
              (if (or (string-empty? trimmed)
                      (string-prefix? ";" trimmed))
                (lp out)
                (lp (cons trimmed out))))))))))

(def (run-whitelist-checks index whitelist)
  (let (allowed (append whitelist (project-definition-names index)))
    (filter-map
     (lambda (call)
       (and (not (allowed-callee? (call-fact-callee call) allowed))
            (call-whitelist-finding call)))
     (project-calls index))))

(def (project-definition-names index)
  (map definition-name (project-definitions index)))

(def (allowed-callee? callee allowed)
  (member callee allowed))

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
