;;; -*- Gerbil -*-
;;; Build/install path contract tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-expand)
        "../src/build-api/build-path-contract")
(export build-install-test)

;; : TestSuite
(def build-install-test
  (test-suite "asp gerbil-scheme build install path contract"
    (test-case "build root configures package-local Gerbil path"
      (configure-build-root! (current-directory))
      (check (getenv "GERBIL_PATH")
             => (path-expand ".gerbil" (current-directory))))
    (test-case "install path is user-local bin"
      (configure-build-root! (current-directory))
      (check (install-launcher-binpath)
             => (path-expand ".local/bin/gslph" (getenv "HOME"))))
    (test-case "development binary path is package-local .bin"
      (configure-build-root! (current-directory))
      (check (dev-launcher-binpath)
             => (path-expand ".bin/gslph" (current-directory))))))
