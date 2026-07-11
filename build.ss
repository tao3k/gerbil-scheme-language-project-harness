#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :gerbil/gambit current-directory exit getenv setenv)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        (only-in :std/cli/getopt flag rest-arguments)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        (only-in :std/make make)
        (only-in :std/misc/path path-directory path-expand)
        "src/build-api/source-coverage"
        (only-in :std/misc/process run-process))

(def +package-root+ (path-directory (this-source-file)))
(def +native-build-api+ (path-expand "src/build-api/native-build.ss" +package-root+))
(def +package-build-api+ (path-expand "src/build-api/package-build.ss" +package-root+))
(def +gxtest-runner+ (path-expand "src/testing/gxtest-runner.ss" +package-root+))

;; This acyclic source-level foundation must remain serial because each stage
;; publishes an SSI for the next; ordinary package stages use worker discovery.
(def +building-framework-bootstrap-interface-stages+
  '("src/support/time.ss"
    "src/testing/model.ss"
    "src/benchmark/framework.ss"
    "src/benchmark/gate.ss"
    "src/testing/scope.ss"
    "src/testing/scenario.ss"
    "src/testing/selection.ss"
    "src/testing/batch.ss"
    "src/testing/performance.ss"
    "src/testing/commands.ss"
    "src/build-api/source-coverage.ss"
    "src/testing/framework.ss"))

(def +building-framework-bootstrap-stages+
  '(("build-api/package-build.ss")
    ("building/native-toolchain.ss")
    ("building/model.ss")
    ("building/std-builder.ss")
    ("building/facade.ss")
  ("building/commands.ss")
  ("build-api/framework.ss")
  ("testing/gxtest-context.ss")
  ("testing/gxtest-syntax.ss")
  ("testing/memory-profile.ss")
  ("testing/framework.ss")
    ("building/declarative.ss")
    ("testing/commands.ss")))

;; Make linked package modules visible before dynamically loading Build API owners.
(current-directory +package-root+)
(setup-local-pkg-env! #t)

(gslph-source-coverage
 roots: '("src" "t")
 runtime-roots: '("src")
 exclude-directories: '("scenarios" "snapshots")
 explanation: "GSLPH source coverage declared by build.ss.")

(def (native-build-getopt . options)
  (append
   [(flag 'verbose "-V" "--verbose"
          help: "Make the build verbose")
    (flag 'debug "-g" "--debug"
          help: "Include debug information")
    (flag 'no-optimize "--O" "--no-optimize"
          help: "Disable Gerbil optimization")
    (flag 'optimized "-O" "--optimized"
          help: "Accept gxpkg optimized build mode")
    (flag 'release "-R" "--release"
          help: "Build optimized release executables")]
   options))

(def compile-getopt
  (native-build-getopt
   (flag 'force "--force"
         help: "Rebuild package stages while preserving incremental artifacts")
   (flag 'binary "--binary"
         help: "Build the package-local development CLI executable under .bin")
   (flag 'full "--full"
         help: "Compile every library module instead of the CLI launcher")))

(def spec-getopt
  (native-build-getopt
   (flag 'binary "--binary"
         help: "Show the package-local development CLI specification")
   (flag 'full "--full"
         help: "Show the full library specification")))

(def install-getopt
  (native-build-getopt
   (flag 'full "--full"
         help: "Compile every library module before installing the CLI launcher")))

(def test-file-getopt
  [(rest-arguments 'files
                   help: "Selected gxtest files")])

(define-multicall-main)

;; : (-> Void)
(def (load-native-build-api!)
  (bootstrap-building-framework!)
  (load +native-build-api+)
  (eval `(configure-build-root! ,+package-root+)))

;; : (-> Void)
(def (load-package-build-api!)
  (load +package-build-api+))

;; : (-> Datum Datum)
(def (package-build-call form)
  (load-package-build-api!)
  (eval form))

;; : (-> String)
(def (building-framework-bootstrap-prefix)
  (let (package-name
        (package-build-call
         `(gslph-package-build-package-name ,+package-root+)))
    (unless package-name
      (error "gerbil.pkg must declare package: for building bootstrap"))
    (string-append package-name "/src")))

;; : (-> Void)
(def (bootstrap-building-framework!)
  (let ((previous-sdkroot (getenv "SDKROOT" #f))
        (previous-developer-dir (getenv "DEVELOPER_DIR" #f)))
    (dynamic-wind
      (lambda ()
        (setenv "SDKROOT" "")
        (setenv "DEVELOPER_DIR" ""))
      bootstrap-building-framework/native!
      (lambda ()
        (setenv "SDKROOT" (or previous-sdkroot ""))
        (setenv "DEVELOPER_DIR" (or previous-developer-dir ""))))))

(def (bootstrap-interface-loadpath source-root)
  (let (roots (string-append source-root ":" +package-root+))
    (let (current (getenv "GERBIL_LOADPATH" #f))
      (if current
        (string-append roots ":" current)
        roots))))

(def (bootstrap-interface-file output-root prefix module)
  (path-expand
   (string-append
    prefix "/"
    (substring module 4 (- (string-length module) 2))
    "ssi")
   output-root))

(def (bootstrap-materialize-source-interfaces! source-root prefix)
  (let (gerbil-path (getenv "GERBIL_PATH" #f))
    (unless gerbil-path
      (error "GERBIL_PATH is required to materialize bootstrap interfaces"))
    (let (output-root (path-expand "lib" gerbil-path))
      (for-each
       (lambda (module)
         (unless (file-exists?
                  (bootstrap-interface-file output-root prefix module))
           (run-process
            (list "env"
                  (string-append "GERBIL_LOADPATH="
                                 (bootstrap-interface-loadpath source-root))
                  "gxc"
                  "-d" output-root
                  "-S" (path-expand module +package-root+)))))
       +building-framework-bootstrap-interface-stages+))))

;; : (-> Void)
(def (bootstrap-building-framework/native!)
  (let ((source-root (path-expand "src" +package-root+))
        (prefix (building-framework-bootstrap-prefix)))
    (bootstrap-materialize-source-interfaces! source-root prefix)
    (for-each
     (lambda (stage)
       (apply make
              stage
              [optimize: #f
               parallelize: 1
               prefix: prefix
               srcdir: source-root]))
     +building-framework-bootstrap-stages+)))

;; : (-> Datum Datum)
(def (native-build-call form)
  (load-native-build-api!)
  (eval form))

;; : (-> Void)
(def (load-gxtest-runner!)
  (bootstrap-building-framework!)
  (load +gxtest-runner+)
  (eval `(configure-build-root! ,+package-root+)))

;; : (-> Datum Datum)
(def (gxtest-runner-call form)
  (load-gxtest-runner!)
  (eval form))

(define-entry-point (compile verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f)
                             full: (full #f)
                             binary: (binary #f)
                             force: (force #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (native-build-call
   `(compile-target ,verbose ,debug ,no-optimize ,optimized ,release ,full ,binary ,force))
  (exit 0))

(define-entry-point (spec verbose: (verbose #f) debug: (debug #f)
                          no-optimize: (no-optimize #f)
                          optimized: (optimized #f)
                          release: (release #f)
                          full: (full #f)
                          binary: (binary #f))
  (help: "Show the build specification"
   getopt: spec-getopt)
  (pretty-print
   (native-build-call `(compile-spec ,full ,release ,binary))))

(define-entry-point (install verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
           release: (release #f)
           full: (full #f))
  (help: "Install optimized release gslph into $HOME/.local/bin"
   getopt: install-getopt)
  (native-build-call
   `(install-target ,verbose ,debug ,no-optimize ,optimized ,release ,full))
  (exit 0))

(define-entry-point (clean)
  (help: "Clean package-local development build artifacts"
   getopt: [])
  (native-build-call '(clean-target))
  (exit 0))

(define-entry-point (test)
  (help: "Run the default fast gxtest smoke gate"
   getopt: [])
  (gxtest-runner-call `(configure-build-root! ,+package-root+))
  (gxtest-runner-call '(test-target)))

(define-entry-point (test-file . files)
  (help: "Run selected gxtest files"
   getopt: test-file-getopt)
  (gxtest-runner-call `(configure-build-root! ,+package-root+))
  (gxtest-runner-call `(test-file-target ',files)))

(define-entry-point (test-full)
  (help: "Run every top-level gxtest file"
   getopt: [])
  (gxtest-runner-call `(configure-build-root! ,+package-root+))
  (gxtest-runner-call '(test-full-target)))
