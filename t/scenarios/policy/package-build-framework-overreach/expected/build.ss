#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import :std/make
        :clan/building
        (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage))

(gslph-source-coverage
 roots: '("src" "t")
 runtime-roots: '("src")
 explanation: "build.ss declares source coverage; acceleration and receipts stay in reusable harness APIs.")

(def (spec)
  (all-gerbil-modules))

(%set-build-environment!
 "build.ss"
 name: "sample"
 deps: '("gslph")
 spec: spec)

(def (compile-package! options)
  (apply make (spec) options))
