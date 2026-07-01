;;; -*- Gerbil -*-
;;; Gxtest package build lifecycle helpers.

(import (only-in :std/misc/path path-directory path-expand path-strip-directory)
        (only-in "../build-api/package-spec"
                 gslph-package-api-spec)
        (only-in "./gxtest-context"
                 package-root
                 ensure-build-root!)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files)
        (only-in "./gxtest-receipts"
                 display-package-api-build-receipt-status
                 package-api-build-current?
                 package-api-build-receipt-status
                 selected-gxtest-build-current?
                 selected-gxtest-build-receipt-status
                 write-package-api-build-receipt!
                 write-selected-gxtest-build-receipt!)
        :gerbil/gambit)

(export clean-target
        compile-package-api-if-stale
        compile-selected-gxtest-if-stale
        compile-spec
        dev-launcher-binpath
        install-launcher-binpath)

;; : (-> Path)
(def (package-build-api-path)
  (path-expand "src/build-api/package-build.ss" package-root))

;; : (-> Void)
(def (load-package-build-api!)
  (let (root package-root)
    (load (package-build-api-path))
    (eval `(gslph-package-configure-build-root! ,root))))

;; : (-> Void)
(def (compile-package-api!)
  (load-package-build-api!)
  (eval '(gslph-package-compile-target #f #f #t #f #f)))

;; : (-> (List String))
(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search-workspace-scope-light.ss"
    "commands/search.ss"
    "commands/query.ss"
    "commands/check-cache.ss"
    "commands/check.ss"
    "commands/evidence.ss"
    "commands/agent.ss"
    "commands/guide.ss"
    "commands/info.ss"
    "search-light-launcher.ss"
    "build-api/source-coverage.ss"
    "build-api/package-receipt.ss"
    "policy/gxtest-report.ss"
    "policy/gxtest.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (cond
   ((or full? release?)
    (error "full and release compile specs are owned by native-build"))
   (binary? cli-bootstrap-modules)
   (else (gslph-package-api-spec))))

;; : (-> Integer Integer)
(def (compile-package-api-if-stale worker-count (compile-thunk #f))
  (let (status (package-api-build-receipt-status))
    (display-package-api-build-receipt-status status)
    (if (package-api-build-current? status)
      status
      (begin
        (if compile-thunk
          (compile-thunk)
          (compile-package-api!))
        (write-package-api-build-receipt!)
        (package-api-build-receipt-status)))))

;; : (-> (List Path) Integer Void)
(def (compile-selected-gxtest! files worker-count)
  (load-package-build-api!)
  (eval `(gslph-package-compile-gxtest-target
          ',(gxtest-selected-source-module-files files)
          ',(gxtest-selected-test-files files)
          ,worker-count)))

;; : (-> (List Path) Integer BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files worker-count)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-package-api-build-receipt-status status)
    (if (selected-gxtest-build-current? status)
      status
      (begin
        (compile-package-api-if-stale worker-count)
        (compile-selected-gxtest! files worker-count)
        (write-selected-gxtest-build-receipt! files)
        (selected-gxtest-build-receipt-status files)))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> Path)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install asp gerbil-scheme into $HOME/.local/bin")))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path Void)
(def (cleanup-compile-exe-artifacts! binpath)
  (let* ((bindir (path-directory binpath))
         (name (path-strip-directory binpath))
         (prefix (string-append name "__exe")))
    (for-each
     (lambda (suffix)
       (delete-file* (path-expand (string-append prefix suffix) bindir)))
     '(".c" "_.c" ".scm" ".o" "_.o"))))

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)
