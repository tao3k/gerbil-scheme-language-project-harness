;;; -*- Gerbil -*-
;;; Build support for the gslph package.

(import (only-in :std/make make)
        (only-in :std/misc/path directory-files path-directory path-expand path-normalize path-strip-directory)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix? string-tokenize)
        (only-in :clan/building all-gerbil-modules)
        (only-in :gerbil/tools/env setup-local-pkg-env!)
        "../src/build-api/source-coverage"
        (only-in "./gslph-install-static-modules" cli-install-static-modules)
        (only-in "../src/support/time" monotonic-micros duration-micros)
        :gerbil/gambit
        (only-in :gerbil/compiler/base __available-cores))
(export compile-target
        install-target
        compile-spec
        cli-binary-build-spec
        configure-build-root!
        dev-launcher-binpath
        gxtest-test-spec
        gxtest-test-files
        install-launcher-binpath
        parallel-gxtest-files
        serial-gxtest-files
        test-phase-receipt-line
        test-runner-worker-count
        test-target
        package-build-spec)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setup-local-pkg-env! #t)
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

;; : (-> String Integer String)
(def (test-phase-receipt-line name elapsed-micros)
  (string-append "[gslph-test-phase] name=" name
                 " elapsedMicros=" (number->string elapsed-micros)
                 " elapsedMs=" (number->string (quotient elapsed-micros 1000))
                 "\n"))

;; : (-> String Integer Void)
(def (display-test-phase-receipt name elapsed-micros)
  (display (test-phase-receipt-line name elapsed-micros))
  (force-output))

;; : (-> String (-> Value) Value)
(def (run-test-phase name thunk)
  (let (start-micros (monotonic-micros))
    (let (result (thunk))
      (display-test-phase-receipt
       name
       (duration-micros start-micros (monotonic-micros)))
      result)))

(def excluded-library-files
  '("cli.ss"
    "cli-dev-linker.ss"
    "cli-install-linker.ss"
    "cli-launcher.ss"
    "cli-release-linker.ss"))

(def (cli-exe-spec type root)
  [(append [type root bin: "gslph"]
           +cli-gsc-options+)])

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

(def +cli-cc-options+
  (openssl-cc-options))

(def +cli-linker-options+
  (openssl-ld-options))

(def +cli-gsc-options+
  (append (gsc-option "-cc-options" +cli-cc-options+)
          (gsc-option "-ld-options" +cli-linker-options+)))

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
(def (build-support-spec)
  '("build-support/gslph-install-static-modules.ss"
    "build-support/gslph-build.ss"))

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
  (append (cli-release-module-spec) (cli-release-spec)))

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
   (else (library-spec))))

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

;; : (-> Integer Integer)
(def (test-runner-worker-count file-count)
  (min (max 1 file-count) (build-worker-count)))

;; : (-> Datum String)
(def (datum-string value)
  (call-with-output-string
    (lambda (out)
      (write value out))))

;; : (-> Path String)
(def (gxtest-file-expression file)
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :gerbil/tools/gxtest)"
                 " (main "
                 (datum-string file)
                 "))"))

;; : (-> Integer Integer)
(def (normalized-exit-status status)
  (cond
   ((and (integer? status) (> status 255))
    (quotient status 256))
   ((integer? status) status)
   (else 1)))

;; : (-> Path GxTestResult)
(def (run-gxtest-file/subprocess file)
  (let ((status 0)
        (start-micros (monotonic-micros)))
    (let (output
          (run-process ["gxi" "-e" (gxtest-file-expression file)]
                       directory: package-root
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status
                           (normalized-exit-status exit-status)))))
      (list file
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

;; : (-> GxTestResult Path)
(def (gxtest-result-file result)
  (list-ref result 0))

;; : (-> GxTestResult Integer)
(def (gxtest-result-status result)
  (list-ref result 1))

;; : (-> GxTestResult String)
(def (gxtest-result-output result)
  (list-ref result 2))

;; : (-> GxTestResult Integer)
(def (gxtest-result-elapsed-micros result)
  (list-ref result 3))

;; : (-> Path Boolean)
(def (timing-sensitive-gxtest-file? file)
  (let (name (path-strip-directory file))
    (or (string-prefix? "bench" name)
        (string-prefix? "benchmark" name))))

;; : (-> Path Boolean)
(def (parallel-gxtest-file? file)
  (not (timing-sensitive-gxtest-file? file)))

;; : (-> (List Path) (List Path))
(def (parallel-gxtest-files files)
  (filter parallel-gxtest-file? files))

;; : (-> (List Path) (List Path))
(def (serial-gxtest-files files)
  (filter timing-sensitive-gxtest-file? files))

;; : (-> Integer (-> Void) (List Thread))
(def (spawn-test-workers count thunk)
  (let loop ((remaining count) (threads []))
    (if (<= remaining 0)
      threads
      (loop (- remaining 1)
            (cons (spawn thunk) threads)))))

;; : (-> (List Path) (List GxTestResult))
(def (serial-gxtest-results files)
  (map run-gxtest-file/subprocess files))

;; : (-> (List Path) Integer (List GxTestResult))
(def (parallel-gxtest-results files worker-count)
  (let* ((items (list->vector files))
         (count (vector-length items))
         (results (make-vector count #f))
         (next-index 0)
         (index-mx (make-mutex 'gxtest-runner-index)))
    (def (take-index)
      (with-lock index-mx
        (lambda ()
          (if (< next-index count)
            (let (index next-index)
              (set! next-index (+ next-index 1))
              index)
            #f))))
    (def (worker)
      (let loop ()
        (let (index (take-index))
          (when index
            (vector-set! results
                         index
                         (run-gxtest-file/subprocess
                          (vector-ref items index)))
            (loop)))))
    (let (threads (spawn-test-workers worker-count worker))
      (for-each thread-join! threads)
      (vector->list results))))

;; : (-> GxTestResult Void)
(def (display-gxtest-result result)
  (display (gxtest-result-output result))
  (display-test-phase-receipt
   (string-append "run:" (gxtest-result-file result))
   (gxtest-result-elapsed-micros result)))

;; : (-> (List GxTestResult) Integer)
(def (first-failure-status results)
  (let loop ((rest results))
    (cond
     ((null? rest) 0)
     ((zero? (gxtest-result-status (car rest)))
      (loop (cdr rest)))
     (else (gxtest-result-status (car rest))))))

;; : (-> (List Path) Void)
(def (run-gxtest-files files)
  (let* ((parallel-files (parallel-gxtest-files files))
         (serial-files (serial-gxtest-files files))
         (worker-count (test-runner-worker-count (length parallel-files)))
         (parallel-results (parallel-gxtest-results parallel-files worker-count))
         (serial-results (serial-gxtest-results serial-files))
         (results (append parallel-results serial-results))
         (status (first-failure-status results)))
    (display (string-append "[gslph-test-runner] files="
                            (number->string (length files))
                            " jobs="
                            (number->string worker-count)
                            " serial="
                            (number->string (length serial-files))
                            "\n"))
    (force-output)
    (for-each display-gxtest-result results)
    (if (zero? status)
      (begin
        (display "OK\n")
        (force-output))
      (exit status))))

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
(def (explicit-project-policy-test-file? entry)
  (string=? entry "project-policy-test.ss"))

;; : (-> Path Boolean)
(def (top-level-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))
       (not (explicit-project-policy-test-file? entry))))

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
    (run-test-phase
     "compile-library"
     (lambda ()
       (make (library-spec)
         optimize: #f
         parallelize: worker-count
         prefix: (source-output-prefix)
         srcdir: source-root)))
    (run-test-phase
     "compile-build-support"
     (lambda ()
       (make (build-support-spec)
         optimize: #f
         parallelize: worker-count
         prefix: (package-root-output-prefix)
         srcdir: package-root)))
    (run-test-phase
     "compile-test-entry"
     (lambda ()
       (make (gxtest-test-spec)
         optimize: #f
         parallelize: worker-count
         prefix: (test-output-prefix)
         srcdir: test-root))))
  (let (tests (gxtest-test-files))
    (if (null? tests)
      (error "no top-level Gerbil test files found")
      (run-test-phase
       "run-gxtest"
       (lambda ()
         (run-gxtest-files tests))))))
