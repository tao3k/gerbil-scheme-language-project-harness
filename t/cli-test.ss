;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :cli-launcher provider-command-line-args main))
(export cli-test)

;; : TestSuite
(def cli-test
  (test-suite "gerbil scheme harness CLI"
    (test-case "provider argv keeps direct subcommands"
      (check (provider-command-line-args
              ["check" "--changed" "."])
             => ["check" "--changed" "."]))
    (test-case "provider argv strips gxi launcher frames"
      (check (provider-command-line-args
              ["gxi" "src/cli.ss" "check" "--changed" "."])
             => ["check" "--changed" "."]))
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
    (test-case "check full is removed from CLI surface"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status (main "check" "--full" ".")))))
          (check status => 2)
          (check (and (string-contains output "removed-cli-full") #t)
                 => #t))))))
