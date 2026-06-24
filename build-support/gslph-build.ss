;;; -*- Gerbil -*-
;;; Build support for the gslph package.

(import (only-in :std/make make)
        (only-in :std/misc/path directory-files path-directory path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
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
        install-launcher-binpath
        test-target
        package-build-spec)

(def package-root #f)
(def source-root #f)
(def test-root #f)

(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (set! source-root (path-expand "src" package-root))
  (set! test-root (path-expand "t" package-root)))

(def (ensure-build-root!)
  (unless package-root
    (configure-build-root! (current-directory))))

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
    "support/time.ss"
    "commands/bench-light.ss"))

(def +library-excluded-dirs+
  '("search-fast"))

(def (cli-binary-spec)
  (append cli-bootstrap-modules cli-spec))

(def (runtime-library-module? module)
  (not (member module excluded-library-files)))

(def (library-module? module)
  (runtime-library-module? module))

(def (library-spec)
  (filter library-module? (all-package-gerbil-modules)))

(def (runtime-library-spec)
  (filter runtime-library-module? (all-package-gerbil-modules)))

(def (all-package-gerbil-modules)
  (collect-gerbil-module-tree source-root ""))

(def (collect-gerbil-module-tree root rel-root)
  (let (result '())
    (def (walk dir rel)
      (for-each
       (lambda (entry)
         (unless (member entry '("." ".."))
           (let* ((path (path-expand entry dir))
                  (relpath (if (string=? rel "")
                             entry
                             (string-append rel "/" entry))))
             (cond
              ((and (source-directory? path)
                    (not (member entry +library-excluded-dirs+)))
               (walk path relpath))
              ((string-suffix? ".ss" entry)
               (set! result (cons relpath result)))
              (else #!void)))))
       (sort (directory-files dir) string<?)))
    (when (source-directory? root)
      (walk root rel-root))
    (reverse result)))

(def (package-build-spec)
  (ensure-build-root!)
  (append (runtime-library-spec) cli-spec))

(def (build-spec release?)
  (if release?
    (cli-binary-spec)
    (library-spec)))

(def (compile-spec full? release? binary?)
  (ensure-build-root!)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec))
   (binary? (cli-binary-spec))
   (else cli-bootstrap-modules)))

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

(def (compile-cli-binary binpath verbose debug build-optimize?
                         release? effective-release? effective-optimized?
                         worker-count)
  (make-target (cli-binary-build-spec release?)
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (compile-cli-launcher-exe binpath verbose debug))

(def (cli-binary-build-spec release?)
  (if release?
    (runtime-library-spec)
    cli-bootstrap-modules))

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

(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install gslph into $HOME/.local/bin")))

(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

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
    srcdir: source-root))

(def (build-worker-count)
  (let* ((raw (getenv "GERBIL_BUILD_CORES" #f))
         (configured (and raw (string->number raw))))
    (if (and configured
             (integer? configured)
             (> configured 0))
      configured
      (max 1 (##cpu-count)))))

(def (sync-build-worker-count!)
  (let (worker-count (build-worker-count))
    (set! __available-cores worker-count)
    worker-count))

(def (darwin-release? release?)
  (and release?
       (darwin-host?)))

(def (darwin-host?)
  (cond-expand
    (darwin #t)
    (else #f)))

(def (source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))))

(def (top-level-test-files)
  (map (lambda (path)
         (string-append "t/" path))
       (filter top-level-test-file?
               (sort (directory-files test-root) string<?))))

(def (test-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (worker-count (sync-build-worker-count!))
    (make (library-spec)
      optimize: #f
      parallelize: worker-count
      srcdir: source-root))
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
