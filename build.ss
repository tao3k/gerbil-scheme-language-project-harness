#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/cli/getopt flag)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        (only-in :std/misc/path path-directory path-expand)
        "src/build-api/source-coverage"
        "build-support/gslph-package-spec")

(def +package-root+ (path-directory (this-source-file)))
(def +heavy-build-support+ (path-expand "build-support/gslph-build.ss" +package-root+))
(def +package-build-support+ (path-expand "build-support/gslph-package-build.ss" +package-root+))

(gslph-source-coverage
 roots: '("src" "build-support" "t")
 runtime-roots: '("src")
 exclude-directories: '("scenarios" "snapshots")
 explanation: "GSLPH source coverage declared by build.ss.")

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
         help: "Build optimized release executables")
   (flag 'binary "--binary"
         help: "Build the package-local development CLI executable under .bin")
   (flag 'full "--full"
         help: "Compile every library module instead of the CLI launcher")])

(define-multicall-main)

;; : (-> Void)
(def (load-heavy-build-support!)
  (load +heavy-build-support+)
  (eval `(configure-build-root! ,+package-root+)))

;; : (-> Void)
(def (load-package-build-support!)
  (load +package-build-support+)
  (eval `(gslph-package-configure-build-root! ,+package-root+)))

;; : (-> Datum Datum)
(def (heavy-build-call form)
  (load-heavy-build-support!)
  (eval form))

;; : (-> Datum Datum)
(def (package-build-call form)
  (load-package-build-support!)
  (eval form))

(define-entry-point (compile verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f)
                             full: (full #f)
                             binary: (binary #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (if (or full release binary)
    (heavy-build-call
     `(compile-target ,verbose ,debug ,no-optimize ,optimized ,release ,full ,binary))
    (package-build-call
     `(gslph-package-compile-target ,verbose ,debug ,no-optimize ,optimized ,release))))

(define-entry-point (spec verbose: (verbose #f) debug: (debug #f)
                          no-optimize: (no-optimize #f)
                          optimized: (optimized #f)
                          release: (release #f)
                          full: (full #f)
                          binary: (binary #f))
  (help: "Show the build specification"
   getopt: compile-getopt)
  (pretty-print
   (if (or full release binary)
     (heavy-build-call `(compile-spec ,full ,release ,binary))
     (gslph-package-api-spec))))

(define-entry-point (install verbose: (verbose #f) debug: (debug #f)
                             no-optimize: (no-optimize #f)
                             optimized: (optimized #f)
                             release: (release #f))
  (help: "Install optimized release gslph into $HOME/.local/bin"
   getopt: compile-getopt)
  (heavy-build-call
   `(install-target ,verbose ,debug ,no-optimize ,optimized ,release)))

(define-entry-point (clean)
  (help: "Clean package-local development build artifacts"
   getopt: [])
  (heavy-build-call '(clean-target)))

(define-entry-point (test)
  (help: "Compile the package API and run the default fast top-level gxtest files"
   getopt: [])
  (heavy-build-call '(test-target)))

(define-entry-point (test-full)
  (help: "Compile the package API and run every top-level gxtest file"
   getopt: [])
  (heavy-build-call '(test-full-target)))
