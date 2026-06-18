;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :commands/guide
        :commands/info
        :commands/search
        :support/args
        :std/misc/ports
        (only-in :std/text/json read-json)
        :unit/poo/runtime-witness
        :unit/search/structural-index)
(export search-test-part-9)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> (List XX) SearchOutput )
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; : (-> (List String) String )
(def (guide-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (guide-main args)))))))
    (check status => 0)
    output))
;; : (-> (List XX) InfoOutput )
(def (info-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; : (-> OutputPort Boolean )
(def (guide-code-render-metadata-free? output)
  (not (or (contains? output "[guide")
           (contains? output "|primaryExemplar")
           (contains? output "|exemplar")
           (contains? output "|code begin")
           (contains? output "selector=")
           (contains? output "nextCommand=")
           (contains? output "\n|"))))
;; : (-> OutputPort Fragments Boolean )
(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))
;; SearchTest
;; TestSuite
(def search-test-part-9
  (test-suite "gerbil scheme harness search part 9"
    (test-case "capability search projects Gerbil engineering posture"
          (let (output (search-output ["capability" "posture" "."]))
            (check-output-contains
             output
             ["[gerbil-search-capability] query=posture"
              "authority=project-capability-posture"
              "|fact id=package-module-posture"
              "|capability name=package-module status=active"
              "|fact id=macro-posture"
              "|capability name=macro status=active policyRules=GERBIL-SCHEME-AGENT-R011"
              "|fact id=poo-posture"
              "|capability name=poo status=active policyRules=GERBIL-SCHEME-AGENT-R008,GERBIL-SCHEME-AGENT-R012"
              "|fact id=higher-order-posture"
              "|fact id=control-flow-posture"
              "|fact id=configurable-interface-posture"
              "|fact id=quality-closure-posture"
              "|capability name=quality-closure status=declared-closure"
              "|qualitySignal id=policy-covered"
              "|qualitySignal id=guide-covered"
              "|qualitySignal id=snapshot-covered"
              "|qualitySignal id=bench-covered"
              "|failureCase id=basic-scheme-fallback"])))
    (test-case "env search exposes active runtime witness"
          (let (output (search-output ["env" "gxi" "."]))
            (check (contains? output "evidenceGrade=fact") => #t)
            (check (contains? output "|runtime gerbilHome=") => #t)
            (check (contains? output "gxiExists=#t") => #t)
            (check (contains? output "gscExists=#t") => #t)
            (check (not (contains? output "pending")) => #t)))))
