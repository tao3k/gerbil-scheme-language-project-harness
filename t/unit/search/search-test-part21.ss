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
(export search-test-part-21)
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
(def search-test-part-21
  (test-suite "gerbil scheme harness search part 21"
    (test-case "structural index packet satisfies IFC envelope"
          (check-structural-index-required-envelope))
    (test-case "structural index exposes queryable owner symbol dependency facts"
          (check-structural-index-queryable-facts))))
