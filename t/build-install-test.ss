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
    (test-case "install path is user-local bin"
      (configure-build-root! (current-directory))
      (check (install-launcher-binpath)
             => (path-expand ".local/bin/gslph" (getenv "HOME"))))
    (test-case "development binary path is package-local .bin"
      (configure-build-root! (current-directory))
      (check (dev-launcher-binpath)
             => (path-expand ".bin/gslph" (current-directory))))
    (test-case "gxtest entry files are discovered from default test root"
      (configure-build-root! (current-directory))
      (let (files (gxtest-test-files))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/parser-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) => #f))
      (check (member "policy-test.ss" (gxtest-test-spec)) ? true))
    (test-case "gxtest policy warning files stay within gxtest scope"
      (configure-build-root! (current-directory))
      (gslph-source-coverage
       roots: '("src" "build-support" "t")
       runtime-roots: '("src")
       exclude-directories: '("scenarios" "snapshots"))
      (let (files (gxtest-policy-warning-files))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/parser-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) => #f)
        (check (member "src/policy/gxtest.ss" files) => #f)
        (check (member "build-support/gslph-build.ss" files) => #f)))
    (test-case "project policy warning files use source coverage declaration"
      (configure-build-root! (current-directory))
      (gslph-source-coverage
       roots: '("src" "build-support" "t")
       runtime-roots: '("src")
       exclude-directories: '("scenarios" "snapshots"))
      (let (files (project-policy-warning-files))
        (check (member "t/policy-test.ss" files) ? true)
        (check (member "t/policy/agent-source-scope-test.ss" files) ? true)
        (check (member "src/policy/gxtest.ss" files) ? true)
        (check (member "build-support/gslph-build.ss" files) ? true)))))
