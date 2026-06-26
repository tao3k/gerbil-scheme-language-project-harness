;;; -*- Gerbil -*-
;;; Build/install path contract tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        "../src/build-api/source-coverage"
        "../build-support/gslph-build")
(export build-install-test)

(def build-install-test
  (test-suite "gslph build install path contract"
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
    (test-case "clean removes package-local development launcher artifacts"
      (configure-build-root! (current-directory))
      (unless (file-exists? ".bin")
        (create-directory ".bin"))
      (let ((binpath (dev-launcher-binpath))
            (artifact (path-expand ".bin/gslph__exe.c" (current-directory))))
        (call-with-output-file binpath
          (lambda (out) (display "test launcher" out)))
        (call-with-output-file artifact
          (lambda (out) (display "test artifact" out)))
        (check (file-exists? binpath) => #t)
        (check (file-exists? artifact) => #t)
        (clean-target)
        (check (file-exists? binpath) => #f)
        (check (file-exists? artifact) => #f)))
    (test-case "gxtest entry files are discovered from default test root"
      (configure-build-root! (current-directory))
      (let (files (gxtest-test-files))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/parser-test.ss" files) ? true)
        (check (member "t/project-policy-test.ss" files) => #f)
        (check (member "t/policy/agent-source-scope-test.ss" files) => #f))
      (check (member "policy-test.ss" (gxtest-test-spec)) ? true))
    (test-case "gxtest build spec stays scoped to top-level test entries"
      (configure-build-root! (current-directory))
      (let (stage (gxtest-test-spec))
        (check (member "policy-test.ss" stage) ? true)
        (check (member "project-policy-test.ss" stage) => #f)
        (check (member "policy/agent-build-test.ss" stage) => #f)
        (check (member "unit/schema/conformance.ss" stage) => #f)
        (check (member "snapshot/policy.ss" stage) => #f)))
    (test-case "timing-sensitive gxtest files run outside parallel workers"
      (let (files ["t/bench-test.ss"
                   "t/benchmark-gate-test.ss"
                   "t/policy-test.ss"])
        (check (serial-gxtest-files files)
               => ["t/bench-test.ss" "t/benchmark-gate-test.ss"])
        (check (parallel-gxtest-files files)
               => ["t/policy-test.ss"])))
    (test-case "test phase receipts are machine parseable"
      (check (test-phase-receipt-line "run-gxtest" 1234)
             => "[gslph-test-phase] name=run-gxtest elapsedMicros=1234 elapsedMs=1\n"))
    (test-case "parallel gxtest worker count is bounded by file count"
      (let (workers (test-runner-worker-count 2))
        (check (>= workers 1) => #t)
        (check (<= workers 2) => #t)))
    (test-case "default package spec exposes downstream gxtest support"
      (configure-build-root! (current-directory))
      (let (stage (compile-spec #f #f #f))
        (check (member "parser/facade.ss" stage) ? true)
        (check (member "policy/facade.ss" stage) ? true)
        (check (member "types/facade.ss" stage) ? true)
        (check (member "build-api/source-coverage.ss" stage) ? true)
        (check (member "build-api/package-receipt.ss" stage) ? true)
        (check (member "policy/gxtest.ss" stage) ? true)))
    (test-case "binary bootstrap spec includes downstream gxtest support"
      (configure-build-root! (current-directory))
      (let (stage (compile-spec #f #f #t))
        (check (member "build-api/source-coverage.ss" stage) ? true)
        (check (member "build-api/package-receipt.ss" stage) ? true)
        (check (member "policy/gxtest.ss" stage) ? true)
        (check (member "policy/gxtest.ss"
                       (member "build-api/source-coverage.ss" stage))
               ? true)))
    (test-case "source coverage files follow the build declaration"
      (configure-build-root! (current-directory))
      (gslph-source-coverage
       roots: '("src" "build-support" "t")
       runtime-roots: '("src")
       exclude-directories: '("scenarios" "snapshots"))
      (let (files (gslph-source-coverage-files (current-directory)))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) ? true)
        (check (member "src/policy/gxtest.ss" files) ? true)
        (check (member "build-support/gslph-build.ss" files) ? true)))
    (test-case "source coverage loads from build.ss"
      (configure-build-root! (current-directory))
      (gslph-source-coverage roots: '("src"))
      (gslph-load-source-coverage (current-directory))
      (let (files (gslph-source-coverage-files (current-directory)))
        (check (member "build-support/gslph-build.ss" files) ? true)
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "src/policy/gxtest.ss" files) ? true)))))
