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

(import :gslph/src/testing/memory-profile)

;; : (-> Path Boolean)
(def (timing-sensitive-gxtest-file? file)
  (gxtest-file-memory-exception? file))

;; : (-> Path Boolean)
(def (source-isolated-gxtest-file? file)
  (gxtest-file-memory-exception? file))

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
