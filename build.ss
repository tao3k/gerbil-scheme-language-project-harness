#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/cli/getopt flag)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        "build-support/gslph-build")

(configure-build-root! (path-directory (this-source-file)))

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
  (test-target))
