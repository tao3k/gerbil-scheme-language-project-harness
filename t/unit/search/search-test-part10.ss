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
(export search-test-part-10)
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
(def search-test-part-10
  (test-suite "gerbil scheme harness search part 10"
    (test-case "runtime-source search exposes ASP acquisition plan"
          (let (output (search-output ["runtime-source" "macro" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-source"
              "evidenceGrade=fact"
              "runtime-version-source"
              "active-runtime-version-to-source-acquisition-plan"
              "|sourceRef kind=runtime-version-source"
              "repository=https://git.cons.io/mighty-gerbils/gerbil"
              "checkoutPolicy=exact-tag-from-active-runtime"
              "statePathPolicy=asp-state-managed"
              "|acquisition owner=asp"
              "operation=clone-or-fetch-checkout-index"
              "stateNamespace=runtime-source/gerbil-scheme"
              "indexOwner=asp-structural-index"
              "|selectorResolver scheme=gerbil-runtime-source owner=asp stateNamespace=runtime-source/gerbil-scheme"
              "selectorFormat=gerbil-runtime-source://<source-path>#<symbol> output=code-with-comments"
              "|sourceExample id=std-sugar-defrule role=macro-rule symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
              "head=defrule operands=(<name> arg ...),body ... keywords=-"
              "|sourceExample id=std-sugar-defsyntax-call role=procedural-macro-call symbol=defsyntax-call selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
              "|sourceExample id=module-sugar-only-in role=import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
              "|sourceComment id=std-sugar-comment-boundary selector=gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"
              "fallback=comment-missing-is-signal"
              "|selector role=std-sugar-source symbol=defrule selector=gerbil-runtime-source://src/std/sugar.ss#defrule"
              "|selector role=module-sugar-import-filter symbol=only-in selector=gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"
              "clone-active-runtime-source-before-answering-language-or-macro-usage"
              "|failureCase id=memory-language-answer"
              "|failureCase id=wrong-runtime-version"
              "|failureCase id=unindexed-source-checkout"
              "|qualitySignal id=no-memory"
              "|qualitySignal id=version-matched-source"
              "|qualitySignal id=asp-state-managed-checkout"
              "|qualitySignal id=code-with-comments-output"
              "|qualitySignal id=selector-resolver-owned-by-asp"
              "|qualitySignal id=source-ranking-prefers-runtime-source"
              "|qualitySignal id=bootstrap-stubs-labelled"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output ".data")) => #t)
            (check (not (contains? output "pending")) => #t)))
    (test-case "runtime-source search routes std sugar to versioned source"
          (let (output (search-output ["runtime-source" "sugar" "."]))
            (check-output-contains
             output
             ["[gerbil-search-runtime-source]"
              "|fact id=gerbil-runtime-source"
              "repository=https://git.cons.io/mighty-gerbils/gerbil"
              "|qualitySignal id=source-index-required"
              "next=search runtime-source macro sugar module-sugar"])
            (check (not (contains? output "pending")) => #t)))))
