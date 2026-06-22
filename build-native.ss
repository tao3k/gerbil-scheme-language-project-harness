#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/make make)
        (only-in :std/source this-source-file)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        :clan/building)

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def bin-dir (path-expand ".bin" package-root))
(def launcher-spec
  '((optimized-exe: "search-light-launcher" bin: "gslph-search")
    (optimized-exe: "cli-launcher" bin: "gslph")))
(def launcher-modules
  '("search-light-launcher" "search-light-launcher.ss"
    "cli-launcher" "cli-launcher.ss"))
(def (source-module? module)
  (not (member module launcher-modules)))

(def (source-spec)
  (let (previous-directory (current-directory))
    (dynamic-wind
      (lambda () (current-directory source-root))
      (lambda () (filter source-module? (all-gerbil-modules)))
      (lambda () (current-directory previous-directory)))))

;; Keep :std/make here instead of defbuild-script: Gerbil's defbuild-script
;; intentionally owns srcdir, while this package keeps modules under src/.
(make
  (append (source-spec) launcher-spec)
  srcdir: source-root
  bindir: bin-dir
  parallelize: 0)
