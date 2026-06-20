#!/usr/bin/env gxi
;;; -*- Gerbil -*-
(import :std/build-script)

(defbuild-script
  '("sample/lib"
    (exe: "sample/main" bin: "sample")))
