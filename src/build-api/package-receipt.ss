;;; -*- Gerbil -*-
;;; Reusable package build freshness receipts.

(import :gerbil/gambit
        (only-in :std/sugar with-catch))

(export gslph-package-build-receipt-version
        gslph-package-build-receipt-write
        gslph-package-build-receipt-read
        gslph-package-build-receipt-current?
        gslph-package-build-receipt-status
        gslph-package-build-receipt-status-ref
        gslph-package-build-receipt-status-line)

;; : Symbol
(def gslph-package-build-receipt-version 'gslph-package-build-receipt.v1)

;; : (-> Alist Symbol Value Value)
(def (gslph-package-build-receipt-ref receipt key default)
  (let (entry (assq key receipt))
    (if entry (cdr entry) default)))

;; gslph-package-build-receipt-path-list?
;;   : (-> ReceiptPathListCandidate Boolean)
;;   | doc m%
;;       `gslph-package-build-receipt-path-list?` validates the receipt path
;;       list shape before freshness checks inspect the filesystem.
;;
;;       # Examples
;;
;;       ```scheme
;;       (gslph-package-build-receipt-path-list? ["src/a.ss"])
;;       ;; => #t
;;       ```
;;     %
(def (gslph-package-build-receipt-path-list? value)
  (and (list? value)
       (andmap string? value)))

;; : (-> Path Integer)
(def (gslph-package-build-receipt-file-seconds path)
  (time->seconds (file-info-last-modification-time (file-info path))))

;; : (-> Path Path Boolean)
(def (gslph-package-build-receipt-file-newer-than? path stamp)
  (> (gslph-package-build-receipt-file-seconds path)
     (gslph-package-build-receipt-file-seconds stamp)))

;; gslph-package-build-receipt-all-exist?
;;   : (-> (List Path) Boolean)
;;   | doc m%
;;       `gslph-package-build-receipt-all-exist?` owns the output existence
;;       predicate for receipt freshness.
;;
;;       # Examples
;;
;;       ```scheme
;;       (gslph-package-build-receipt-all-exist? outputs)
;;       ;; => #t
;;       ```
;;     %
(def (gslph-package-build-receipt-all-exist? paths)
  (andmap file-exists? paths))

;; : (-> Path (List Path) (List Path) version: Symbol Void)
(def (gslph-package-build-receipt-write stamp sources outputs
                                        version: (version gslph-package-build-receipt-version))
  (call-with-output-file stamp
    (lambda (port)
      (write `((version . ,version)
               (sources . ,sources)
               (outputs . ,outputs))
             port)
      (newline port))))

;; : (-> Path version: Symbol (Maybe Pair))
(def (gslph-package-build-receipt-read stamp
                                       version: (version gslph-package-build-receipt-version))
  (and (file-exists? stamp)
       (with-catch
        (lambda (_) #f)
        (lambda ()
          (let* ((receipt (call-with-input-file stamp read))
                 (receipt-version
                  (and (list? receipt)
                       (gslph-package-build-receipt-ref receipt 'version #f)))
                 (sources
                  (and (list? receipt)
                       (gslph-package-build-receipt-ref receipt 'sources #f)))
                 (outputs
                  (and (list? receipt)
                       (gslph-package-build-receipt-ref receipt 'outputs #f))))
            (and (eq? receipt-version version)
                 (gslph-package-build-receipt-path-list? sources)
                 (gslph-package-build-receipt-path-list? outputs)
                 (cons sources outputs)))))))

;; : (-> (List Path) (List Path) Boolean)
(def (gslph-package-build-receipt-populated? sources outputs)
  (and (pair? sources) (pair? outputs)))

;; : (-> (List Path) (List Path) MaybePathList MaybePathList Boolean)
(def (gslph-package-build-receipt-expected-shape? sources outputs
                                                   expected-sources
                                                   expected-outputs)
  (and (or (not expected-sources) (equal? sources expected-sources))
       (or (not expected-outputs) (equal? outputs expected-outputs))))

;; : (-> Path Path Boolean)
(def (gslph-package-build-receipt-source-current? stamp source)
  (and (file-exists? source)
       (not (gslph-package-build-receipt-file-newer-than? source stamp))))

;; : (-> Path (List Path) Boolean)
(def (gslph-package-build-receipt-sources-current? stamp sources)
  (cond
   ((null? sources) #t)
   ((gslph-package-build-receipt-source-current? stamp (car sources))
    (gslph-package-build-receipt-sources-current? stamp (cdr sources)))
   (else #f)))

;; gslph-package-build-receipt-current?
;;   : (-> Path Pair expected-sources: MaybePathList expected-outputs: MaybePathList Boolean)
;;   | doc m%
;;       `gslph-package-build-receipt-current?` checks receipt shape, expected
;;       source/output lists, output existence, and source freshness.
;;
;;       # Examples
;;
;;       ```scheme
;;       (gslph-package-build-receipt-current? stamp receipt)
;;       ;; => #t
;;       ```
;;     %
(def (gslph-package-build-receipt-current? stamp receipt
                                           expected-sources: (expected-sources #f)
                                           expected-outputs: (expected-outputs #f))
  (let ((sources (car receipt))
        (outputs (cdr receipt)))
    (and (gslph-package-build-receipt-populated? sources outputs)
         (gslph-package-build-receipt-expected-shape? sources
                                                      outputs
                                                      expected-sources
                                                      expected-outputs)
         (gslph-package-build-receipt-all-exist? outputs)
         (gslph-package-build-receipt-sources-current? stamp sources))))

;; : (-> Symbol Symbol Path (Maybe Pair) Alist)
(def (gslph-package-build-receipt-make-status status reason stamp receipt)
  `((status . ,status)
    (reason . ,reason)
    (sources . ,(if receipt (length (car receipt)) 0))
    (outputs . ,(if receipt (length (cdr receipt)) 0))
    (stamp . ,stamp)))

;; : (-> Path version: Symbol expected-sources: MaybePathList expected-outputs: MaybePathList Alist)
(def (gslph-package-build-receipt-status stamp
                                         version: (version gslph-package-build-receipt-version)
                                         expected-sources: (expected-sources #f)
                                         expected-outputs: (expected-outputs #f))
  (cond
   ((not (file-exists? stamp))
    (gslph-package-build-receipt-make-status 'stale 'missing-stamp stamp #f))
   (else
    (let (receipt (gslph-package-build-receipt-read stamp version: version))
      (cond
       ((not receipt)
        (gslph-package-build-receipt-make-status 'stale 'invalid-stamp stamp #f))
       ((gslph-package-build-receipt-current? stamp receipt
                                             expected-sources: expected-sources
                                             expected-outputs: expected-outputs)
        (gslph-package-build-receipt-make-status 'current #f stamp receipt))
       (else
        (gslph-package-build-receipt-make-status
         'stale
         (if (or (and expected-sources (not (equal? (car receipt) expected-sources)))
                 (and expected-outputs (not (equal? (cdr receipt) expected-outputs))))
           'receipt-shape-mismatch
           'dirty-source-or-missing-output)
         stamp
         receipt)))))))

;; : (-> Alist Symbol Value Value)
(def (gslph-package-build-receipt-status-ref status key default)
  (gslph-package-build-receipt-ref status key default))

;; : (-> Alist String)
(def (gslph-package-build-receipt-status-line status)
  (string-append
   "[gslph-package-build-receipt]"
   " status=" (symbol->string (gslph-package-build-receipt-status-ref status 'status 'unknown))
   " sources=" (number->string (gslph-package-build-receipt-status-ref status 'sources 0))
   " outputs=" (number->string (gslph-package-build-receipt-status-ref status 'outputs 0))
   " stamp=" (object->string (gslph-package-build-receipt-status-ref status 'stamp ""))))
