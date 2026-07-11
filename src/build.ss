;;; -*- Gerbil -*-
;;;
;;; Native source-root build declaration.  gxi evaluates this file directly;
;;; clan/building owns command dispatch and std/make owns compilation.

(import :clan/building)

(init-build-environment!
 spec: (lambda ()
         (append
          (all-gerbil-modules
           exclude: '("build.ss"
                      "cli-dev-linker.ss"
                      "cli-release-linker.ss"))
          '((exe: "cli-dev-linker" bin: "gslph")
            (exe: "cli-release-linker" bin: "gslph-release")))))
