;;; -*- Gerbil -*-
;;; Build support for the gslph package.

(import (only-in :std/make make)
        (only-in :std/misc/path directory-files path-directory path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :clan/building all-gerbil-modules)
        "../src/build-api/source-coverage"
        :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores)
        (only-in :gerbil/compiler/driver compile-exe)
        (rename-in :gerbil/tools/gxtest (main gxtest-main)))
(export compile-target
        install-target
        compile-spec
        cli-binary-build-spec
        configure-build-root!
        dev-launcher-binpath
        gxtest-test-spec
        gxtest-test-files
        install-launcher-binpath
        test-target
        package-build-spec)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (set! source-root (path-expand "src" package-root))
  (set! test-root (path-expand "t" package-root))
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

;; : (-> String)
(def (test-output-prefix)
  (package-output-prefix "t"))

;; : (-> (List Path))
(def (gxtest-test-files)
  (top-level-test-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))

;; : (-> Path ModulePath)
(def (gxtest-test-module-path path)
  (if (string-prefix? "t/" path)
    (substring path 2 (string-length path))
    path))

(def excluded-library-files
  '("cli.ss"))

(def cli-spec
  '((exe: "cli-release-linker" bin: "gslph")))

(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search-workspace-scope-light.ss"
    "commands/search.ss"
    "commands/query.ss"
    "commands/check.ss"
    "commands/evidence.ss"
    "commands/agent.ss"
    "commands/guide.ss"
    "commands/info.ss"
    "search-light-launcher.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"
    "policy/gxtest.ss"
    "support/time.ss"
    "benchmark/gate.ss"
    "commands/bench-light.ss"))

(def +library-excluded-dirs+
  '("search-fast"))

(def +default-excluded-dirs+
  '("run" "t" ".git" "_darcs" ".gerbil"))

(def +test-support-dirs+
  '("unit" "snapshot" "policy"))

(def +test-support-warning-rules+
  '("GERBIL-SCHEME-MOD-R007"))

;; : (-> (List BuildSpec))
(def (cli-binary-spec)
  (append cli-bootstrap-modules cli-spec))

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
(def (test-support-spec)
  (apply append
         (map (lambda (rel-root)
                (gerbil-modules-in-directory
                 (path-expand rel-root test-root)
                 rel-root))
              +test-support-dirs+)))

;; : (-> (List BuildSpec))
(def (build-support-spec)
  '("build-support/gslph-build.ss"))

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
  (append (runtime-library-spec) cli-spec))

;; : (-> Boolean (List BuildSpec))
(def (build-spec release?)
  (if release?
    (cli-binary-spec)
    (library-spec)))

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec))
   (binary? (cli-binary-spec))
   (else cli-bootstrap-modules)))

;; : (-> Boolean Boolean Boolean Boolean Boolean Boolean Boolean Void)
(def (compile-target verbose debug no-optimize optimized release full binary)
  (ensure-build-root!)
  (current-directory package-root)
  (when (darwin-release? release)
    (error "Darwin release binary build is disabled because Gerbil compile-exe does not complete reliably on macOS; use the Linux release builder or a pinned GitHub release artifact"))
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

;; : (-> Boolean Boolean Boolean Boolean Boolean Void)
(def (install-target verbose debug no-optimize optimized release)
  (ensure-build-root!)
  (current-directory package-root)
  (when (darwin-release? release)
    (error "Darwin release binary build is disabled because Gerbil compile-exe does not complete reliably on macOS; install the pinned GitHub release artifact with asp install language"))
  (let* ((build-optimize? (and optimized (not no-optimize)))
         (worker-count (sync-build-worker-count!)))
    (compile-cli-binary (install-launcher-binpath)
                        verbose debug build-optimize?
                        release release optimized
                        worker-count)
    #!void))

;; : (-> Path Boolean Boolean Boolean Boolean Boolean Boolean Integer Path)
(def (compile-cli-binary binpath verbose debug build-optimize?
                         release? effective-release? effective-optimized?
                         worker-count)
  (make-target (cli-binary-build-spec release?)
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (compile-cli-launcher-exe binpath verbose debug))

;; : (-> Boolean (List BuildSpec))
(def (cli-binary-build-spec release?)
  (if release?
    (runtime-library-spec)
    cli-bootstrap-modules))

;; : (-> Path Boolean Boolean Path)
(def (compile-cli-launcher-exe binpath verbose debug)
  (let (bindir (path-directory binpath))
    (ensure-directory! bindir)
    (compile-exe (path-expand "cli-release-linker.ss" source-root)
                 [invoke-gsc: #t
                  output-file: binpath
                  keep-scm: #f
                  verbose: (and verbose 9)
                  debug: (and debug 'env)
                  full-program-optimization: #f
                  parallel: #f])
    binpath))

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

;; : (-> Integer)
(def (build-worker-count)
  (let* ((raw (getenv "GERBIL_BUILD_CORES" #f))
         (configured (and raw (string->number raw))))
    (if (and configured
             (integer? configured)
             (> configured 0))
      configured
      (max 1 (##cpu-count)))))

;; : (-> Integer)
(def (sync-build-worker-count!)
  (let (worker-count (build-worker-count))
    (set! __available-cores worker-count)
    worker-count))

;; : (-> Boolean Boolean)
(def (darwin-release? release?)
  (and release?
       (darwin-host?)))

;; : (-> Boolean)
(def (darwin-host?)
  (cond-expand
    (darwin #t)
    (else #f)))

;; : (-> Path Boolean)
(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))))

;; : (-> (List Path))
(def (top-level-test-files)
  (ensure-build-root!)
  (map (lambda (path)
         (string-append "t/" path))
       (filter top-level-test-file?
               (sort (directory-files test-root) string<?))))

;; : (-> Void)
(def (test-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (worker-count (sync-build-worker-count!))
    (make (library-spec)
      optimize: #f
      parallelize: worker-count
      prefix: (source-output-prefix)
      srcdir: source-root)
    (make (build-support-spec)
      optimize: #f
      parallelize: worker-count
      prefix: (package-root-output-prefix)
      srcdir: package-root)
    (let (support-spec (test-support-spec))
      (unless (null? support-spec)
        (make support-spec
          optimize: #f
          parallelize: worker-count
          prefix: (test-output-prefix)
          srcdir: test-root)))
    (make (gxtest-test-spec)
      optimize: #f
      parallelize: worker-count
      prefix: (test-output-prefix)
      srcdir: test-root))
  (let (tests (gxtest-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
