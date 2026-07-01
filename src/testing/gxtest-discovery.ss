;;; -*- Gerbil -*-
;;; Gxtest discovery facade and batch planning.

(import (only-in :std/misc/path path-strip-directory)
        (only-in :std/srfi/1 any iota split-at)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar foldl hash-get hash-key? hash-put!)
        (only-in "./gxtest-syntax"
                 gxtest-export-symbols
                 gxtest-file-forms-path
                 gxtest-file-forms
                 gxtest-file-exported-symbols
                 gxtest-file-exported-suite?
                 gxtest-file-exported-suite
                 gxtest-file-self-running?
                 gxtest-file-local-suite?
                 gxtest-files-local-suite?
                 gxtest-file-module-symbol)
        (only-in "./gxtest-sources"
                 compiled-in-process-gxtest-file?
                 gxtest-import-files
                 gxtest-selected-source-files
                 gxtest-selected-source-module-files
                 gxtest-selected-test-files)
        :gerbil/gambit)

(export gxtest-export-symbols
        gxtest-file-forms
        gxtest-file-exported-symbols
        gxtest-file-exported-suite
        gxtest-file-local-suite?
        gxtest-files-local-suite?
        gxtest-file-module-symbol
        compiled-in-process-gxtest-file?
        gxtest-selected-source-files
        gxtest-selected-source-module-files
        gxtest-selected-test-files
        source-isolated-gxtest-file?
        parallel-gxtest-files
        serial-gxtest-files
        gxtest-batches)

(def +runtime-benchmark-gate-symbols+
  '(benchmark-run
    benchmark-contract-run
    benchmark-contract-run/root
    policy-scenario-run/timed))

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

(def (gxtest-any? proc values)
  (if (any proc values) #t #f))

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
          (file-exists? (gxtest-file-forms-path file))
          (gxtest-any?
           (lambda (form)
             (gxtest-runtime-benchmark-form? file seen form))
           (gxtest-file-forms file))))))

;; : (-> Path Boolean)
(def +gxtest-runtime-benchmark-gate-cache+
  (make-hash-table))

(def (gxtest-file-runtime-benchmark-gate? file)
  (if (hash-key? +gxtest-runtime-benchmark-gate-cache+ file)
    (hash-get +gxtest-runtime-benchmark-gate-cache+ file)
    (let (result (gxtest-source-file-runtime-benchmark-gate? file []))
      (hash-put! +gxtest-runtime-benchmark-gate-cache+ file result)
      result)))

;; : (-> Path Boolean)
(def (timing-sensitive-gxtest-file? file)
  (let (name (path-strip-directory file))
    (or (string-prefix? "bench" name)
        (string-prefix? "benchmark" name)
        (string=? name "gxtest-runner-contract-test.ss")
        (gxtest-file-runtime-benchmark-gate? file))))

;; : (-> Path Boolean)
(def (source-isolated-gxtest-file? file)
  (string=? (path-strip-directory file)
            "gxtest-runner-contract-test.ss"))

;; : (-> Path Boolean)
(def (parallel-gxtest-file? file)
  (not (timing-sensitive-gxtest-file? file)))

;; : (-> (List Path) (List Path))
(def (parallel-gxtest-files files)
  (filter parallel-gxtest-file? files))

;; : (-> (List Path) (List Path))
(def (serial-gxtest-files files)
  (filter timing-sensitive-gxtest-file? files))

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
