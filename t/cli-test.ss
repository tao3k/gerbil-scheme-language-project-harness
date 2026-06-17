;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :std/test
        (only-in :cli provider-command-line-args))
(export cli-test)

;; CliTest
(def cli-test
  (test-suite "gerbil scheme harness CLI"
    (test-case "provider argv keeps direct subcommands"
      (check (provider-command-line-args
              ["check" "--changed" "."])
             => ["check" "--changed" "."]))
    (test-case "provider argv strips gxi launcher frames"
      (check (provider-command-line-args
              ["gxi" "bin/gerbil-scheme-harness.ss" "check" "--changed" "."])
             => ["check" "--changed" "."]))
    (test-case "provider argv strips generated wrapper frames"
      (check (provider-command-line-args
              ["gerbil-scheme-harness" "check" "--full" "/tmp/project"])
             => ["check" "--full" "/tmp/project"]))
    (test-case "provider argv preserves help requests"
      (check (provider-command-line-args
              ["gerbil-scheme-harness" "--help"])
             => ["--help"]))
    (test-case "provider argv strips no-argument launcher frames"
      (check (provider-command-line-args
              ["gerbil-scheme-harness"])
             => []))
    (test-case "provider argv preserves unknown commands"
      (check (provider-command-line-args
              ["gxi" "bin/gerbil-scheme-harness.ss" "bogus"])
             => ["bogus"]))))

(run-tests! cli-test)
