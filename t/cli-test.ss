;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        "../build-support/gslph-build"
        (only-in :cli-launcher provider-command-line-args)
        (only-in :commands/agent agent-main))
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
              ["gxi" "src/cli.ss" "check" "--changed" "."])
             => ["check" "--changed" "."]))
    (test-case "provider argv strips generated binary frames"
      (check (provider-command-line-args
              ["gslph" "check" "--full" "/tmp/project"])
             => ["check" "--full" "/tmp/project"]))
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
    (test-case "release build spec uses static linker root"
      (let (spec (compile-spec #f #t #f))
        (check (member "cli-release-linker.ss" spec) ? true)
        (check (member '(exe: "cli-release-linker" bin: "gslph") spec) ? true)
        (check (member '(exe: "cli-launcher" bin: "gslph") spec) => #f)))
    (test-case "agent guide forwards section flags"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status (agent-main ["guide" "." "--poo"])))))
          (check status => 0)
          (check (and (string-contains output "poo-prototype-fixed-point") #t)
                 => #t)
          (check (and (string-contains output "GERBIL-SCHEME-AGENT-R026") #t)
                 => #t))))))

(run-tests! cli-test)
