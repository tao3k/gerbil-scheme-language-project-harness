;;; -*- Gerbil -*-
;;; Build/install path contract tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        "../build-support/gslph-build")
(export build-install-test)

(def build-install-test
  (test-suite "gslph build install path contract"
    (test-case "install path is user-local bin"
      (configure-build-root! (current-directory))
      (check (install-launcher-binpath)
             => (path-expand ".local/bin/gslph" (getenv "HOME"))))
    (test-case "development binary path is package-local .bin"
      (configure-build-root! (current-directory))
      (check (dev-launcher-binpath)
             => (path-expand ".bin/gslph" (current-directory))))))
