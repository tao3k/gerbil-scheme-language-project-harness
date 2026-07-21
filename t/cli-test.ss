;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :gslph/src/cli-launcher provider-command-line-args main)
        (only-in :gslph/src/cli-release-linker release-command-dispatch)
        (only-in :gslph/src/protocol/command-catalog
                 provider-command-names
                 provider-dynamic-command-dispatch))
(export cli-test)

;; : TestSuite
(def cli-test
  (test-suite "gerbil scheme harness CLI"
    (test-case "provider argv keeps direct subcommands"
      (check (provider-command-line-args
              ["search" "owner" "src/main.ss"])
             => ["search" "owner" "src/main.ss"]))
    (test-case "provider argv strips gxi launcher frames"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "query" "src/main.ss"])
             => ["query" "src/main.ss"]))
    (test-case "provider argv strips generated binary frames"
      (check (provider-command-line-args
              ["gslph" "fmt" "--check" "/tmp/project"])
             => ["fmt" "--check" "/tmp/project"]))
    (test-case "provider argv preserves help requests"
      (check (provider-command-line-args
              ["gslph" "--help"])
             => ["--help"]))
    (test-case "provider argv strips no-argument launcher frames"
      (check (provider-command-line-args
              ["gslph"])
             => []))
    (test-case "provider argv preserves unknown commands"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "bogus"])
             => ["bogus"]))
    (test-case "provider argv keeps formatter command"
      (check (provider-command-line-args
              ["gslph" "fmt" "--check" "."])
             => ["fmt" "--check" "."]))
    (test-case "command catalog owns dynamic and release command names"
      (check (map car provider-dynamic-command-dispatch)
             => provider-command-names)
      (check (map car release-command-dispatch)
             => provider-command-names)
      (check (andmap (lambda (entry) (procedure? (cadr entry)))
                     release-command-dispatch)
             => #t))
    ))
