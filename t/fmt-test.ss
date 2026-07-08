;;; -*- Gerbil -*-
;;; Formatter command contract tests.

(import :std/test
        (only-in :std/misc/path path-expand)
        :benchmark/framework
        :format/facade
        :support/io)

(export fmt-test)

(def +fmt-scenario-root+
  "t/scenarios/format/rs7-basic-style")

(def +fmt-scenario-input+
  (path-expand "input/main.ss" +fmt-scenario-root+))

(def +fmt-scenario-expected+
  (path-expand "expected/main.ss" +fmt-scenario-root+))

;; : (-> String)
(def (fmt-scenario-input-text)
  (read-source-text +fmt-scenario-input+))

;; : (-> String)
(def (fmt-scenario-expected-text)
  (read-source-text +fmt-scenario-expected+))

;; FmtTest
(def fmt-test
  (test-suite "gerbil scheme harness fmt"
    (test-case "scenario owns RS7 input and expected formatter style"
      (check (benchmark-contract-input-expected-pass?
              (path-expand "benchmark.ss" +fmt-scenario-root+))
             => #t)
      (check (benchmark-contract-valid/root? +fmt-scenario-root+)
             => #t)
      (check (fmt-format-text (fmt-scenario-input-text))
             => (fmt-scenario-expected-text)))
   (test-case "scenario benchmark keeps formatter core sub-millisecond"
      (let* ((input (fmt-scenario-input-text))
             (receipt
              (benchmark-contract-run/root
               +fmt-scenario-root+
               (lambda ()
                 (fmt-format-text input)))))
        (check (benchmark-contract-receipt-pass? receipt) => #t)))
    (test-case "default formatter target discovery skips scenario fixtures"
      (let (scenario-input "scenarios/format/rs7-basic-style/input/main.ss")
        (check (member scenario-input (fmt-target-files "t" []))
               => #f)
        (check (member scenario-input
                       (fmt-target-files "t" ["scenarios/format/rs7-basic-style/input"]))
               => (list scenario-input))))))
