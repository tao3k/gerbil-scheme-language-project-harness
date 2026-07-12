;;; -*- Gerbil -*-
;;; Build/install path contract tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        "../src/build-api/build-path-contract"
        (only-in "../src/build-api/native-build"
                 cli-binary-module-spec
                 package-api-build-output-files)
        (only-in "../src/build-api/package-spec"
                 gslph-package-api-stage-specs)
        (only-in "../src/commands/guide-sections" guide-section-lines-for)
        (only-in "../src/constants" +help+))
(export build-install-test)

;; : TestSuite
(def build-install-test
  (test-suite "asp gerbil-scheme build install path contract"
    (test-case "build root configures package-local Gerbil path"
      (configure-build-root! (current-directory))
      (check (getenv "GERBIL_PATH")
             => (path-expand ".gerbil" (current-directory))))
    (test-case "install path is user-local bin"
      (configure-build-root! (current-directory))
      (check (install-launcher-binpath)
             => (path-expand ".local/bin/gslph" (getenv "HOME"))))
    (test-case "development binary path is package-local .bin"
      (configure-build-root! (current-directory))
      (check (dev-launcher-binpath)
             => (path-expand ".bin/gslph" (current-directory))))
    (test-case "bootstrap and release module closures exclude linker roots"
      (let* ((development-modules (cli-binary-module-spec #f))
             (release-modules (cli-binary-module-spec #t)))
        (for-each
          (lambda (module)
            (check (member module development-modules) => #f)
            (check (member module release-modules) => #f))
          '("commands/bench.ss" "commands/bench-light.ss"))
        (check (member "cli-dev-linker.ss" development-modules)
               => #f)
        (check (member "cli-release-linker.ss" development-modules)
               => #f)
        (check (member "cli-release-linker.ss" release-modules)
               => #f)
        (for-each
         (lambda (module)
           (check (member module release-modules) => #f))
         '("checker/arity.ss"
           "checker/core.ss"
           "checker/facade.ss"
           "checker/forms.ss"
           "checker/model.ss"
           "checker/types.ss"
           "checker/whitelist.ss"))
        (check (not (not (ormap (lambda (path)
                                  (string-contains path "commands/guide-sections.ssi"))
                                (package-api-build-output-files))))
               => #t)
        (check (string-contains +help+ "bench") => #f)
        (check (ormap (lambda (line) (string-contains line "bench"))
                      (guide-section-lines-for '()))
               => #f))
    (test-case "package test driver dependencies remain materialized"
      (let (modules (apply append (gslph-package-api-stage-specs)))
        (check (not (not (member "testing/commands.ss" modules))) => #t)
        (check (not (not (member "testing/project-build.ss" modules))) => #t)
        (check (not (not (member "build-api/project-build.ss" modules))) => #t)))
    (test-case "package bootstrap compiles native-build dependencies first"
      (let loop ((stages (gslph-package-api-stage-specs))
                 (index 0)
                 (package-build-index #f)
                 (native-build-index #f))
        (if (null? stages)
          (begin
            (check package-build-index => 0)
            (check (< package-build-index native-build-index) => #t))
          (let (stage (car stages))
            (loop (cdr stages)
                  (+ index 1)
                  (or package-build-index
                      (and (member "build-api/package-build.ss" stage) index))
                  (or native-build-index
                      (and (member "build-api/native-build.ss" stage) index))))))))
    (test-case "package runtime stage does not rewrite bootstrap controls"
      (let (modules (apply append (gslph-package-api-stage-specs)))
        (for-each
         (lambda (module)
           (check (member module modules) => #f))
         '("building/native-toolchain.ss"
           "building/model.ss"
           "building/std-builder.ss"
           "building/facade.ss"
           "building/declarative.ss"))))
  ))
