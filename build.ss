#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/cli/getopt flag)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        (only-in :std/misc/path directory-files)
        :std/make
        :std/sort
        :std/srfi/13
        :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores)
        (only-in :gerbil/compiler/driver compile-exe)
        (rename-in :gerbil/tools/gxtest (main gxtest-main)))

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def test-root (path-expand "t" package-root))

(current-directory package-root)

(def excluded-library-files
  '("cli.ss"))

(def cli-spec
  '((exe: "cli-launcher" bin: "gslph")))

(def cli-bootstrap-modules
  '("constants.ss"
    "commands/search-prime-light-list.ss"
    "commands/search-prime-light.ss"
    "commands/search-workspace-scope-light.ss"
    "search-light-launcher.ss"
    "cli-launcher.ss"
    "support/time.ss"
    "commands/bench-light.ss"))

(def (cli-binary-spec)
  (append cli-bootstrap-modules cli-spec))

(def +library-excluded-dirs+
  '("search-fast"))

(def compile-getopt
  [(flag 'verbose "-V" "--verbose"
         help: "Make the build verbose")
   (flag 'debug "-g" "--debug"
         help: "Include debug information")
   (flag 'no-optimize "--O" "--no-optimize"
         help: "Disable Gerbil optimization")
   (flag 'optimized "-O" "--optimized"
         help: "Accept gxpkg optimized build mode")
   (flag 'release "-R" "--release"
         help: "Build static release executables")
   (flag 'binary "--binary"
         help: "Build the native CLI executable")
   (flag 'full "--full"
         help: "Compile every library module instead of the CLI launcher")])

(def (runtime-library-module? module)
  (not (member module excluded-library-files)))

(def (library-module? module)
  (and (not (member module excluded-library-files))
       (not (string-prefix? "policy/" module))))

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
  (append (runtime-library-spec) cli-spec))

(def (build-spec release?)
  (if release?
    (cli-binary-spec)
    (library-spec)))

(def (compile-spec full? release? binary?)
  (cond
   (full? (library-spec))
   (release? (cli-binary-spec))
   (binary? (cli-binary-spec))
   (else cli-bootstrap-modules)))

(def (compile-target verbose debug no-optimize optimized release full binary)
  (when (and binary (not release))
    (error "binary install is release-only; use ./build.ss install --release or install the pinned release with asp install language"))
  (let* ((is-darwin-release? (darwin-release? release))
         (build-optimize? (and optimized (not no-optimize) (not is-darwin-release?)))
         (effective-release? (and release (not is-darwin-release?)))
         (effective-optimized? (and optimized (not is-darwin-release?)))
         (worker-count (sync-build-worker-count!)))
    (when is-darwin-release?
      (display "build.ss: Darwin does not support Gerbil -static release linking; building native executables without Gerbil -O.\n"
               (current-error-port)))
    (if (and (not full) (or release binary))
      (compile-cli-binary verbose debug build-optimize?
                          effective-release? effective-optimized?
                          worker-count)
      (make-target (compile-spec full release binary)
                   verbose debug build-optimize?
                   effective-release? effective-optimized?
                   worker-count))
    #!void))

(def (compile-cli-binary verbose debug build-optimize?
                         effective-release? effective-optimized?
                         worker-count)
  (make-target cli-bootstrap-modules
               verbose debug build-optimize?
               effective-release? effective-optimized?
               worker-count)
  (compile-cli-launcher-exe verbose debug))

(def (compile-cli-launcher-exe verbose debug)
  (let* ((binpath (native-launcher-binpath))
         (bindir (path-directory binpath)))
    (unless (file-exists? bindir)
      (create-directory bindir))
    (compile-exe (path-expand "cli-launcher.ss" source-root)
                 [invoke-gsc: #t
                  output-file: binpath
                  keep-scm: #f
                  verbose: (and verbose 9)
                  debug: (and debug 'env)
                  full-program-optimization: #f
                  parallel: #f])
    binpath))

(def (native-launcher-binpath)
  (path-expand "bin/gslph" (gerbil-user-root)))

(def (gerbil-user-root)
  (or (getenv "GERBIL_PATH" #f)
      (path-expand ".gerbil" (getenv "HOME"))))

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

(define-multicall-main)

(define-entry-point (compile verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f)
                             full: (full #f)
                             binary: (binary #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (compile-target verbose debug no-optimize optimized release full binary))

(define-entry-point (spec verbose: (verbose #f) debug: (debug #f)
                          no-optimize: (no-optimize #f)
                          optimized: (optimized #f)
                          release: (release #f)
                          full: (full #f)
                          binary: (binary #f))
  (help: "Show the build specification"
   getopt: compile-getopt)
  (pretty-print (compile-spec full release binary)))

(define-entry-point (install verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f))
  (help: "Build the native gslph executable"
   getopt: compile-getopt)
  (compile-target verbose debug no-optimize optimized release #f #t))

(define-entry-point (test)
  (help: "Compile the package and run top-level gxtest files")
  (let (worker-count (sync-build-worker-count!))
    (make (library-spec)
      optimize: #f
      parallelize: worker-count
      srcdir: source-root))
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
