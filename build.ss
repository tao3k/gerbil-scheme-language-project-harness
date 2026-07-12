#!/usr/bin/env gxi
;;; -*- Gerbil -*-

(import
 :clan/building
 :std/build-script
 :std/source)

(defbuild-script
 (all-gerbil-modules
  exclude: '("manifest.ss"
             "version.ss"
             "policy/modularity.ss"
             "src/cli-dev-linker.ss"
             "src/cli-release-linker.ss"
             "src/cli-install-linker.ss"))
 parallelize: 0)
