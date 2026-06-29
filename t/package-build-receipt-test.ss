;;; -*- Gerbil -*-
;;; Package build receipt API tests.

(import :gerbil/gambit
        :std/test
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/srfi/13 string-prefix?)
        "../src/build-api/package-receipt")

(export package-build-receipt-test)

;; : Path
(def +package-build-receipt-test-root+
  (path-expand ".cache/agent-semantic-protocol/test/package-build-receipt"
               (current-directory)))

;; package-build-receipt-strip-trailing-slashes
;;   : (-> Path Path)
;;   | doc m%
;;       `package-build-receipt-strip-trailing-slashes` normalizes fixture
;;       directory paths before recursive directory creation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (package-build-receipt-strip-trailing-slashes "a/b/")
;;       ;; => "a/b"
;;       ```
;;     %
(def (package-build-receipt-strip-trailing-slashes path)
  (package-build-receipt-strip-trailing-slashes/end path
                                                   (string-length path)))

;; : (-> Path Integer Path)
(def (package-build-receipt-strip-trailing-slashes/end path end)
  (if (and (> end 1)
           (char=? (string-ref path (- end 1)) #\/))
    (package-build-receipt-strip-trailing-slashes/end path (- end 1))
    (substring path 0 end)))

;; : (-> String Void)
(def (package-build-receipt-ensure-directory* path)
  (let (path (and path (package-build-receipt-strip-trailing-slashes path)))
    (when path
      (unless (or (string=? path "")
                  (string=? path ".")
                  (file-exists? path))
        (let (parent (path-directory path))
          (when (and parent (not (string=? parent path)))
            (package-build-receipt-ensure-directory* parent)))
        (unless (file-exists? path)
          (create-directory path))))))

;; : (-> Path String Void)
(def (package-build-receipt-write-file path content)
  (package-build-receipt-ensure-directory* (path-directory path))
  (call-with-output-file path
    (lambda (port)
      (display content port)
      (newline port))))

;; : (-> String Path)
(def (package-build-receipt-path name)
  (path-expand name +package-build-receipt-test-root+))

;; : (-> Void)
(def (package-build-receipt-reset!)
  (package-build-receipt-ensure-directory* +package-build-receipt-test-root+))

;; : TestSuite
(def package-build-receipt-test
  (test-suite "package build receipt api"
    (test-case "creates nested cache directories from a fresh parent"
      (let (fresh (package-build-receipt-path "fresh-parent/nested/leaf"))
        (package-build-receipt-ensure-directory* fresh)
        (check (file-exists? fresh) => #t)))
    (test-case "reports current when sources and outputs match the receipt"
      (package-build-receipt-reset!)
      (let* ((source (package-build-receipt-path "current/source.ss"))
             (output (package-build-receipt-path "current/source.ssi"))
             (stamp (package-build-receipt-path "current/build.sexp")))
        (package-build-receipt-write-file source "source")
        (package-build-receipt-write-file output "output")
        (gslph-package-build-receipt-write stamp [source] [output])
        (let (status (gslph-package-build-receipt-status stamp))
          (check (gslph-package-build-receipt-status-ref status 'status #f)
                 => 'current)
          (check (gslph-package-build-receipt-status-ref status 'sources #f)
                 => 1)
          (check (gslph-package-build-receipt-status-ref status 'outputs #f)
                 => 1)
          (check (string-prefix?
                  "[gslph-package-build-receipt] status=current"
                  (gslph-package-build-receipt-status-line status))
                 => #t))))
    (test-case "reports stale when an output is missing"
      (package-build-receipt-reset!)
      (let* ((source (package-build-receipt-path "missing-output/source.ss"))
             (output (package-build-receipt-path "missing-output/source.ssi"))
             (stamp (package-build-receipt-path "missing-output/build.sexp")))
        (package-build-receipt-write-file source "source")
        (gslph-package-build-receipt-write stamp [source] [output])
        (let (status (gslph-package-build-receipt-status stamp))
          (check (gslph-package-build-receipt-status-ref status 'status #f)
                 => 'stale)
          (check (gslph-package-build-receipt-status-ref status 'reason #f)
                 => 'dirty-source-or-missing-output))))
    (test-case "reports stale when expected receipt shape changed"
      (package-build-receipt-reset!)
      (let* ((source (package-build-receipt-path "shape/source.ss"))
             (new-source (package-build-receipt-path "shape/new-source.ss"))
             (output (package-build-receipt-path "shape/source.ssi"))
             (stamp (package-build-receipt-path "shape/build.sexp")))
        (package-build-receipt-write-file source "source")
        (package-build-receipt-write-file new-source "new source")
        (package-build-receipt-write-file output "output")
        (gslph-package-build-receipt-write stamp [source] [output])
        (let (status (gslph-package-build-receipt-status
                      stamp
                      expected-sources: [source new-source]
                      expected-outputs: [output]))
          (check (gslph-package-build-receipt-status-ref status 'status #f)
                 => 'stale)
          (check (gslph-package-build-receipt-status-ref status 'reason #f)
                 => 'receipt-shape-mismatch))))
    (test-case "reports stale for missing or invalid receipts"
      (package-build-receipt-reset!)
      (let ((missing (package-build-receipt-path "missing/build.sexp"))
            (invalid (package-build-receipt-path "invalid/build.sexp")))
        (let (missing-status (gslph-package-build-receipt-status missing))
          (check (gslph-package-build-receipt-status-ref missing-status 'status #f)
                 => 'stale)
          (check (gslph-package-build-receipt-status-ref missing-status 'reason #f)
                 => 'missing-stamp))
        (package-build-receipt-write-file invalid "not-a-valid-receipt")
        (let (invalid-status (gslph-package-build-receipt-status invalid))
          (check (gslph-package-build-receipt-status-ref invalid-status 'status #f)
                 => 'stale)
          (check (gslph-package-build-receipt-status-ref invalid-status 'reason #f)
                 => 'invalid-stamp))))))
