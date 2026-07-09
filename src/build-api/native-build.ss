;;; -*- Gerbil -*-
;;; Build runtime API for the asp gerbil-scheme package.

(import (only-in :std/make make)
        (only-in :std/misc/path path-directory path-expand path-normalize path-strip-directory)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        (only-in "./cli-gsc-options"
                 gslph-cli-gsc-options
                 gslph-cli-gsc-options-cache-key)
        (only-in "./source-coverage"
                 gslph-source-coverage-files
                 gslph-source-coverage-runtime-roots
                 gslph-source-coverage-exclude-directories)
        (only-in "./package-receipt"
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-status-line
                 gslph-package-build-receipt-write)
        (only-in "./launcher-receipt"
                 gslph-build-module-source-file
                 gslph-build-module-output-file
                 gslph-cli-launcher-build-current?
                 gslph-cli-launcher-build-receipt-status
                 gslph-ensure-cli-launcher-inputs!
                 gslph-ensure-install-launcher-inputs!
                 gslph-install-launcher-build-current?
                 gslph-install-launcher-build-receipt-status
                 gslph-write-cli-launcher-build-receipt!
                 gslph-write-install-launcher-build-receipt!)
        (only-in "./package-spec" gslph-package-api-spec)
        (only-in "./worker-count" build-worker-count sync-build-worker-count!)
        (only-in "./install-static-modules" cli-install-static-modules)
        :gerbil/gambit)
(export clean-target
        compile-target
        install-target
        compile-spec
        cli-binary-build-spec
        configure-build-root!
        dev-launcher-binpath
        install-launcher-binpath
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
        build-worker-count
        compile-package-api-if-stale
        sync-build-worker-count!
        write-package-api-build-receipt!
        package-build-spec)

;; : (Maybe Path)
(def package-root #f)

;; : (Maybe Path)
(def source-root #f)

;; : (Maybe Datum)
(def current-package-gerbil-modules-key #f)

;; : (Maybe (List ModulePath))
(def current-package-gerbil-modules #f)

;; : (Maybe String)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setup-local-pkg-env! #t)
  (set! source-root (path-expand "src" package-root))
  (set! current-package-gerbil-modules-key #f)
  (set! current-package-gerbil-modules #f)
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> Path (Maybe String))
(def (read-build-package-name root)
  ;; : (-> (List Any) (Maybe (U Symbol String)))
  (def (package-name-ref plist)
    (let lp ((rest plist))
      (if (and (pair? rest) (pair? (cdr rest)))
        (if (eq? (car rest) 'package:)
          (cadr rest)
          (lp (cddr rest)))
        #f)))
  (let* ((package-file (path-expand "gerbil.pkg" root))
         (plist (with-catch
                 (lambda (_) #f)
                 (lambda () (call-with-input-file package-file read))))
         (name (and plist (package-name-ref plist))))
    (cond
     ((symbol? name) (symbol->string name))
     ((string? name) name)
     (else #f))))

;; : (-> String String)
(def (package-output-prefix root-name)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  (string-append package-name "/" root-name))

;; : (-> String)
(def (package-root-output-prefix)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for build output prefix"))
  package-name)

;; : (-> String)
(def (source-output-prefix)
  (package-output-prefix "src"))

;; : (List ModulePath)
(def excluded-library-files
  '("cli.ss"
    "cli-dev-linker.ss"
    "cli-install-linker.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"))

;; : (-> Boolean String (List BuildSpec))
(def (cli-exe-spec optimized? root)
  [(append (if optimized?
             [optimized-exe: root bin: "gslph"]
             [exe: root bin: "gslph"])
           (gslph-cli-gsc-options package-root))])

;; : (-> Boolean (List BuildSpec))
(def (cli-dev-spec optimized?)
  (cli-exe-spec optimized? "cli-dev-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-release-spec optimized?)
  (cli-exe-spec optimized? "cli-release-linker"))

;; : (-> Boolean (List BuildSpec))
(def (cli-install-spec optimized?)
  (cli-exe-spec optimized? "cli-install-linker"))

;; : (-> (List ModulePath))
(def (cli-install-module-spec)
  (append cli-bootstrap-modules
          cli-install-static-modules))

;; : (List ModulePath)
(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search-workspace-scope-light.ss"
    "search-light-launcher.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

;; : (List ModulePath)
(def cli-release-static-modules
  '("cli-launcher.ss"))

;; : (List String)
(def +library-excluded-dirs+
  '("search-fast" "testing"))

;; : (List String)
(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-module-spec release?)
  (if release?
    (cli-release-module-spec)
    cli-bootstrap-modules))

;; : (-> (List BuildSpec))
(def (cli-release-module-spec)
  (append (runtime-library-spec)
          cli-release-static-modules))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-exe-spec release? optimized?)
  (if release?
    (cli-release-spec optimized?)
    (cli-dev-spec optimized?)))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-spec release? optimized?)
  (append (cli-binary-module-spec release?)
          (cli-binary-exe-spec release? optimized?)))

;; : (-> ModulePath Boolean)
(def (runtime-library-module? module)
  (and (not (member module excluded-library-files))
       (not (library-excluded-dir-module? module))))

;; : (-> ModulePath Boolean)
(def (library-excluded-dir-module? module)
  (let loop ((dirs +library-excluded-dirs+))
    (and (pair? dirs)
         (or (string-prefix? (string-append (car dirs) "/") module)
             (loop (cdr dirs))))))

;; : (-> ModulePath Boolean)
(def (library-module? module)
  (runtime-library-module? module))

;; : (-> (List BuildSpec))
(def (library-spec)
  (filter library-module? (all-package-gerbil-modules)))

;; : (-> (List BuildSpec))
(def (runtime-library-spec)
  (filter runtime-library-module? (all-package-gerbil-modules)))

;; : (-> (List BuildSpec))
(def (native-runtime-spec)
  '("src/build-api/install-static-modules.ss"
    "src/build-api/worker-count.ss"
    "src/build-api/cli-gsc-options.ss"
    "src/build-api/launcher-receipt.ss"
    "src/build-api/package-build.ss"
    "src/build-api/build-path-contract.ss"
    "src/testing/gxtest-smoke.ss"
    "src/testing/gxtest-runner.ss"
    "src/build-api/native-build.ss"))

;; : (-> [Path (List Path) (List String)])
(def (package-gerbil-modules-cache-key)
  (list package-root
        (gslph-source-coverage-runtime-roots)
        (coverage-excluded-directories)))

;; : (-> (List ModulePath))
(def (uncached-package-gerbil-modules)
  (apply append
         (map runtime-root-gerbil-modules
              (gslph-source-coverage-runtime-roots))))

;; : (-> (List ModulePath))
(def (all-package-gerbil-modules)
  (let (key (package-gerbil-modules-cache-key))
    (if (and current-package-gerbil-modules-key
             (equal? current-package-gerbil-modules-key key))
      current-package-gerbil-modules
      (let (modules (uncached-package-gerbil-modules))
        (set! current-package-gerbil-modules-key key)
        (set! current-package-gerbil-modules modules)
        modules))))

;; : (-> Path (Maybe ModulePath))
(def (source-runtime-module-path path)
  (let (prefix "src/")
    (and (string-prefix? prefix path)
         (substring path
                    (string-length prefix)
                    (string-length path)))))

;; : (-> (List ModulePath))
(def (source-runtime-modules)
  (filter (lambda (module) module)
          (map source-runtime-module-path
               (gslph-source-coverage-files package-root))))

;; : (-> Path (List ModulePath))
(def (runtime-root-gerbil-modules root)
  (cond
   ((string=? root "src")
    (source-runtime-modules))
   (else
    [])))

;; : (-> (List String))
(def (coverage-excluded-directories)
  (append +default-excluded-dirs+
          +library-excluded-dirs+
          (gslph-source-coverage-exclude-directories)))

;; : (-> (List BuildSpec))
(def (package-build-spec)
  (ensure-build-root!)
  (gslph-package-api-spec))

;; : (-> Path String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> PackageLibOutputRoot)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand ".gerbil/lib" package-root)))

;; : (-> PackageApiReceiptPath)
(def (package-api-build-receipt-path)
  (path-expand ".gerbil/build/package-api.receipt" package-root))

;; : (-> (List Path))
(def (build-module-source-file module)
  (gslph-build-module-source-file source-root module))

;; : (-> (List Path))
(def (build-module-output-file module)
  (gslph-build-module-output-file (package-api-output-root) module))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map build-module-source-file
       (package-build-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map build-module-output-file
       (package-build-spec)))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (gslph-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)
   expected-outputs: (package-api-build-output-files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Void)
(def (display-package-api-build-receipt-status status)
  (display (gslph-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Void)
(def (write-package-api-build-receipt!)
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (package-api-build-source-files)
     (package-api-build-output-files))))

;; : (-> Integer [Maybe (-> Void)] BuildReceiptStatus)
(def (compile-package-api-if-stale worker-count (compile-thunk #f))
  (let (status (package-api-build-receipt-status))
    (display-package-api-build-receipt-status status)
    (if (package-api-build-current? status)
      status
      (begin
        (if compile-thunk
          (compile-thunk)
          (make (package-build-spec)
            optimize: #f
            parallelize: worker-count
            prefix: (source-output-prefix)
            srcdir: source-root))
        (write-package-api-build-receipt!)
        (package-api-build-receipt-status)))))

;; : (-> (List ModulePath))
(def (install-launcher-source-modules)
  (append (cli-install-module-spec)
          '("cli-install-linker.ss")))

;; : (-> Boolean (List ModulePath))
(def (cli-launcher-source-modules release?)
  (append (cli-binary-module-spec release?)
          (list (if release?
                  "cli-release-linker.ss"
                  "cli-dev-linker.ss"))))

;; : (-> Boolean (List BuildSpec))
(def (build-spec release?)
  (if release?
    (cli-binary-spec #t #t)
    (library-spec)))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec #t #t))
   (binary? (cli-binary-spec #f #f))
   (else (gslph-package-api-spec))))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Void)
(def (compile-target verbose debug no-optimize optimized release full binary)
  (ensure-build-root!)
  (current-directory package-root)
  (let* ((build-optimize? (and optimized (not no-optimize)))
         (effective-release? release)
         (effective-optimized? optimized)
         (worker-count (sync-build-worker-count!)))
    (if (and (not full) (or release binary))
      (compile-cli-binary-if-stale (dev-launcher-binpath)
                                   verbose debug build-optimize?
                                   release effective-release? effective-optimized?
                                   worker-count)
      (make-target (compile-spec full release binary)
                   verbose debug build-optimize?
                   effective-release? effective-optimized?
                   worker-count))
     #!void))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean Integer BuildReceiptStatus)
(def (compile-cli-binary-if-stale binpath verbose debug build-optimize?
                                  release? effective-release?
                                  effective-optimized? worker-count)
  (let* ((inputs-path
          (gslph-ensure-cli-launcher-inputs!
           package-root
           release?
           build-optimize?
           effective-release?
           effective-optimized?
           (gslph-cli-gsc-options-cache-key)
           (gslph-cli-gsc-options package-root)))
         (status
          (gslph-cli-launcher-build-receipt-status
           package-root
           source-root
           (package-api-output-root)
           release?
           binpath
           inputs-path
           (cli-binary-module-spec release?)
           (cli-launcher-source-modules release?))))
    (display-package-api-build-receipt-status status)
    (if (gslph-cli-launcher-build-current? status)
      status
      (begin
        (compile-cli-binary binpath
                            verbose debug build-optimize?
                            release? effective-release?
                            effective-optimized? worker-count)
        (gslph-write-cli-launcher-build-receipt!
         package-root
         source-root
         (package-api-output-root)
         release?
         binpath
         inputs-path
         (cli-binary-module-spec release?)
         (cli-launcher-source-modules release?))
        (gslph-cli-launcher-build-receipt-status
         package-root
         source-root
         (package-api-output-root)
         release?
         binpath
         inputs-path
         (cli-binary-module-spec release?)
         (cli-launcher-source-modules release?))))))

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)

;; : (-> Boolean Boolean Boolean Boolean Boolean Void)
(def (install-target verbose debug no-optimize optimized release)
  (ensure-build-root!)
  (current-directory package-root)
  (let* ((install-release? (and (not no-optimize) (or release #t)))
         (install-optimized? (and (not no-optimize)
                                  (or optimized install-release?)))
         (build-optimize? (and install-optimized? (not no-optimize)))
         (worker-count (sync-build-worker-count!)))
    (compile-install-binary-if-stale (install-launcher-binpath)
                                     verbose debug build-optimize?
                                     install-release? install-optimized?
                                     worker-count)
    #!void))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Integer BuildReceiptStatus)
(def (compile-install-binary-if-stale binpath verbose debug build-optimize?
                                      effective-release? effective-optimized?
                                      worker-count)
  (let* ((inputs-path
          (gslph-ensure-install-launcher-inputs!
           package-root
           build-optimize?
           effective-release?
           effective-optimized?
           (gslph-cli-gsc-options-cache-key)
           (gslph-cli-gsc-options package-root)))
         (status
          (gslph-install-launcher-build-receipt-status
           package-root
           source-root
           (package-api-output-root)
           binpath
           inputs-path
           (cli-install-module-spec)
           (install-launcher-source-modules))))
    (display-package-api-build-receipt-status status)
    (if (gslph-install-launcher-build-current? status)
      status
      (begin
        (compile-install-binary binpath
                                verbose debug build-optimize?
                                effective-release? effective-optimized?
                                worker-count)
        (gslph-write-install-launcher-build-receipt!
         package-root
         source-root
         (package-api-output-root)
         binpath
         inputs-path
         (cli-install-module-spec)
         (install-launcher-source-modules))
        (gslph-install-launcher-build-receipt-status
         package-root
         source-root
         (package-api-output-root)
         binpath
         inputs-path
         (cli-install-module-spec)
         (install-launcher-source-modules))))))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-install-binary binpath verbose debug build-optimize?
                             effective-release? effective-optimized?
                             worker-count)
  (compile-binary-artifact
    binpath
    (cli-install-module-spec)
    (cli-install-spec build-optimize?)
    verbose debug build-optimize?
    effective-release? effective-optimized?
    worker-count))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-cli-binary binpath verbose debug build-optimize?
                         release? effective-release? effective-optimized?
                         worker-count)
  (compile-binary-artifact
    binpath
    (cli-binary-module-spec release?)
    (cli-binary-exe-spec release? build-optimize?)
    verbose debug build-optimize?
    effective-release? effective-optimized?
    worker-count))

;; : (-> Path (List BuildSpec) (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-binary-artifact binpath module-spec exe-spec
                              verbose debug build-optimize?
                              effective-release? effective-optimized?
                              worker-count)
  (make-target module-spec
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (cleanup-compile-exe-artifacts! binpath)
  (make-target/bindir exe-spec
                       verbose debug build-optimize?
                       effective-release? effective-optimized?
                      1
                      (path-directory binpath))
  (cleanup-compile-exe-artifacts! binpath)
  binpath)

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-build-spec release?)
  (cli-binary-spec release? #t))

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

;; : (-> DevLauncherBinPath)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> InstallLauncherBinPath)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> HomeDirectoryPath)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install gslph into $HOME/.local/bin")))

;; : (-> Path Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Integer Void)
(def (make-target spec verbose debug build-optimize?
                  effective-release? effective-optimized?
                  worker-count)
  (make spec
    verbose: (and verbose 9)
    debug: (and debug 'env)
    optimize: build-optimize?
    build-release: effective-release?
    build-optimized: effective-optimized?
    parallelize: worker-count
    prefix: (source-output-prefix)
    srcdir: source-root))

;; : (-> (List BuildSpec) Boolean Boolean Boolean Boolean Boolean Integer Path Void)
(def (make-target/bindir spec verbose debug build-optimize?
                         effective-release? effective-optimized?
                         worker-count bindir)
  (ensure-directory! bindir)
  (make spec
    verbose: (and verbose 9)
    debug: (and debug 'env)
    optimize: build-optimize?
    build-release: effective-release?
    build-optimized: effective-optimized?
    parallelize: worker-count
    bindir: bindir
    prefix: (source-output-prefix)
    srcdir: source-root))
