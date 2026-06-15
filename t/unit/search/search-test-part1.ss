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
(export search-test-part-1)
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
(def search-test-part-1
  (test-suite "gerbil scheme harness search part 1"
    (test-case "POO partial upgrades have runtime witnesses"
          (check-poo-runtime-witnesses))
    (test-case "owner item marker is not treated as project root"
          (check (project-root ["src/checker/types.ss"
                                "items"
                                "--query"
                                "type-compatible"
                                "--names-only"])
                 => ".")
          (check (drop-project-root ["src/checker/types.ss"
                                     "items"
                                     "--query"
                                     "type-compatible"
                                     "--names-only"
                                     "."])
                 => ["src/checker/types.ss"
                     "items"
                     "--query"
                     "type-compatible"
                     "--names-only"]))
    (test-case "guide exposes gerbil-poo engineering pattern policies"
          (let (output (guide-output []))
            (check-output-contains
             output
             ["|policy gerbil-build-discovery=prefer :std/make + :clan/base + :clan/building all-gerbil-modules discovery"
              "|policy cli-option-composition=keep src/cli.ss as a thin dispatcher"
              "|policy protocol-surface-minimality=define the minimal protocol slot surface first"
              "|policy reusable-contract-tests=prefer small t/ owners that apply generic contract tests to type descriptors"
              "|policy poo-thin-macro-bridge=POO syntax macros such as brace/@method should stay thin syntax bridges"
              "|policy poo-slot-resolution=POO object edits must account for C3 precedence and lazy slot cache resolution"
              "|policy poo-serialization-method-family=json<-/<-json, marshal/unmarshal, bytes<-/<-bytes, and string<-/<-string should be modeled as method/type slots"])))))
