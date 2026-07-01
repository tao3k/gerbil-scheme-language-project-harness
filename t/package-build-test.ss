;;; -*- Gerbil -*-
;;; Package build API behavior tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-directory path-expand)
        "../src/build-api/package-build")

(export package-build-test)

(def +package-build-test-root+
  (path-expand ".cache/agent-semantic-protocol/test/package-build"
               (current-directory)))

(def (with-gerbil-path value thunk)
  (let ((previous-path (getenv "GERBIL_PATH"))
        (previous-directory (current-directory)))
    (dynamic-wind
      (lambda ()
        (setenv "GERBIL_PATH" value))
      thunk
      (lambda ()
        (setenv "GERBIL_PATH" (or previous-path ""))
        (current-directory previous-directory)))))

(def (package-build-test-ensure-directory! path)
  (when (and path
             (not (string=? path ""))
             (not (string=? path "."))
             (not (file-exists? path)))
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent path)))
        (package-build-test-ensure-directory! parent)))
    (unless (file-exists? path)
      (create-directory path))))

(def package-build-test
  (test-suite "package build api"
    (test-case "uses caller GERBIL_PATH for dependency build artifacts"
      (let* ((package-root (path-expand "linked-package" +package-build-test-root+))
             (consumer-gerbil-path
              (path-expand "consumer/.gerbil" +package-build-test-root+))
             (expected (path-expand consumer-gerbil-path)))
        (with-gerbil-path
         consumer-gerbil-path
         (lambda ()
           (check (gslph-package-build-active-gerbil-path package-root)
                  => expected)
           (check (gslph-package-build-active-gerbil-lib-path package-root)
                  => (path-expand "lib" expected))))))
    (test-case "package build lock uses caller GERBIL_PATH and releases"
      (let* ((package-root (path-expand "lock-package" +package-build-test-root+))
             (consumer-gerbil-path
              (path-expand "lock-consumer/.gerbil" +package-build-test-root+)))
        (package-build-test-ensure-directory! package-root)
        (package-build-test-ensure-directory! consumer-gerbil-path)
        (with-gerbil-path
         consumer-gerbil-path
         (lambda ()
           (gslph-package-configure-build-root! package-root)
           (let (lock-path (gslph-package-build-lock-path package-root))
             (check lock-path
                    => (path-expand "build/gslph-package.lock"
                                    consumer-gerbil-path))
             (check (file-exists? lock-path) => #f)
             (check (gslph-package-build-with-lock
                     (lambda ()
                       (check (file-exists? lock-path) => #t)
                       'locked))
                    => 'locked)
             (check (file-exists? lock-path) => #f))))))
    (test-case "falls back to package local GERBIL_PATH when caller path is absent"
      (let* ((package-root (path-expand "standalone-package"
                                        +package-build-test-root+))
             (expected (path-expand ".gerbil" package-root)))
        (with-gerbil-path
         ""
         (lambda ()
           (check (gslph-package-build-active-gerbil-path package-root)
                  => expected)
           (check (gslph-package-build-active-gerbil-lib-path package-root)
                  => (path-expand "lib" expected))))))))
