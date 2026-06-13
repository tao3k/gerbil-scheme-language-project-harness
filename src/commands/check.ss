;;; -*- Gerbil -*-
;;; Check command adapter.

(import :gerbil/gambit
        :checker/facade
        :constants
        :parser/facade
        :protocol/json
        :std/sugar
        :support/args
        :types/facade)

(export check-main)

(def (check-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (index (collect-project root))
         (findings (run-type-checks/whitelist index '() whitelist))
         (status (type-status findings)))
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
        (for-each display-finding findings)))
    (if (equal? status "pass") 0 1)))

(def (display-finding finding)
  (displayln "|finding rule=" (type-finding-rule-id finding)
             " severity=" (type-finding-severity finding)
             " path=" (type-finding-path finding)
             " selector=" (or (type-finding-selector finding) "")
             " message=" (type-finding-message finding))
  (display-finding-details finding))

(def +finding-detail-keys+
  '(advice next keepNamedLetWhen requiredWitness kind name selector))

(def (display-finding-details finding)
  (let* ((details (type-finding-details finding))
         (parts (and details
                     (filter identity
                             (map (cut finding-detail-part details <>)
                                  +finding-detail-keys+))))
         (guide-parts (finding-guide-parts finding))
         (all-parts (append (or parts []) guide-parts)))
    (when (and all-parts (pair? all-parts))
      (display "|finding-detail")
      (for-each (lambda (part)
                  (display " ")
                  (display part))
                all-parts)
      (newline))))

(def (finding-guide-parts finding)
  (match (finding-guide-route (type-finding-rule-id finding))
    ([topic intent command]
     [(string-append "guideTopic=" topic)
      (string-append "guideIntent=" intent)
      (string-append "nextCommand=" command)])
    (_ [])))

(def (finding-guide-route rule)
  (cond
   ((equal? rule "GERBIL-SCHEME-AGENT-R009")
    ["functional-data-transform"
     "repair"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R009 --intent repair"])
   ((equal? rule "GERBIL-SCHEME-AGENT-R011")
    ["macro-runtime-source"
     "witness"
     "asp gerbil-scheme guide --code --rule GERBIL-SCHEME-AGENT-R011 --intent witness"])
   ((or (equal? rule "GERBIL-SCHEME-AGENT-R008")
        (equal? rule "GERBIL-SCHEME-AGENT-R012"))
    ["poo-policy"
     "repair"
     (string-append "asp gerbil-scheme guide --code --rule " rule " --intent repair")])
   (else #f)))

(def (finding-detail-part details key)
  (let (value (finding-detail-value details key))
    (and value
         (string-append (symbol->string key)
                        "="
                        (datum->display-string value)))))

(def (finding-detail-value details key)
  (with-catch
   (lambda (_) #f)
   (lambda () (hash-get details key))))

(def (datum->display-string value)
  (call-with-output-string "" (cut display value <>)))
