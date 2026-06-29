#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/make
        :clan/base
        :clan/building)

;;; Package build shape follows gerbil-poo: clan/building owns source discovery
;;; and the build load path; spec only adds project-specific helper modules.
(def (spec)
  (!> (all-gerbil-modules)
      (cut cons "t/unit/build-runtime" <>)))

(init-build-environment!
 name: "sample-package"
 deps: '("clan")
 spec: spec)
