#!/usr/bin/env gxi
;; -*- Gerbil -*-

(import (only-in :std/cli/getopt flag)
        (only-in :std/cli/multicall define-entry-point define-multicall-main)
        (only-in :std/misc/path directory-files)
        :std/make
        :std/sort
        :std/srfi/13
        :gerbil/gambit
        (rename-in :gerbil/tools/gxtest (main gxtest-main)))

(def package-root (path-normalize (path-directory (this-source-file))))
(def source-root (path-expand "src" package-root))
(def test-root (path-expand "t" package-root))

(current-directory package-root)
(add-load-path! package-root)
(add-load-path! source-root)

(def excluded-library-files
  '("src/cli-launcher.ss"))

(def cli-launcher-spec
  '((exe: "src/cli-launcher" bin: "gslph")))

(def cli-launcher-release-modules
  '("src/constants.ss"
    "src/commands/search-prime-light.ss"
    "src/search-light-launcher.ss"))

(def cli-launcher-release-spec
  (append cli-launcher-release-modules cli-launcher-spec))

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
         help: "Build static release executables")])

(def (library-module? module)
  (and (not (member module excluded-library-files))
       (not (string-prefix? "policy/" module))))

(def (library-spec)
  (filter library-module? (all-package-gerbil-modules)))

(def (all-package-gerbil-modules)
  (append (if (file-exists? (path-expand "version.ss" package-root))
            '("version.ss")
            '())
          (collect-gerbil-module-tree source-root "src")))

(def (collect-gerbil-module-tree root rel-root)
  (let (result '())
    (def (walk dir rel)
      (for-each
       (lambda (entry)
         (unless (member entry '("." ".."))
           (let ((path (path-expand entry dir))
                 (relpath (string-append rel "/" entry)))
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
  (append (library-spec) cli-launcher-spec))

(def (build-spec release?)
  (if release?
    cli-launcher-release-spec
    (package-build-spec)))

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
                             release: (release #f))
  (help: "Compile the package"
   getopt: compile-getopt)
  (let* ((is-darwin-release? (darwin-release? release))
         (build-optimize? (and (not no-optimize) (not is-darwin-release?)))
         (effective-release? (and release (not is-darwin-release?)))
         (effective-optimized? (and optimized (not is-darwin-release?))))
    (when is-darwin-release?
      (display "build.ss: Darwin does not support Gerbil -static release linking; building native executables without Gerbil -O.\n"
               (current-error-port)))
    (make (build-spec release)
      verbose: (and verbose 9)
      debug: (and debug 'env)
      optimize: build-optimize?
      build-release: effective-release?
      build-optimized: effective-optimized?
      parallelize: #t
      srcdir: package-root)))

(define-entry-point (spec verbose: (verbose #f) debug: (debug #f)
                          no-optimize: (no-optimize #f)
                          optimized: (optimized #f)
                          release: (release #f))
  (help: "Show the build specification"
   getopt: compile-getopt)
  (pretty-print (build-spec release)))

(define-entry-point (test)
  (help: "Compile the package and run top-level gxtest files")
  (make (package-build-spec) parallelize: #t srcdir: package-root)
  (add-load-path! package-root)
  (add-load-path! source-root)
  (add-load-path! test-root)
  (let (tests (top-level-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (apply gxtest-main tests))))
