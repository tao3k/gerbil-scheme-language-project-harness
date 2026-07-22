#!/usr/bin/env gxi
;;; -*- Gerbil -*-
;;; Build the complete workspace-owned gslph artifact consumed by ASP CAS.

(import (only-in :gerbil/gambit
                 current-directory
                 getenv)
        (only-in :std/make make)
        (only-in :std/misc/path path-expand path-normalize)
        (only-in :std/misc/process run-process/batch)
        (only-in "../src/build-api/release-modules"
                 cli-release-modules))
(export main)

(def +workspace-artifact-relative-root+
  "build/workspace-provider")

;; : (-> Path)
(def (workspace-artifact-root)
  (let* ((expected (path-normalize
                    (path-expand +workspace-artifact-relative-root+
                                 (current-directory))))
         (configured (getenv "GERBIL_PATH" #f))
         (actual (and configured
                      (path-normalize
                       (path-expand configured (current-directory))))))
    (unless (and actual (string=? actual expected))
      (error "workspace artifact root mismatch"
             actual
             expected))
    actual))

;; : (-> Void)
(def (install-workspace-dependencies!)
  (run-process/batch ["gxpkg" "deps" "--install"]))

;; : (-> Void)
(def (compile-workspace-runtime!)
  (make cli-release-modules
        srcdir: "src"
        prefix: "gslph/src"
        optimize: #f
        parallelize: 1))

;; : (-> Void)
(def (compile-workspace-launcher!)
  (make '((exe: "cli-install-linker" bin: "gslph"))
        srcdir: "src"
        prefix: "gslph/src"
        optimize: #f
        parallelize: 1))

;; : (-> Void)
(def (main . _)
  (let (artifact-root (workspace-artifact-root))
    (run-process/batch ["rm" "-rf" artifact-root])
    (install-workspace-dependencies!)
    (compile-workspace-runtime!)
    (compile-workspace-launcher!)))
