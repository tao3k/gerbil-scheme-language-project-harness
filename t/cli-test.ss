;;; -*- Gerbil -*-
;;; gerbil scheme harness CLI dispatcher policy.

(import :gerbil/gambit
        :std/test
        (only-in :std/srfi/13 string-contains)
        (only-in :std/sugar ormap)
        "../build-support/gslph-build"
        (only-in :cli-launcher provider-command-line-args)
        (only-in :commands/agent agent-main))
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
    (test-case "release build spec uses native exe linker root"
      (let (spec (compile-spec #f #t #f))
        (check (member "cli-release-linker.ss" spec) => #f)
        (check (member "cli-launcher.ss" spec) ? true)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-dev-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #f)))
    (test-case "release binary builds runtime module graph"
      (let (spec (cli-binary-build-spec #t))
        (check (member "cli-release-linker.ss" spec) => #f)
        (check (member "cli-launcher.ss" spec) ? true)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (member "parser/model.ss" spec) ? true)
        (check (member "policy/core.ss" spec) ? true)))
    (test-case "non-release binary build spec stays bootstrap scoped"
      (let (spec (cli-binary-build-spec #f))
        (check (member "cli-dev-linker.ss" spec) => #f)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-dev-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #t)
        (check (ormap (lambda (entry)
                        (match entry
                          ([optimized-exe: "cli-release-linker" bin: "gslph" . _] #t)
                          (_ #f)))
                      spec)
               => #f)
        (check (member "parser/model.ss" spec) => #f)
        (check (member "policy/core.ss" spec) => #f)))
    (test-case "default compile spec builds full harness and benchmark gate helper"
      (let (spec (compile-spec #f #f #f))
        (check (member "benchmark/gate.ss" spec) ? true)
        (check (member "parser/model.ss" spec) ? true)
        (check (member "policy/core.ss" spec) ? true)))
    (test-case "agent guide forwards section flags"
      (let (status #f)
        (let (output
              (with-output-to-string
                (lambda ()
                  (set! status (agent-main ["guide" "." "--poo"])))))
          (check status => 0)
          (check (and (string-contains output "poo-prototype-fixed-point") #t)
                 => #t)
          (check (and (string-contains output "GERBIL-SCHEME-AGENT-POLICY-026") #t)
                 => #t))))))
