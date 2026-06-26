#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/cli/getopt flag)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        "src/build-api/source-coverage"
        "build-support/gslph-build")

(configure-build-root! (path-directory (this-source-file)))

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
  (help: "Install optimized release gslph into $HOME/.local/bin"
   getopt: compile-getopt)
  (install-target verbose debug no-optimize optimized release))

(define-entry-point (clean)
  (help: "Clean package-local development build artifacts"
   getopt: [])
  (clean-target))

(define-entry-point (test)
  (help: "Compile the package and run top-level gxtest files"
   getopt: [])
  (test-target))
