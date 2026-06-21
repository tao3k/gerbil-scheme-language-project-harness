#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :gerbil/gambit
        (only-in :std/make make)
        (only-in :std/source this-source-file)
        (only-in :std/misc/path path-directory path-expand path-normalize))

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def bin-dir (path-expand ".bin" package-root))

(def (darwin-system?)
  (memq 'apple (system-type)))

(def (assert-static-supported!)
  (when (darwin-system?)
    (error "static Gerbil executable builds are unsupported on Darwin; use build-native.ss")))

;; Keep :std/make here instead of defbuild-script: Gerbil's defbuild-script
;; intentionally owns srcdir, while this package keeps modules under src/.
(assert-static-supported!)

(make
  '((optimized-static-exe: "cli-launcher" bin: "gslph"))
  srcdir: source-root
  bindir: bin-dir
  parallelize: 0)
