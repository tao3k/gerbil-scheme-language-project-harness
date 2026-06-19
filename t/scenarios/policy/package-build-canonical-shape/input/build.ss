#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import :std/make
        (only-in :std/misc/process invoke))

(def (compile-all!)
  (setenv "GERBIL_LOADPATH" "src:t")
  (make ["src/orders/core"] srcdir: (current-directory))
  (invoke "gxc" ["-exe" "-o" ".build/sample" "src/orders/core.ss"]))

(def (main . args)
  (compile-all!))
