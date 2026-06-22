#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/make make)
        (only-in :std/source this-source-file)
        (only-in :std/misc/path path-directory path-expand path-normalize))

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def bin-dir (path-expand ".bin" package-root))

;; Keep :std/make here instead of defbuild-script: Gerbil's defbuild-script
;; intentionally owns srcdir, while this package keeps modules under src/.
(make
  '("commands/search-prime-light"
    (optimized-exe: "search-light-launcher" bin: "gslph-search")
    (optimized-exe: "cli-launcher" bin: "gslph"))
  srcdir: source-root
  bindir: bin-dir
  parallelize: 0)
