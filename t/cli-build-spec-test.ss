;;; -*- Gerbil -*-
;;; CLI build specification contracts.

(import :gerbil/gambit
        :std/test
        (only-in :std/sugar ormap)
        "../src/build-api/native-build")
(export cli-build-spec-test)

;; : TestSuite
(def cli-build-spec-test
  (test-suite "gerbil scheme harness CLI build spec"
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
    (test-case "binary build spec includes fmt command"
      (let (spec (cli-binary-build-spec #f))
        (check (member "commands/fmt.ss" spec) ? true)))
    (test-case "default compile spec builds full harness and benchmark gate helper"
      (let (spec (compile-spec #f #f #f))
        (check (member "benchmark/gate.ss" spec) ? true)
        (check (member "parser/model.ss" spec) ? true)
        (check (member "policy/core.ss" spec) ? true)))))
