#!/usr/bin/env gxi
;;; -*- Gerbil -*-
(import :std/make)

(def spec
  '((gsc: "ffi/_nono"
          "-cc-options" "-Iffi"
          "-ld-options" "-lnono")
    (ssi: "ffi/_nono")
    "ffi/nono"))

(make spec srcdir: (current-directory))
