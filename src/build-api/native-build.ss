;;; -*- Gerbil -*-
;;; Build runtime API for the asp gerbil-scheme package.
;;; Build support for the gslph package.

(import (only-in :std/make make)
        (only-in :std/misc/path path-directory path-expand path-normalize path-strip-directory)
        (only-in :std/misc/process run-process)
        (only-in :std/srfi/13 string-suffix? string-tokenize)
        (only-in :clan/building all-gerbil-modules)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        "./source-coverage"
        "./package-receipt"
        "./package-spec"
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

(def package-root #f)
(def source-root #f)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setup-local-pkg-env! #t)
  (set! source-root (path-expand "src" package-root))
  (set! package-name (read-build-package-name package-root)))

;; : (-> Void)
(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

;; : (-> Path MaybeString)
(def (read-build-package-name root)
  (let* ((package-file (path-expand "gerbil.pkg" root))
         (plist (with-catch
                 (lambda (_) #f)
                 (lambda () (call-with-input-file package-file read))))
         (name (and plist (plist-ref plist 'package: #f))))
    (cond
     ((symbol? name) (symbol->string name))
     ((string? name) name)
     (else #f))))

;; : (-> List Symbol Datum Datum)
(def (plist-ref plist key default)
  (let lp ((rest plist))
    (if (and (pair? rest) (pair? (cdr rest)))
      (if (eq? (car rest) key)
        (cadr rest)
        (lp (cddr rest)))
      default)))

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

(def excluded-library-files
  '("cli.ss"
    "cli-dev-linker.ss"
    "cli-install-linker.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"))

(def (cli-exe-spec type root)
  [(append [type root bin: "gslph"]
           (cli-gsc-options))])

(def (cli-dev-spec)
  (cli-exe-spec optimized-exe: "cli-dev-linker"))

(def (cli-release-spec)
  (cli-exe-spec optimized-exe: "cli-release-linker"))

(def (cli-install-spec)
  (cli-exe-spec optimized-exe: "cli-install-linker"))

(def (cli-install-module-spec)
  (append cli-bootstrap-modules
          cli-install-static-modules))

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
    "policy/gxtest.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

(def cli-release-static-modules
  '("cli-launcher.ss"))

(def +library-excluded-dirs+
  '("search-fast"))

(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

;; : (-> (Or String False))
(def (openssl-prefix)
  (or (getenv "OPENSSL_DIR" #f)
      (getenv "OPENSSL_ROOT_DIR" #f)))

;; : (-> (List String) (List String))
(def (pkg-config-openssl-options args)
  (let (status 0)
    (with-catch
     (lambda (_) [])
     (lambda ()
       (let (output
             (run-process (append ["pkg-config"] args ["openssl"])
                          stderr-redirection: #t
                          check-status:
                          (lambda (exit-status _settings)
                            (set! status exit-status))))
         (if (zero? status)
           (string-tokenize output)
           []))))))

;; : (-> (List String))
(def (openssl-prefix-cc-options)
  (let (prefix (openssl-prefix))
    (if prefix
      [(string-append "-I" prefix "/include")]
      [])))

;; : (-> (List String))
(def (openssl-prefix-ld-options)
  (let (prefix (openssl-prefix))
    (if prefix
      [(string-append "-L" prefix "/lib")]
      [])))

;; : (-> (List String))
(def (openssl-cc-options)
  (let (options (pkg-config-openssl-options ["--cflags"]))
    (if (null? options)
      (openssl-prefix-cc-options)
      options)))

;; : (-> (List String))
(def (openssl-ld-options)
  (let (options (pkg-config-openssl-options ["--libs"]))
    (if (null? options)
      (append (openssl-prefix-ld-options)
              '("-lssl" "-lcrypto"))
      options)))

;; : (-> (List String) String)
(def (join-gsc-options options)
  (match options
    ([] "")
    ([option] option)
    ([option . rest]
     (string-append option " " (join-gsc-options rest)))))

;; : (-> String (List String) (List String))
(def (gsc-option flag options)
  (if (null? options)
    []
    [flag (join-gsc-options options)]))

(def +cli-gsc-options-cache+ #f)

;; Keep pkg-config out of module load/import. Most tests only inspect build
;; contracts; OpenSSL flags are needed only when a CLI binary spec is built.
(def (cli-gsc-options)
  (or +cli-gsc-options-cache+
      (let (options
            (append (gsc-option "-cc-options" (openssl-cc-options))
                    (gsc-option "-ld-options" (openssl-ld-options))))
        (set! +cli-gsc-options-cache+ options)
        options)))

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
(def (cli-binary-exe-spec release?)
  (if release?
    (cli-release-spec)
    (cli-dev-spec)))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-spec release?)
  (append (cli-binary-module-spec release?)
          (cli-binary-exe-spec release?)))

;; : (-> ModulePath Boolean)
(def (runtime-library-module? module)
  (not (member module excluded-library-files)))

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
    "src/build-api/package-build.ss"
    "src/build-api/build-path-contract.ss"
    "src/testing/gxtest-smoke.ss"
    "src/testing/gxtest-runner.ss"
    "src/build-api/native-build.ss"))

;; : (-> (List ModulePath))
(def (all-package-gerbil-modules)
  (apply append
         (map runtime-root-gerbil-modules
              (gslph-source-coverage-runtime-roots))))

;; : (-> Path (List ModulePath))
(def (runtime-root-gerbil-modules root)
  (cond
   ((string=? root "src")
    (gerbil-modules-in-directory source-root ""))
   (else
    [])))

;; : (-> (List String))
(def (coverage-excluded-directories)
  (append +default-excluded-dirs+
          +library-excluded-dirs+
          (gslph-source-coverage-exclude-directories)))

;; : (-> Path (List ModulePath))
(def (gerbil-modules-under-root root)
  (ensure-build-root!)
  (let* ((directory (path-expand root package-root))
         (prefix (root-module-prefix root)))
    (gerbil-modules-in-directory directory prefix)))

;; : (-> Path String (List ModulePath))
(def (gerbil-modules-in-directory directory prefix)
  (with-directory directory
    (lambda ()
      (map (lambda (path)
             (if (string=? prefix "")
               path
               (string-append prefix "/" path)))
           (all-gerbil-modules
            exclude-dirs: (coverage-excluded-directories))))))

;; : (-> Path String)
(def (root-module-prefix root)
  (if (or (string=? root "")
          (string=? root "."))
    ""
    root))

;; : (-> Path (-> a) a)
(def (with-directory directory thunk)
  (let (previous (current-directory))
    (dynamic-wind
      (lambda () (current-directory directory))
      thunk
      (lambda () (current-directory previous)))))

;; : (-> (List BuildSpec))
(def (package-build-spec)
  (ensure-build-root!)
  (gslph-package-api-spec))

;; : (-> Path String)
(def (module-path-stem module)
  (if (string-suffix? ".ss" module)
    (substring module 0 (- (string-length module) 3))
    module))

;; : (-> Path)
(def (package-api-output-root)
  (path-expand (source-output-prefix)
               (path-expand ".gerbil/lib" package-root)))

;; : (-> Path)
(def (package-api-build-receipt-path)
  (path-expand ".gerbil/build/package-api.receipt" package-root))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map (lambda (module)
         (path-expand module source-root))
       (package-build-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map (lambda (module)
         (path-expand
          (string-append (module-path-stem module) ".ssi")
          (package-api-output-root)))
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

;; : (-> Boolean (List BuildSpec))
(def (build-spec release?)
  (if release?
    (cli-binary-spec #t)
    (library-spec)))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec #t))
   (binary? (cli-binary-spec #f))
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
      (compile-cli-binary (dev-launcher-binpath)
                          verbose debug build-optimize?
                          release effective-release? effective-optimized?
                          worker-count)
      (make-target (compile-spec full release binary)
                   verbose debug build-optimize?
                   effective-release? effective-optimized?
                   worker-count))
    #!void))

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
  (let* ((install-release? (or release #t))
         (install-optimized? (or optimized install-release?))
         (build-optimize? (and install-optimized? (not no-optimize)))
         (worker-count (sync-build-worker-count!)))
    (compile-install-binary (install-launcher-binpath)
                            verbose debug build-optimize?
                            install-release? install-optimized?
                            worker-count)
    #!void))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-install-binary binpath verbose debug build-optimize?
                             effective-release? effective-optimized?
                             worker-count)
  (make-target (cli-install-module-spec)
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (make-target/bindir (cli-install-spec)
                      verbose debug build-optimize?
                      effective-release? effective-optimized?
                      1
                      (path-directory binpath))
  (cleanup-compile-exe-artifacts! binpath)
  binpath)

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-cli-binary binpath verbose debug build-optimize?
                         release? effective-release? effective-optimized?
                         worker-count)
  (make-target (cli-binary-module-spec release?)
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (make-target/bindir (cli-binary-exe-spec release?)
                      verbose debug build-optimize?
                      effective-release? effective-optimized?
                      1
                      (path-directory binpath))
  (cleanup-compile-exe-artifacts! binpath)
  binpath)

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-build-spec release?)
  (cli-binary-spec release?))

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

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> Path)
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
