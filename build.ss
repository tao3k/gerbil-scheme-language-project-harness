#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/cli/multicall
        (only-in :std/misc/path directory-files)
        :std/source
        :std/sort
        :std/srfi/13
        (rename-in :gerbil/tools/gxtest (main gxtest-main))
        :clan/building)

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def test-root (path-expand "t" package-root))

;;; Boundary:
;;; - gxpkg owns dependency installation and package-local GERBIL_PATH.
;;; - clan/building owns source discovery and the source-root load path.
;;; - This package keeps Gerbil modules under src/, so the build environment
;;;   uses src/ as the native source directory instead of adding ad hoc runtime
;;;   load paths in CI or build-support.
(def spec all-gerbil-modules)

(%set-build-environment!
 (path-expand "build.ss" source-root)
 name: "gslph"
 deps: '("clan" "gerbil-poo")
 spec: spec)

(define-multicall-main)

(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))))

(def (top-level-test-files)
  (map (cut path-expand <> test-root)
       (filter top-level-test-file?
               (sort (directory-files test-root) string<?))))

(define-entry-point (test)
  (help: "Run the Gerbil harness test suite" getopt: [])
  (compile)
  (current-directory package-root)
  (add-load-path! source-root)
  (add-load-path! test-root)
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
