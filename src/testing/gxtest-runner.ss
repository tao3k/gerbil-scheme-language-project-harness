;;; -*- Gerbil -*-
;;; Gxtest framework runner for package test targets.

(import (only-in :std/misc/path directory-files path-directory path-expand path-normalize path-strip-directory)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        "../build-api/package-receipt"
        "../build-api/package-spec"
        (only-in "../build-api/worker-count"
                 build-worker-count
                 gxtest-worker-count
                 gxtest-worker-count/cores
                 machine-efficiency-core-count
                 machine-logical-core-count
                 machine-performance-core-count
                 sync-build-worker-count!)
        (only-in "../support/time" monotonic-micros duration-micros)
        (only-in "./gxtest-smoke"
                 gslph-default-gxtest-smoke-files)
        :gerbil/gambit)
(export clean-target
        compile-spec
        configure-build-root!
        default-gxtest-test-files
        dev-launcher-binpath
        gxtest-test-spec
        gxtest-test-files
        gxtest-batch-label
        gxtest-batches
        gxtest-worker-count/cores
        gxtest-compiled-batch-expression
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-file-module-symbol
        gxtest-source-load-batch-expression
        gxtest-selected-test-files
        install-launcher-binpath
        gslph-package-build-receipt-status-ref
        package-api-build-current?
        package-api-build-output-files
        package-api-build-receipt-path
        package-api-build-receipt-status
        package-api-build-source-files
        parallel-gxtest-files
        serial-gxtest-files
        build-worker-count
        machine-efficiency-core-count
        machine-logical-core-count
        machine-performance-core-count
        compile-package-api-if-stale
        sync-build-worker-count!
        test-file-target
        test-full-target
        test-phase-receipt-line
        test-target
        test-target-compile-selected-gxtest?
        selected-gxtest-build-current?
        selected-gxtest-build-output-files
        selected-gxtest-build-receipt-path
        selected-gxtest-build-receipt-status
        selected-gxtest-build-source-files
        test-runner-worker-count
        write-package-api-build-receipt!)

(def package-root #f)
(def source-root #f)
(def test-root #f)
(def package-name #f)

;; : (-> String Void)
(def (configure-build-root! root)
  (set! package-root (path-normalize root))
  (current-directory package-root)
  (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
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
(def (source-output-prefix)
  (package-output-prefix "src"))

;; : (-> String)
(def (test-output-prefix)
  (package-output-prefix "t"))

;; : (-> Path)
(def (package-build-api-path)
  (path-expand "src/build-api/package-build.ss" package-root))

;; : (-> Void)
(def (load-package-build-api!)
  (let (root package-root)
    (load (package-build-api-path))
    (eval `(gslph-package-configure-build-root! ,root))))

;; : (-> Void)
(def (compile-package-api!)
  (load-package-build-api!)
  (eval '(gslph-package-compile-target #f #f #t #f #f)))

;; : (-> (List Path))
(def (gxtest-test-files)
  (top-level-test-files))

;; : (-> (List Path))
(def (default-gxtest-test-files)
  (gslph-default-gxtest-smoke-files))

;; : (-> (List ModulePath))
(def (gxtest-test-spec)
  (map gxtest-test-module-path (gxtest-test-files)))

;; : (-> (List Path) (List ModulePath))
(def (gxtest-files-spec files)
  (map gxtest-test-module-path files))

;; : (-> Path ModulePath)
(def (gxtest-test-module-path path)
  (if (string-prefix? "t/" path)
    (substring path 2 (string-length path))
    path))

;; : (-> Path ModulePath)
(def (gxtest-source-module-path path)
  (if (string-prefix? "src/" path)
    (substring path 4 (string-length path))
    path))

;; : (-> ModulePath ModulePath)
(def (gxtest-normalize-module-path module-path)
  (if (and package-name
           (string-prefix? (string-append package-name "/") module-path))
    (substring module-path
               (+ (string-length package-name) 1)
               (string-length module-path))
    module-path))

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

;; : (-> Boolean Boolean Boolean (List BuildSpec))
(def (compile-spec full? release? binary?)
  (cond
   ((or full? release?)
    (error "full and release compile specs are owned by native-build"))
   (binary? cli-bootstrap-modules)
   (else (gslph-package-api-spec))))

;; : (-> String)
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

;; : (-> Path)
(def (selected-gxtest-build-receipt-path)
  (path-expand ".gerbil/build/selected-gxtest.receipt" package-root))

;; : (-> (List Path))
(def (package-api-build-source-files)
  (map (lambda (module)
         (path-expand module source-root))
       (gslph-package-api-spec)))

;; : (-> (List Path))
(def (package-api-build-output-files)
  (map (lambda (module)
         (path-expand
          (string-append (module-path-stem module) ".ssi")
          (package-api-output-root)))
       (gslph-package-api-spec)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-source-files files)
  (map (lambda (file)
         (path-expand file package-root))
       (gxtest-selected-source-files files)))

;; : (-> (List Path) (List Path))
(def (selected-gxtest-build-output-files files)
  (map (lambda (file)
         (cond
          ((string-prefix? "src/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-source-module-path file))
             ".ssi")
            (path-expand (source-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          ((string-prefix? "t/" file)
           (path-expand
            (string-append
             (module-path-stem (gxtest-test-module-path file))
             ".ssi")
            (path-expand (test-output-prefix)
                         (path-expand ".gerbil/lib" package-root))))
          (else
           (error "selected gxtest source file must be under src/ or t/" file))))
       (gxtest-selected-source-files files)))

;; : (-> BuildReceiptStatus)
(def (package-api-build-receipt-status)
  (gslph-package-build-receipt-status
   (package-api-build-receipt-path)
   expected-sources: (package-api-build-source-files)
   expected-outputs: (package-api-build-output-files)))

;; : (-> (List Path) BuildReceiptStatus)
(def (selected-gxtest-build-receipt-status files)
  (gslph-package-build-receipt-status
   (selected-gxtest-build-receipt-path)
   expected-sources: (selected-gxtest-build-source-files files)
   expected-outputs: (selected-gxtest-build-output-files files)))

;; : (-> BuildReceiptStatus Boolean)
(def (package-api-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Boolean)
(def (selected-gxtest-build-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus Void)
(def (display-package-api-build-receipt-status status)
  (display (gslph-package-build-receipt-status-line status))
  (newline)
  (force-output))

;; : (-> Void)
(def (ensure-directory! path)
  (unless (file-exists? path)
    (let (parent (path-directory path))
      (when (and parent
                 (not (string=? parent ""))
                 (not (string=? parent path)))
        (ensure-directory! parent))
      (create-directory path))))

;; : (-> Void)
(def (write-package-api-build-receipt!)
  (let (stamp (package-api-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (package-api-build-source-files)
     (package-api-build-output-files))))

;; : (-> (List Path) Void)
(def (write-selected-gxtest-build-receipt! files)
  (let (stamp (selected-gxtest-build-receipt-path))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (selected-gxtest-build-source-files files)
     (selected-gxtest-build-output-files files))))

;; : (-> Integer [Maybe (-> Void)] BuildReceiptStatus)
(def (compile-package-api-if-stale worker-count (compile-thunk #f))
  (let (status (package-api-build-receipt-status))
    (display-package-api-build-receipt-status status)
    (if (package-api-build-current? status)
      status
      (begin
        (if compile-thunk
          (compile-thunk)
          (compile-package-api!))
        (write-package-api-build-receipt!)
        (package-api-build-receipt-status)))))

;; : (-> (List Path) Integer Void)
(def (compile-selected-gxtest! files worker-count)
  (load-package-build-api!)
  (eval `(gslph-package-compile-gxtest-target
          ',(gxtest-selected-source-module-files files)
          ',(gxtest-selected-test-files files)
          ,worker-count)))

;; : (-> (List Path) Integer BuildReceiptStatus)
(def (compile-selected-gxtest-if-stale files worker-count)
  (let (status (selected-gxtest-build-receipt-status files))
    (display-package-api-build-receipt-status status)
    (if (selected-gxtest-build-current? status)
      status
      (begin
        (compile-selected-gxtest! files worker-count)
        (write-selected-gxtest-build-receipt! files)
        (selected-gxtest-build-receipt-status files)))))

;; : (-> Path)
(def (dev-launcher-binpath)
  (path-expand ".bin/gslph" package-root))

;; : (-> Path)
(def (install-launcher-binpath)
  (path-expand ".local/bin/gslph" (user-home-directory)))

;; : (-> Path)
(def (user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to install asp gerbil-scheme into $HOME/.local/bin")))

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

;; : (-> Void)
(def (clean-target)
  (ensure-build-root!)
  (current-directory package-root)
  (let (binpath (dev-launcher-binpath))
    (delete-file* binpath)
    (cleanup-compile-exe-artifacts! binpath))
  #!void)

;; : (-> Integer Integer)
(def (test-runner-worker-count file-count)
  (gxtest-worker-count file-count))

;; : (-> Datum String)
(def (datum-string value)
  (call-with-output-string
    (lambda (out)
      (write value out))))

;; : (-> Path String)
(def (join-gxtest-args files)
  (match files
    ([] "")
    ([file] (datum-string file))
    ([file . rest]
     (string-append (datum-string file) " " (join-gxtest-args rest)))))

(def (join-strings values separator)
  (match values
    ([] "")
    ([value] value)
    ([value . rest]
     (string-append value separator (join-strings rest separator)))))

(def (gxtest-export-symbols form)
  (if (and (pair? form)
           (eq? (car form) 'export))
    (gxtest-filter-map
     (lambda (item)
       (and (symbol? item) item))
     (cdr form))
    []))

(def (gxtest-suite-symbol? symbol)
  (string-suffix? "-test" (symbol->string symbol)))

(def (gxtest-first pred values)
  (cond
   ((null? values) #f)
   ((pred (car values)) (car values))
   (else (gxtest-first pred (cdr values)))))

(def (gxtest-file-exported-symbols file)
  (let (path (path-expand file package-root))
    (call-with-input-file path
      (lambda (port)
        (let loop ((symbols []))
          (let (form (read port))
            (if (eof-object? form)
              symbols
              (loop (append symbols (gxtest-export-symbols form))))))))))

(def (gxtest-file-exported-suite file)
  (let* ((symbols (gxtest-file-exported-symbols file))
         (suite (or (gxtest-first gxtest-suite-symbol? symbols)
                    (and (pair? symbols) (car symbols)))))
    (or suite
        (error "gxtest file must export a test suite" file))))

(def (gxtest-def-symbol form)
  (and (pair? form)
       (eq? (car form) 'def)
       (pair? (cdr form))
       (let (head (cadr form))
         (cond
          ((symbol? head) head)
          ((and (pair? head) (symbol? (car head))) (car head))
          (else #f)))))

(def (gxtest-file-local-def-symbols file)
  (let (path (path-expand file package-root))
    (call-with-input-file path
      (lambda (port)
        (let loop ((symbols []))
          (let (form (read port))
            (if (eof-object? form)
              symbols
              (let (symbol (gxtest-def-symbol form))
                (loop (if symbol (cons symbol symbols) symbols))))))))))

(def (gxtest-file-local-suite? file)
  (member (gxtest-file-exported-suite file)
          (gxtest-file-local-def-symbols file)))

(def (gxtest-files-local-suite? files)
  (cond
   ((null? files) #t)
   ((gxtest-file-local-suite? (car files))
    (gxtest-files-local-suite? (cdr files)))
   (else #f)))

(def (gxtest-file-module-symbol file)
  (ensure-build-root!)
  (unless package-name
    (error "gerbil.pkg must declare package: for gxtest module import"))
  (string->symbol
   (string-append ":"
                  package-name
                  "/"
                  (module-path-stem file))))

(def (gxtest-compiled-import-clause file)
  (string-append "(only-in "
                 (datum-string (gxtest-file-module-symbol file))
                 " "
                 (datum-string (gxtest-file-exported-suite file))
                 ")"))

(def (gxtest-compiled-run-clause file)
  (string-append "(run-test-suite! "
                 (datum-string (gxtest-file-exported-suite file))
                 ")"))

(def (gxtest-compiled-batch-expression files)
  (string-append "(begin"
                 " (import :std/test "
                 (join-strings (map gxtest-compiled-import-clause files) " ")
                 ") "
                 (join-strings (map gxtest-compiled-run-clause files) " ")
                 ")"))

(def (gxtest-source-load-clause file)
  (string-append "(load " (datum-string file) ")"))

(def (gxtest-source-load-batch-expression files)
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :std/test) "
                 (join-strings (map gxtest-source-load-clause files) " ")
                 " "
                 (join-strings (map gxtest-compiled-run-clause files) " ")
                 ")"))

(def (gxtest-batch-label files)
  (match files
    ([] "empty")
    ([file] file)
    ([file . rest]
     (string-append file ",+" (number->string (length rest))))))

(def (gxtest-batch-expression files)
  (string-append "(begin"
                 " (add-load-path! \".\")"
                 " (add-load-path! \"src\")"
                 " (add-load-path! \"t\")"
                 " (import :gerbil/tools/gxtest)"
                 " (main "
                 (join-gxtest-args files)
                 "))"))

;; : (-> Integer Integer)
(def (normalized-exit-status status)
  (cond
   ((and (integer? status) (> status 255))
    (quotient status 256))
   ((integer? status) status)
   (else 1)))

(def (run-gxtest-batch/subprocess files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (let (output
          (run-process ["gxi" "-e" (gxtest-batch-expression files)]
                       directory: package-root
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status
                           (normalized-exit-status exit-status)))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

(def (run-gxtest-batch/compiled-subprocess files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (run-process ["gxi" "-e" (gxtest-compiled-batch-expression files)]
                       directory: package-root
                       stderr-redirection: #t
                       check-status:
                       (lambda (exit-status _settings)
                         (set! status
                           (normalized-exit-status exit-status)))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

(def +compiled-gxtest-eval-lock+ (make-mutex 'compiled-gxtest-eval))

(def (eval-compiled-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-compiled-batch-expression files)
              read)))))

(def (eval-source-gxtest-batch! files)
  (with-lock +compiled-gxtest-eval-lock+
    (lambda ()
      (eval (call-with-input-string
              (gxtest-source-load-batch-expression files)
              read)))))

(def (run-gxtest-batch/compiled-in-process files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (display exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (eval-compiled-gxtest-batch! files)))))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

(def (run-gxtest-batch/source-in-process files)
  (let ((status 0)
        (start-micros (monotonic-micros))
        (label (gxtest-batch-label files)))
    (setenv "GERBIL_PATH" (path-expand ".gerbil" package-root))
    (let (output
          (call-with-output-string
            (lambda (port)
              (with-catch
               (lambda (exn)
                 (set! status 1)
                 (display exn port)
                 (newline port))
               (lambda ()
                 (parameterize ((current-output-port port)
                                (current-error-port port))
                   (eval-source-gxtest-batch! files)))))))
      (list label
            status
            output
            (duration-micros start-micros (monotonic-micros))))))

;; : (-> Path GxTestResult)
(def (run-gxtest-file/subprocess file)
  (run-gxtest-batch/subprocess [file]))

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

(def +runtime-benchmark-gate-symbols+
  '(benchmark-run
    benchmark-contract-run
    benchmark-contract-run/root))

(def (datum-contains-symbol? datum symbol)
  (cond
   ((eq? datum symbol) #t)
   ((pair? datum)
    (or (datum-contains-symbol? (car datum) symbol)
        (datum-contains-symbol? (cdr datum) symbol)))
   (else #f)))

(def (datum-contains-any-symbol? datum symbols)
  (cond
   ((null? symbols) #f)
   ((datum-contains-symbol? datum (car symbols)) #t)
   (else (datum-contains-any-symbol? datum (cdr symbols)))))

(def (gxtest-filter-map proc values)
  (let loop ((rest values) (out []))
    (cond
     ((null? rest) (reverse out))
     (else
      (let (value (proc (car rest)))
        (loop (cdr rest)
              (if value (cons value out) out)))))))

(def (gxtest-any? proc values)
  (cond
   ((null? values) #f)
   ((proc (car values)) #t)
   (else (gxtest-any? proc (cdr values)))))

(def (gxtest-import-symbols datum)
  (cond
   ((symbol? datum) (list datum))
   ((pair? datum)
    (append (gxtest-import-symbols (car datum))
            (gxtest-import-symbols (cdr datum))))
   (else [])))

(def (gxtest-module-symbol-file symbol)
  (let (name (symbol->string symbol))
    (if (string-prefix? ":" name)
      (let* ((module-path (gxtest-normalize-module-path
                           (substring name 1 (string-length name))))
             (relpath (string-append module-path ".ss"))
             (test-path (if (string-prefix? "t/" relpath)
                          relpath
                          (path-expand relpath "t")))
             (source-path (if (string-prefix? "src/" relpath)
                            relpath
                            (path-expand relpath "src"))))
        (cond
         ((file-exists? test-path) test-path)
         ((file-exists? source-path) source-path)
         (else #f)))
      #f)))

(def (gxtest-import-files form)
  (if (and (pair? form)
           (eq? (car form) 'import))
    (gxtest-filter-map
     gxtest-module-symbol-file
     (gxtest-import-symbols (cdr form)))
    []))

(def (gxtest-unique-paths paths)
  (let loop ((rest paths) (seen []) (out []))
    (cond
     ((null? rest) (reverse out))
     ((member (car rest) seen)
      (loop (cdr rest) seen out))
     (else
      (loop (cdr rest)
            (cons (car rest) seen)
            (cons (car rest) out))))))

(def (gxtest-source-file-import-list file)
  (with-catch
   (lambda (_) [])
   (lambda ()
     (let (path (path-expand file package-root))
       (if (file-exists? path)
         (call-with-input-file path
           (lambda (port)
             (let loop ((imports []))
               (let (form (read port))
                 (if (eof-object? form)
                   imports
                   (loop (append imports (gxtest-import-files form))))))))
         [])))))

(def (gxtest-file-source-closure file seen)
  (if (member file seen)
    []
    (cons file
          (gxtest-files-source-closure
           (gxtest-source-file-import-list file)
           (cons file seen)))))

(def (gxtest-files-source-closure files seen)
  (let loop ((queue files) (seen seen) (out []))
    (cond
     ((null? queue) (reverse out))
     ((member (car queue) seen)
      (loop (cdr queue) seen out))
     (else
      (let (file (car queue))
        (loop (append (cdr queue)
                      (gxtest-source-file-import-list file))
              (cons file seen)
              (cons file out)))))))

(def (gxtest-selected-source-files files)
  (gxtest-unique-paths (gxtest-files-source-closure files [])))

(def (gxtest-selected-source-module-files files)
  (gxtest-filter-map
   (lambda (file)
     (and (string-prefix? "src/" file)
          (gxtest-source-module-path file)))
   (gxtest-selected-source-files files)))

(def (gxtest-selected-test-files files)
  (gxtest-filter-map
   (lambda (file)
     (and (string-prefix? "t/" file)
          file))
   (gxtest-selected-source-files files)))

(def (gxtest-source-file-runtime-benchmark-gate? file seen)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (not (member file seen))
          (file-exists? file)
          (call-with-input-file file
            (lambda (port)
              (let loop ()
                (let (form (read port))
                  (cond
                   ((eof-object? form) #f)
                   ((datum-contains-any-symbol?
                     form
                     +runtime-benchmark-gate-symbols+)
                    #t)
                   ((gxtest-any?
                     (lambda (imported-file)
                       (and (string-prefix? "t/" imported-file)
                            (gxtest-source-file-runtime-benchmark-gate?
                             imported-file
                             (cons file seen))))
                     (gxtest-import-files form))
                    #t)
                   (else (loop)))))))))))

;; : (-> Path Boolean)
(def +gxtest-runtime-benchmark-gate-cache+ [])

(def (gxtest-file-runtime-benchmark-gate? file)
  (let (cached (assoc file +gxtest-runtime-benchmark-gate-cache+))
    (if cached
      (cdr cached)
      (let (result (gxtest-source-file-runtime-benchmark-gate? file []))
        (set! +gxtest-runtime-benchmark-gate-cache+
          (cons (cons file result)
                +gxtest-runtime-benchmark-gate-cache+))
        result))))

;; : (-> Path Boolean)
(def (timing-sensitive-gxtest-file? file)
  (let (name (path-strip-directory file))
    (or (string-prefix? "bench" name)
        (string-prefix? "benchmark" name)
        (gxtest-file-runtime-benchmark-gate? file))))

;; : (-> Path Boolean)
(def (source-isolated-gxtest-file? file)
  (timing-sensitive-gxtest-file? file))

;; : (-> Path Boolean)
(def (parallel-gxtest-file? file)
  (not (source-isolated-gxtest-file? file)))

;; : (-> (List Path) (List Path))
(def (parallel-gxtest-files files)
  (filter parallel-gxtest-file? files))

;; : (-> (List Path) (List Path))
(def (serial-gxtest-files files)
  (filter source-isolated-gxtest-file? files))

;; : (-> Integer (-> Void) (List Thread))
(def (spawn-test-workers count thunk)
  (let loop ((remaining count) (threads []))
    (if (<= remaining 0)
      threads
      (loop (- remaining 1)
            (cons (spawn thunk) threads)))))

(def (take-gxtest-batch files count)
  (let loop ((remaining count) (rest files) (batch []))
    (if (or (<= remaining 0) (null? rest))
      (cons (reverse batch) rest)
      (loop (- remaining 1)
            (cdr rest)
            (cons (car rest) batch)))))

(def (gxtest-batches files worker-count)
  (let loop ((rest files)
             (batches [])
             (remaining-batches (max 1 worker-count)))
    (if (null? rest)
      (reverse batches)
      (let* ((remaining-files (length rest))
             (batch-size
              (max 1
                   (quotient (+ remaining-files remaining-batches -1)
                             remaining-batches)))
             (split (take-gxtest-batch rest batch-size))
             (batch (car split))
             (next-rest (cdr split)))
        (loop next-rest
              (cons batch batches)
              (- remaining-batches 1))))))

;; : (-> (List Path) (List GxTestResult))
(def (serial-gxtest-results files)
  (if (null? files)
    []
    (list (record-gxtest-result (run-gxtest-batch/subprocess files)))))

;; : (-> (List Path) Integer (List GxTestResult))
(def (parallel-gxtest-results files worker-count)
  (let* ((items (list->vector (gxtest-batches files worker-count)))
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
                         (record-gxtest-result
                          (run-gxtest-batch/subprocess
                           (vector-ref items index))))
            (loop)))))
    (let (threads (spawn-test-workers worker-count worker))
      (for-each thread-join! threads)
      (vector->list results))))

;; : (-> GxTestResult GxTestResult)
(def (record-gxtest-result result)
  (display-test-phase-receipt
   (string-append "run:" (gxtest-result-file result))
   (gxtest-result-elapsed-micros result))
  result)

;; : (-> GxTestResult Void)
(def (display-gxtest-result result)
  (display (gxtest-result-output result)))

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
         (source-in-process?
          (and (= worker-count 1)
               (gxtest-files-local-suite? files)))
         (selected-status
          (and source-in-process?
               (selected-gxtest-build-receipt-status files)))
         (compiled-in-process?
          (and selected-status
               (selected-gxtest-build-current? selected-status)))
         (parallel-results
          (if source-in-process?
            (list (record-gxtest-result
                   (if compiled-in-process?
                     (run-gxtest-batch/compiled-in-process files)
                     (run-gxtest-batch/source-in-process files))))
            (parallel-gxtest-results parallel-files worker-count)))
         (serial-results
          (if source-in-process?
            []
            (serial-gxtest-results serial-files)))
         (results (append parallel-results serial-results))
         (status (first-failure-status results)))
    (display (string-append "[gslph-test-runner] files="
                            (number->string (length files))
                            " jobs="
                            (number->string worker-count)
                            " serial="
                            (number->string (length serial-files))
                            " mode="
                            (if compiled-in-process?
                              "compiled-in-process"
                              (if source-in-process?
                                "source-in-process"
                                "subprocess"))
                            "\n"))
    (force-output)
    (for-each display-gxtest-result results)
    (if (zero? status)
      (begin
        (display "OK\n")
        (force-output))
      (exit status))))

;; : (-> (List Path) Boolean)
(def (test-target-compile-selected-gxtest? tests)
  #f)

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

;; : (-> (List Path) Void)
(def (run-test-target tests)
  (ensure-build-root!)
  (current-directory package-root)
  (when (null? tests)
    (error "no top-level Gerbil test files found"))
  (let (worker-count (sync-build-worker-count!))
    (run-test-phase
     "compile-package-api"
     (lambda ()
       (compile-package-api-if-stale worker-count))))
  (run-test-phase
   "run-gxtest"
   (lambda ()
     (run-gxtest-files tests))))

;; : (-> Void)
(def (test-target)
  (run-test-target (default-gxtest-test-files)))

;; : (-> (List Path) Void)
(def (test-file-target files)
  (run-test-target files))

;; : (-> Void)
(def (test-full-target)
  (run-test-target (gxtest-test-files)))
