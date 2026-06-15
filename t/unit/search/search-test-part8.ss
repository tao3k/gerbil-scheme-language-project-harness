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
(export search-test-part-8)
;; Json <- Table Key
(def (json-get table key)
  (hash-get table key))
;; SearchOutput <- (List XX)
(def (search-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (search-main args)))))))
    (check status => 0)
    output))
;; String <- (List String)
(def (guide-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (guide-main args)))))))
    (check status => 0)
    output))
;; InfoOutput <- (List XX)
(def (info-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (info-main args)))))))
    (check status => 0)
    output))
;; Boolean <- OutputPort Fragment
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; Boolean <- OutputPort
(def (guide-code-render-metadata-free? output)
  (not (or (contains? output "[guide")
           (contains? output "|primaryExemplar")
           (contains? output "|exemplar")
           (contains? output "|code begin")
           (contains? output "selector=")
           (contains? output "nextCommand=")
           (contains? output "\n|"))))
;; Boolean <- OutputPort Fragments
(def (check-output-contains output fragments)
  (for-each
   (lambda (fragment)
     (check (contains? output fragment) => #t))
   fragments))
;; SearchTest
;; TestSuite
(def search-test-part-8
  (test-suite "gerbil scheme harness search part 8"
    (test-case "structural owner output exposes higher-order facts"
          (let (output (search-output
                        ["structural"
                         "--owner" "t/fixtures/parser/higher-order.ss"
                         "--view" "seeds" "."]))
            (check-output-contains
             output
             ["[gerbil-search-structural-owner]"
              "owner=t/fixtures/parser/higher-order.ss"
              "|syntaxFact kind=function languageKind=lambda name=lambda"
              "role=anonymous-function"
              "operandCount=1"
              "arities=1"
              "kind=call languageKind=map name=map"
              "role=sequence-map"
              "kind=call languageKind=cut name=cut"
              "role=partial-application"
              "caller="])))
    (test-case "structural search exposes dependency adapter quality facts"
          (check-structural-index-dependency-adapter-facts))))
