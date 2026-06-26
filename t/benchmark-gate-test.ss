;;; -*- Gerbil -*-
;;; Boundary: upstream benchmark gate helpers stay reusable by downstream tests.

(import :gerbil/gambit
        :std/sort
        :std/test
        (only-in :commands/check check-main)
        (rename-in :cli-launcher (main launcher-main))
        (only-in :std/misc/process run-process)
        (only-in :std/sugar ormap)
        (only-in :support/time monotonic-ms duration-ms)
        :benchmark/gate)

(export benchmark-gate-test)

;; : Alist
(def benchmark-gate-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-R000
   'fixture-gate
   "reusable benchmark gate"
   "small deterministic thunk"
   "return a pass/fail receipt"
   '(benchmark gate test)))

;; : Alist
(def benchmark-gate-fail-fixture
  (cons (cons 'maxTotalMs 0)
        (cdr benchmark-gate-fixture)))

;; : (-> Symbol Alist Alist)
(def (benchmark-gate-without key fixture)
  (filter (lambda (entry) (not (eq? (car entry) key)))
          fixture))

;; : (-> Symbol Value Alist Alist)
(def (benchmark-gate-with key value fixture)
  (cons (cons key value)
        (benchmark-gate-without key fixture)))

;; : Alist
(def benchmark-gate-missing-observed-fixture
  (benchmark-gate-without 'observedTimings benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-invalid-observed-fixture
  (cons (cons 'observedTimings
              '(((name . measure-best) (durationMs . -1))))
        (benchmark-gate-without 'observedTimings benchmark-gate-fixture)))

;; : Alist
(def benchmark-gate-subsecond-fixture
  (benchmark-gate-with
   'maxTotalMs
   0.75
   (benchmark-gate-with
    'observedTotalMs
    0.25
    (benchmark-gate-with
     'targetTotalMs
     0.5
     (benchmark-gate-with
      'regressionBudgetMs
      0.25
      (benchmark-gate-with
       'observedTimings
       '(((name . collect-before) (durationMs . 0.125))
         ((name . policy-before) (durationMs . 0.125)))
       benchmark-gate-fixture))))))

;; : Alist
(def benchmark-gate-slow-hot-fixture
  (benchmark-gate-with
   'targetTotalMs
   100
   benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-integration-fixture
  (benchmark-gate-with
   'tags
   '(gxtest import-closure)
   (benchmark-gate-with
    'maxTotalMs
    200
    (benchmark-gate-with
     'targetTotalMs
     100
     (benchmark-gate-with
      'observedTotalMs
      80
      benchmark-gate-fixture)))))

;; : Alist
(def benchmark-gate-slow-integration-fixture
  (benchmark-gate-with
   'maxTotalMs
   1000
   benchmark-gate-integration-fixture))

;; Relpath
(def +benchmark-gate-scenario-root+ "t/scenarios/policy")

;; Relpath
(def +check-cache-gate-root+
  (path-expand ".cache/agent-semantic-protocol/test/check-cache-gate"
               (current-directory)))

;; Relpath
(def +check-cache-gate-cache-path+
  (path-expand ".cache/agent-semantic-protocol/gerbil-scheme/check/text.sexp"
               +check-cache-gate-root+))

(def +changed-empty-gate-root+
  (path-expand ".cache/agent-semantic-protocol/test/check-changed-empty-gate"
               (current-directory)))

;; Integer
(def +check-cache-gate-max-warm-ms+ 100)

;; Integer
(def +check-cache-gate-max-launcher-warm-ms+ 100)

;;; Boundary:
;;; - Empty changed-scope launcher checks measured 135-191ms on the package
;;;   runtime path; keep the gate subsecond while avoiding scheduler noise.
;; : Integer
(def +check-cache-gate-max-launcher-changed-ms+ 250)

;; : (-> Path Boolean)
(def (benchmark-gate-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean)
(def (benchmark-gate-scenario-entry? entry)
  (not (ormap (lambda (blocked)
                (equal? entry blocked))
              '("." ".."))))

;; : (-> Path (List Path))
(def (benchmark-gate-scenario-benchmark-paths/root root)
  (let (paths [])
    (def (walk dir)
      (for-each
       (lambda (entry)
         (let (path (path-expand entry dir))
           (cond
            ((not (benchmark-gate-scenario-entry? entry))
             #!void)
            ((benchmark-gate-directory? path)
             (walk path))
            ((equal? entry "benchmark.ss")
             (set! paths (cons path paths)))
            (else #!void))))
       (sort (directory-files dir) string<?)))
    (walk root)
    (reverse paths)))

;; : (-> (List Path))
(def (benchmark-gate-scenario-benchmark-paths)
  (benchmark-gate-scenario-benchmark-paths/root
   +benchmark-gate-scenario-root+))

;; : (-> Path Alist)
(def (benchmark-gate-read-fixture path)
  (call-with-input-file path
    (lambda (port)
      (read port))))

;; trim-trailing-slashes
;;   : (-> String String)
;;   | doc m%
;;       `trim-trailing-slashes path` normalizes a directory path before the
;;       recursive fixture creator checks parents.
;;
;;       # Examples
;;       ```scheme
;;       (trim-trailing-slashes "tmp/cache/")
;;       ;; => "tmp/cache"
;;       ```
;;     %
(def (trim-trailing-slashes path)
  (let loop ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (loop (- end 1))
      (substring path 0 end))))

;; : (-> Path Void)
(def (ensure-directory* path)
  (when path
    (let (dir (trim-trailing-slashes path))
      (unless (or (string=? dir "")
                  (string=? dir ".")
                  (file-exists? dir))
        (let (parent (path-directory dir))
          (when (and parent
                     (not (string=? parent dir)))
            (ensure-directory* parent)))
        (unless (file-exists? dir)
          (create-directory dir))))))

;; : (-> Path Void)
(def (delete-file* path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (when (file-exists? path)
       (delete-file path)))))

;; : (-> Path String Void)
(def (write-text-file path text)
  (delete-file* path)
  (ensure-directory* (path-directory path))
  (call-with-output-file path
    (lambda (out) (display text out))))

;; : (-> Void)
(def (prepare-check-cache-gate-project!)
  (ensure-directory* +check-cache-gate-root+)
  (ensure-directory* (path-expand "src" +check-cache-gate-root+))
  (delete-file* +check-cache-gate-cache-path+)
  (write-text-file
   (path-expand "gerbil.pkg" +check-cache-gate-root+)
   ";;; Boundary:\n;;; - Package fixture isolates cache replay from source discovery drift.\n;;; - Keep the runtime scope to one deterministic source module.\n(package: check-cache-gate)\n")
  (write-text-file
   (path-expand "src/core.ss" +check-cache-gate-root+)
   ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - Cache gate fixture keeps one deterministic runtime export.\n;;; - No IO, macro expansion, or dynamic imports belong in this timing scope.\n(import :gerbil/gambit)\n(export add1*)\n;;; Boundary:\n;;; - add1* is intentionally pure so full-check timing measures cache replay.\n;;; - Preserve this helper as a single arithmetic operation.\n;; : (-> Integer Integer)\n(def (add1* n) (+ n 1))\n"))

;; : (-> Void)
(def (prepare-changed-empty-gate-project!)
  (ensure-directory* +changed-empty-gate-root+)
  (write-text-file
   (path-expand "README.md" +changed-empty-gate-root+)
   "non-gerbil change\n")
  (run-process ["git" "init"]
               directory: +changed-empty-gate-root+
               stdout-redirection: #t
               stderr-redirection: #t
               check-status: void))

;; : (-> (-> Integer) Alist)
(def (run-check-command/silent thunk)
  (let* ((start-ms (monotonic-ms))
         (status
          (parameterize ((current-output-port (open-output-string)))
            (thunk)))
         (elapsed-ms (duration-ms start-ms (monotonic-ms))))
    (list (cons 'status status)
          (cons 'elapsedMs elapsed-ms))))

;; run-check-command/silent/best
;;   : (-> Integer (-> Integer) Alist)
;;   | doc m%
;;       `run-check-command/silent/best attempts thunk` returns the fastest
;;       successful timing receipt from a small repeated benchmark window.
;;
;;       # Examples
;;
;;       ```scheme
;;       (benchmark-fixture-ref
;;        (run-check-command/silent/best 3 (lambda () 0))
;;        'status)
;;       ;; => 0
;;       ```
;;     %
(def (run-check-command/silent/best attempts thunk)
  (if (<= attempts 0)
    (error "check benchmark attempts must be positive" attempts)
    (let loop ((remaining attempts) (best #f))
      (if (zero? remaining)
        best
        (let (receipt (run-check-command/silent thunk))
          (loop (- remaining 1)
                (if (or (not best)
                        (< (benchmark-fixture-ref receipt 'elapsedMs)
                           (benchmark-fixture-ref best 'elapsedMs)))
                  receipt
                  best)))))))

;; : (-> Path Alist)
(def (run-check-full/silent root)
  (run-check-command/silent
   (lambda ()
     (check-main ["--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-check-full/silent/best root)
  (run-check-command/silent/best
   3
   (lambda ()
     (check-main ["--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-launcher-check-full/silent root)
  (run-check-command/silent
   (lambda ()
     (apply launcher-main ["check" "--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-launcher-check-full/silent/best root)
  (run-check-command/silent/best
   3
   (lambda ()
     (apply launcher-main ["check" "--workspace" root "--full"]))))

;; : (-> Path Alist)
(def (run-launcher-check-changed/silent root)
  (run-check-command/silent/best
   3
   (lambda ()
     (apply launcher-main ["check" "changed" "--view" "seeds" root]))))

;; : TestSuite
(def benchmark-gate-test
  (test-suite "gerbil scheme benchmark gate"
    (test-case "fixture carries reusable gate metadata"
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxTotalMs)
             => 100)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxRssMb)
             => 512)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryMetric)
             => 'resident-set-size)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryUnit)
             => "MB")
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedTotalMs)
             => 10)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'targetTotalMs)
             => 25)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'regressionBudgetMs)
             => 15)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedTimings)
             => '(((name . measure-best) (durationMs . 10))))
      (check (benchmark-fixture-ref benchmark-gate-fixture 'targetRationale)
             => "default generated benchmark fixture target")
      (check (member 'assert-memory-gate
                     (benchmark-fixture-ref benchmark-gate-fixture
                                            'measurementPhases))
             => '(assert-memory-gate))
      (check (benchmark-fixture-ref benchmark-gate-fixture 'iterations) => 3)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'tags)
             => '(benchmark gate test))
      (check (benchmark-fixture-missing-keys benchmark-gate-fixture) => [])
      (check (benchmark-fixture-memory-contract-pass? benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass? benchmark-gate-fixture) => #t))

    (test-case "observed timing baseline is required by the gate contract"
      (check (benchmark-fixture-missing-keys
              benchmark-gate-missing-observed-fixture)
             => '(observedTimings))
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-missing-observed-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-missing-observed-fixture)
             => #f)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-invalid-observed-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-invalid-observed-fixture)
             => #f))

    (test-case "subsecond timing baselines satisfy the gate contract"
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'maxTotalMs)
             => 0.75)
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'observedTotalMs)
             => 0.25)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t))

    (test-case "benchmark timing class separates hot policy and integration scope"
      (check (benchmark-fixture-integration-scope?
              benchmark-gate-fixture)
             => #f)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-slow-hot-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-slow-hot-fixture)
             => #f)
      (check (benchmark-fixture-integration-scope?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-integration-fixture)
             => #t)
      (check (benchmark-fixture-timing-class-contract-pass?
              benchmark-gate-slow-integration-fixture)
             => #f))

    (test-case "scenario benchmark fixtures satisfy the shared gate contract"
      (let (paths (benchmark-gate-scenario-benchmark-paths))
        (check (> (length paths) 0) => #t)
        (for-each
         (lambda (path)
           (let (fixture (benchmark-gate-read-fixture path))
             (check (benchmark-fixture-missing-keys fixture) => [])
             (check (benchmark-fixture-memory-contract-pass? fixture) => #t)
             (check (benchmark-fixture-contract-pass? fixture) => #t)))
         paths)))

    (test-case "run returns pass receipt under threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'feature)
               => 'fixture-gate)
        (check (benchmark-fixture-ref receipt 'maxRssMb)
               => 512)
        (check (benchmark-fixture-ref receipt 'memoryMetric)
               => 'resident-set-size)
        (check (benchmark-fixture-ref receipt 'memoryUnit)
               => "MB")
        (check (>= (benchmark-fixture-ref receipt 'elapsedMicros) 0)
               => #t)
        (check (benchmark-fixture-ref receipt 'observedTotalMs)
               => 10)
        (check (benchmark-fixture-ref receipt 'targetTotalMs)
               => 25)
        (check (benchmark-fixture-ref receipt 'regressionBudgetMs)
               => 15)
        (check (benchmark-fixture-ref receipt 'observedTimings)
               => '(((name . measure-best) (durationMs . 10))))
        (check (benchmark-fixture-ref receipt 'targetRationale)
               => "default generated benchmark fixture target")
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "run returns fail receipt at zero threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fail-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'maxTotalMs) => 0)
        (check (benchmark-receipt-pass? receipt) => #f)))

    (test-case "check full cache stays in millisecond budget"
      (prepare-check-cache-gate-project!)
      (let* ((cold (run-check-full/silent +check-cache-gate-root+))
             (warm (run-check-full/silent/best +check-cache-gate-root+))
             (launcher-warm
              (run-launcher-check-full/silent/best +check-cache-gate-root+)))
        (check (benchmark-fixture-ref cold 'status) => 0)
        (check (benchmark-fixture-ref warm 'status) => 0)
        (check (benchmark-fixture-ref launcher-warm 'status) => 0)
        (check (< (benchmark-fixture-ref warm 'elapsedMs)
                  +check-cache-gate-max-warm-ms+)
               => #t)
        (check (< (benchmark-fixture-ref launcher-warm 'elapsedMs)
                  +check-cache-gate-max-launcher-warm-ms+)
               => #t)))

    (test-case "check changed empty Gerbil scope stays in launcher millisecond budget"
      (prepare-changed-empty-gate-project!)
      (let (changed (run-launcher-check-changed/silent +changed-empty-gate-root+))
        (check (benchmark-fixture-ref changed 'status) => 0)
        (check (< (benchmark-fixture-ref changed 'elapsedMs)
                  +check-cache-gate-max-launcher-changed-ms+)
               => #t)))))
