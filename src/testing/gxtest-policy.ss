;;; -*- Gerbil -*-
;;; Scoped policy gate support for gxtest targets.

(import (only-in :std/misc/path directory-files path-directory path-expand)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-suffix?)
        (only-in :std/sugar foldl hash-get hash-put!)
        (only-in "../build-api/package-receipt"
                 gslph-package-build-receipt-status
                 gslph-package-build-receipt-status-ref
                 gslph-package-build-receipt-write)
        (only-in "./gxtest-context"
                 package-root
                 source-root)
        (only-in "./gxtest-discovery"
                 gxtest-selected-source-files)
        (only-in "./gxtest-receipts"
                 ensure-directory!
                 file-set-cache-key)
        :gerbil/gambit)

(export scoped-policy-receipt-path
        scoped-policy-status-line
        scoped-policy-source-files
        scoped-policy-target-files
        run-scoped-policy-if-stale)

;; : (-> (List Path) String)
(def (scoped-policy-cache-key files)
  (file-set-cache-key files))

;; : (-> Path)
(def (scoped-policy-receipt-path (files []))
  (path-expand
   (string-append ".gerbil/build/scoped-policy/"
                  (scoped-policy-cache-key files)
                  ".receipt")
   package-root))

;; : (-> Path Boolean)
(def (gslph-source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (eq? (file-info-type (file-info path)) 'directory))))

;; : (-> Path Boolean)
(def (gslph-gerbil-source-file? path)
  (string-suffix? ".ss" path))

;; : (-> Path Path (List Path))
(def (scoped-policy-directory-source-files directory prefix)
  (apply append
         (map (lambda (entry)
                (let* ((path (path-expand entry directory))
                       (relative
                        (if (string=? prefix "")
                          entry
                          (string-append prefix "/" entry))))
                  (cond
                   ((member entry '("." "..")) [])
                   ((gslph-source-directory? path)
                    (scoped-policy-directory-source-files path relative))
                   ((gslph-gerbil-source-file? entry) [path])
                   (else []))))
              (sort (directory-files directory) string<?))))

;; : (-> (List Path))
(def (scoped-policy-engine-source-files)
  (append
   (scoped-policy-directory-source-files (path-expand "policy" source-root)
                                         "policy")
   (scoped-policy-directory-source-files (path-expand "parser" source-root)
                                         "parser")
   (scoped-policy-directory-source-files (path-expand "types" source-root)
                                         "types")))

;; : (-> (List Path))
(def (scoped-policy-engine-witness-relative-files)
  ["t/policy/agent-dependency-adapter-test.ss"])

;; : (-> (List Path))
(def (scoped-policy-engine-witness-source-files)
  (map (lambda (file)
         (path-expand file package-root))
       (scoped-policy-engine-witness-relative-files)))

;; : (-> (List Path) (List Path))
(def (scoped-policy-unique-paths files)
  (let (state
        (foldl scoped-policy-unique-path-step
               (list (make-hash-table) [])
               files))
    (reverse (cadr state))))

;; : (-> Path (Tuple HashTable (List Path)) (Tuple HashTable (List Path)))
(def (scoped-policy-unique-path-step file state)
  (let ((seen (car state))
        (out (cadr state)))
    (if (hash-get seen file)
      state
      (begin
        (hash-put! seen file #t)
        (list seen (cons file out))))))

;; scoped-policy-target-files
;;   : (-> (List Path) (List Path))
;;   | doc m%
;;       `scoped-policy-target-files` maps the selected gxtest files to the
;;       exact policy source scope.  It preserves incremental behavior by
;;       expanding only the files reachable from the selected tests, plus the
;;       tiny policy-engine witness that keeps the harness gate live.
;;
;;       # Examples
;;
;;       ```scheme
;;       (scoped-policy-target-files ["t/build-install-test.ss"])
;;       ;; => selected source files plus the policy witness
;;       ```
;;     %
(def (scoped-policy-target-files files)
  (let (selected (gxtest-selected-source-files files))
    (scoped-policy-unique-paths
     (append
      (if (null? selected) files selected)
      (scoped-policy-engine-witness-relative-files)))))

;; : (-> (List Path) (List Path))
(def (scoped-policy-source-files files)
  (sort (append
         (scoped-policy-engine-source-files)
         (scoped-policy-engine-witness-source-files)
         (map (lambda (file)
                (path-expand file package-root))
              files))
        string<?))

;; : (-> (List Path) Void)
(def (write-scoped-policy-receipt! files)
  (let (stamp (scoped-policy-receipt-path files))
    (ensure-directory! (path-directory stamp))
    (gslph-package-build-receipt-write
     stamp
     (scoped-policy-source-files files)
     [stamp]
     version: 'gslph-scoped-policy-receipt.v1)))

;; : (-> (List Path) BuildReceiptStatus)
(def (scoped-policy-receipt-status files)
  (let (stamp (scoped-policy-receipt-path files))
    (gslph-package-build-receipt-status
     stamp
     version: 'gslph-scoped-policy-receipt.v1
     expected-sources: (scoped-policy-source-files files)
     expected-outputs: [stamp])))

;; : (-> BuildReceiptStatus Boolean)
(def (scoped-policy-current? status)
  (eq? (gslph-package-build-receipt-status-ref status 'status 'unknown)
       'current))

;; : (-> BuildReceiptStatus String)
(def (scoped-policy-status-line status)
  (string-append
   "[gslph-scoped-policy] status="
   (symbol->string (gslph-package-build-receipt-status-ref status
                                                           'status
                                                           'unknown))
   " reason="
   (let (reason (gslph-package-build-receipt-status-ref status 'reason #f))
     (if reason (symbol->string reason) "none"))
   " sources="
   (number->string
    (gslph-package-build-receipt-status-ref status 'sources 0))
   " outputs="
   (number->string
    (gslph-package-build-receipt-status-ref status 'outputs 0))
   "\n"))

;; : (-> BuildReceiptStatus Void)
(def (display-scoped-policy-status status)
  (display (scoped-policy-status-line status))
  (force-output))

;; : (-> (List Path) Void)
(def (run-scoped-policy! files)
  (add-load-path! ".")
  (add-load-path! "src")
  (add-load-path! "t")
  (load "src/policy/gxtest.ss")
  (let* ((policy-report (eval 'policy-report))
         (display-report (eval 'display-project-policy-report))
         (report (policy-report "." files)))
    (when (not (equal? (hash-get report 'status) "pass"))
      (display-report report)
      (exit 1))))

;; : (-> (List Path) Void)
(def (run-scoped-policy-if-stale files)
  (let (status (scoped-policy-receipt-status files))
    (display-scoped-policy-status status)
    (unless (scoped-policy-current? status)
      (run-scoped-policy! files)
      (write-scoped-policy-receipt! files))))
