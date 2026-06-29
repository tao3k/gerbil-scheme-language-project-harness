;;; -*- Gerbil -*-
;;; Gxtest source discovery, exported suite introspection, and batch planning.

(import (only-in :std/misc/path path-expand path-strip-directory)
        (only-in :std/srfi/1 append-map any every find iota split-at)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar filter-map foldl)
        (only-in "./gxtest-context"
                 package-root
                 package-name
                 gxtest-normalize-module-path
                 gxtest-source-module-path
                 module-path-stem)
        :gerbil/gambit)

(export gxtest-export-symbols
        gxtest-file-forms
        gxtest-file-exported-symbols
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-files-local-suite?
        gxtest-file-module-symbol
        gxtest-selected-source-files
        gxtest-selected-source-module-files
        gxtest-selected-test-files
        parallel-gxtest-files
        serial-gxtest-files
        gxtest-batches)

(def (gxtest-export-symbols form)
  (if (and (pair? form)
           (eq? (car form) 'export))
    (gxtest-filter-map
     (lambda (item)
       (and (symbol? item) item))
     (cdr form))
    []))

(def (gxtest-read-forms port)
  (read-all port))

(def (gxtest-file-forms file)
  (call-with-input-file (path-expand file package-root)
    gxtest-read-forms))

(def (gxtest-suite-symbol? symbol)
  (string-suffix? "-test" (symbol->string symbol)))

(def (gxtest-first pred values)
  (find pred values))

(def (gxtest-file-exported-symbols file)
  (gxtest-append-map gxtest-export-symbols
                     (gxtest-file-forms file)))

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
  (gxtest-filter-map gxtest-def-symbol
                     (gxtest-file-forms file)))

(def (gxtest-file-local-suite? file)
  (member (gxtest-file-exported-suite file)
          (gxtest-file-local-def-symbols file)))

(def (gxtest-files-local-suite? files)
  (if (every gxtest-file-local-suite? files) #t #f))

(def (gxtest-file-module-symbol file)
  (unless package-name
    (error "gerbil.pkg must declare package: for gxtest module import"))
  (string->symbol
   (string-append ":"
                  package-name
                  "/"
                  (module-path-stem file))))

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
  (if (any (lambda (symbol)
             (datum-contains-symbol? datum symbol))
           symbols)
    #t
    #f))

(def (gxtest-filter-map proc values)
  (filter-map proc values))

(def (gxtest-append-map proc values)
  (append-map proc values))

(def (gxtest-any? proc values)
  (if (any proc values) #t #f))

(def (gxtest-import-symbols datum)
  (cond
   ((symbol? datum) (list datum))
   ((pair? datum)
    (append (gxtest-import-symbols (car datum))
            (gxtest-import-symbols (cdr datum))))
   (else [])))

(def (gxtest-module-relpath module-path)
  (string-append module-path ".ss"))

(def (gxtest-module-candidate-path prefix relpath)
  (if (string-prefix? prefix relpath)
    relpath
    (path-expand relpath prefix)))

(def (gxtest-existing-module-path test-path source-path)
  (or (and (file-exists? test-path) test-path)
      (and (file-exists? source-path) source-path)))

(def (gxtest-module-path-file module-path)
  (let* ((relpath (gxtest-module-relpath module-path))
         (test-path (gxtest-module-candidate-path "t/" relpath))
         (source-path (gxtest-module-candidate-path "src/" relpath)))
    (gxtest-existing-module-path test-path source-path)))

(def (gxtest-module-symbol-file symbol)
  (let (name (symbol->string symbol))
    (and (string-prefix? ":" name)
         (gxtest-module-path-file
          (gxtest-normalize-module-path
           (substring name 1 (string-length name)))))))

(def (gxtest-import-files form)
  (if (and (pair? form)
           (eq? (car form) 'import))
    (gxtest-filter-map
     gxtest-module-symbol-file
     (gxtest-import-symbols (cdr form)))
    []))

(def (gxtest-unique-paths paths)
  (let (state (foldl gxtest-unique-path-step '(() ()) paths))
    (reverse (cadr state))))

(def (gxtest-unique-path-step path state)
  (let ((seen (car state))
        (out (cadr state)))
    (if (member path seen)
      state
      (list (cons path seen)
            (cons path out)))))

(def (gxtest-source-file-import-list file)
  (with-catch
   (lambda (_) [])
   (lambda ()
     (if (file-exists? (path-expand file package-root))
       (gxtest-append-map gxtest-import-files
                          (gxtest-file-forms file))
       []))))

(def (gxtest-file-source-closure file seen)
  (if (member file seen)
    []
    (cons file
          (gxtest-files-source-closure
           (gxtest-source-file-import-list file)
           (cons file seen)))))

(def (gxtest-source-queue files)
  (cons files []))

(def (gxtest-source-queue-empty)
  (cons [] []))

(def (gxtest-source-queue-pop queue)
  (let ((front (car queue))
        (rear (cdr queue)))
    (cond
     ((and (null? front) (null? rear))
      (values #f (gxtest-source-queue-empty)))
     ((null? front)
      (gxtest-source-queue-pop (cons (reverse rear) [])))
     (else
      (values (car front) (cons (cdr front) rear))))))

(def (gxtest-source-queue-push-list queue files)
  (cons (car queue)
        (foldl (lambda (file rear)
                 (cons file rear))
               (cdr queue)
               files)))

;; gxtest-files-source-closure
;;   : (-> (List Path) (List Path) (List Path))
;;   | doc m%
;;       `gxtest-files-source-closure` walks selected test files and their
;;       imported source/test modules with a FIFO queue so dependency discovery
;;       preserves stable order without loop-local `append` growth.
;;     %
(def (gxtest-files-source-closure files seen)
  (let loop ((queue (gxtest-source-queue files))
             (seen seen)
             (out []))
    (call-with-values
      (lambda () (gxtest-source-queue-pop queue))
      (lambda (file queue)
        (cond
         ((not file) (reverse out))
         ((member file seen)
          (loop queue seen out))
         (else
          (loop (gxtest-source-queue-push-list
                 queue
                 (gxtest-source-file-import-list file))
                (cons file seen)
                (cons file out))))))))

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

(def (gxtest-runtime-benchmark-import-gate? file seen form)
  (gxtest-any?
   (lambda (imported-file)
     (and (string-prefix? "t/" imported-file)
          (gxtest-source-file-runtime-benchmark-gate?
           imported-file
           (cons file seen))))
   (gxtest-import-files form)))

(def (gxtest-runtime-benchmark-form? file seen form)
  (or (datum-contains-any-symbol?
       form
       +runtime-benchmark-gate-symbols+)
      (gxtest-runtime-benchmark-import-gate? file seen form)))

(def (gxtest-source-file-runtime-benchmark-gate? file seen)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (not (member file seen))
          (file-exists? file)
          (call-with-input-file file
            (lambda (port)
              (gxtest-any?
               (lambda (form)
                 (gxtest-runtime-benchmark-form? file seen form))
               (read-all port))))))))

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

(def (gxtest-next-batch-size remaining-files remaining-batches)
  (max 1
       (quotient (+ remaining-files remaining-batches -1)
                 remaining-batches)))

(def (gxtest-batch-size-step _ state)
  (let ((remaining-files (car state))
        (remaining-batches (cadr state))
        (sizes (caddr state)))
    (if (<= remaining-files 0)
      (list 0 (- remaining-batches 1) sizes)
      (let (batch-size
            (gxtest-next-batch-size remaining-files remaining-batches))
        (list (- remaining-files batch-size)
              (- remaining-batches 1)
              (cons batch-size sizes))))))

(def (gxtest-batch-sizes file-count worker-count)
  (reverse
   (caddr
    (foldl gxtest-batch-size-step
           (list file-count (max 1 worker-count) [])
           (iota (max 1 worker-count))))))

(def (gxtest-batch-split-step size state)
  (call-with-values
    (lambda () (split-at (car state) size))
    (lambda (batch rest)
      (list rest (cons batch (cadr state))))))

(def (gxtest-batches files worker-count)
  (reverse
   (cadr
    (foldl gxtest-batch-split-step
           (list files [])
           (gxtest-batch-sizes (length files) worker-count)))))
