#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/misc/process invoke))

(def (compile-all!)
  (invoke "gxc" ["-exe" "-o" ".build/sample" "src/main.ss"]))

(def (main . args)
  (compile-all!))
