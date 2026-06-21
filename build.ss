#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/cli/multicall
        (only-in :std/misc/path directory-files)
        (only-in :std/make make)
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
(def (spec)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory source-root))
      all-gerbil-modules
      (lambda () (current-directory previous-directory)))))

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
  (map (cut string-append "t/" <>)
       (filter top-level-test-file?
               (sort (directory-files test-root) string<?))))

;;; Test compile boundary:
;;; - Keep `test` self-contained by compiling the package before gxtest.
;;; - Use std/make directly here instead of re-entering the clan multicall
;;;   compile command; repeated child compiler runs have produced orphaned
;;;   code-70 exits on this workspace.
;;; - Gerbil's make documentation calls out parallel compiler rough edges under
;;;   memory pressure, so test compile fixes GERBIL_BUILD_CORES to 0.
(def (compile-for-test!)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory source-root))
      (lambda () (make (spec) srcdir: source-root parallelize: 0))
      (lambda () (current-directory previous-directory)))))

(define-entry-point (test)
  (help: "Run the Gerbil harness test suite" getopt: [])
  (compile-for-test!)
  (current-directory package-root)
  (add-load-path! source-root)
  (add-load-path! test-root)
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
