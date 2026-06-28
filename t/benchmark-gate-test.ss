;;; -*- Gerbil -*-
;;; Boundary: upstream benchmark gate helpers stay reusable by downstream tests.

(import :gerbil/gambit
        :std/sort
        :std/test
        (only-in :commands/check check-main)
        (rename-in :cli-release-linker (main launcher-main))
        (only-in :std/misc/process run-process)
        (only-in :std/sugar ormap)
        (only-in :support/time
                 duration-literal->nanos
                 monotonic-ms
                 duration-ms)
        :benchmark/gate)

(export benchmark-gate-test)

;; : Alist
(def benchmark-gate-fixture
  (make-benchmark-fixture
   'GERBIL-SCHEME-AGENT-POLICY-000
   'fixture-gate
   "reusable benchmark gate"
   "small deterministic thunk"
   "return a pass/fail receipt"
   '(benchmark gate test)))

;; : Alist
(def benchmark-gate-fail-fixture
  (cons (cons 'max_total '0ns)
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
(def benchmark-gate-slow-expected-fixture
  (benchmark-gate-with
   'expected_over_input_budget
   '1ms
   (benchmark-gate-with
    'observedTimings
    '(((name . collect-before) (durationMs . 1))
      ((name . policy-before) (durationMs . 0))
      ((name . collect-after) (durationMs . 3))
      ((name . policy-after) (durationMs . 0)))
    benchmark-gate-fixture)))

;; : Alist
(def benchmark-gate-missing-observed-peer-fixture
  (benchmark-gate-without 'observedCollectMs benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-observed-over-max-fixture
  (benchmark-gate-with 'observedPhaseMs 7 benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-subsecond-fixture
  (benchmark-gate-with
   'max_total
   '750us
   (benchmark-gate-with
    'observed_total
    '250us
    (benchmark-gate-with
     'target_total
     '500us
     (benchmark-gate-with
      'regression_budget
      '250us
      (benchmark-gate-with
       'expected_over_input_budget
       '125us
       (benchmark-gate-with
        'observedTimings
        '(((name . collect-before) (durationMs . 0.125) (durationNs . 125000))
          ((name . policy-before) (durationMs . 0) (durationNs . 0))
          ((name . collect-after) (durationMs . 0.125) (durationNs . 125000))
          ((name . policy-after) (durationMs . 0) (durationNs . 0)))
        benchmark-gate-fixture)))))))

;; : Alist
(def benchmark-gate-slow-hot-fixture
  (benchmark-gate-with
   'target_total
   '100ms
   benchmark-gate-fixture))

;; : Alist
(def benchmark-gate-integration-fixture
  (benchmark-gate-with
   'tags
   '(gxtest import-closure)
   (benchmark-gate-with
    'max_total
    '200ms
    (benchmark-gate-with
     'target_total
     '100ms
     (benchmark-gate-with
      'observed_total
      '80ms
      benchmark-gate-fixture)))))

;; : Alist
(def benchmark-gate-slow-integration-fixture
  (benchmark-gate-with
   'max_total
   '1s
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

;; String
(def +benchmark-gate-scenario-benchmark-suffix+ "/benchmark.ss")

;; : (-> String String Boolean)
(def (benchmark-gate-string-suffix? text suffix)
  (let ((text-len (string-length text))
        (suffix-len (string-length suffix)))
    (and (>= text-len suffix-len)
         (string=? (substring text (- text-len suffix-len) text-len)
                   suffix))))

;; : (-> Path Path)
(def (benchmark-gate-scenario-root-for-benchmark path)
  (if (benchmark-gate-string-suffix?
       path
       +benchmark-gate-scenario-benchmark-suffix+)
    (substring path
               0
               (- (string-length path)
                  (string-length +benchmark-gate-scenario-benchmark-suffix+)))
    path))

;; : (-> Path Boolean)
(def (benchmark-gate-scenario-input-expected-pass? benchmark-path)
  (let (root (benchmark-gate-scenario-root-for-benchmark benchmark-path))
    (and (benchmark-gate-directory? (path-expand "input" root))
         (benchmark-gate-directory? (path-expand "expected" root)))))

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
    (test-case "duration literals parse to exact nanoseconds"
      (check (duration-literal->nanos '800ns) => 800)
      (check (duration-literal->nanos '75us) => 75000)
      (check (duration-literal->nanos '1.2ms) => 1200000)
      (check (duration-literal->nanos '1s) => 1000000000)
      (check (duration-literal->nanos '0.1ns) => #f))

    (test-case "fixture carries reusable gate metadata"
      (check (benchmark-fixture-ref benchmark-gate-fixture 'max_total)
             => '100ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxRssMb)
             => 512)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryMetric)
             => 'resident-set-size)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryUnit)
             => "MB")
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observed_total)
             => '10ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'target_total)
             => '25ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'regression_budget)
             => '15ms)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxCollectMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedCollectMs)
             => 10)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxParseMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedParseMs)
             => 0)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxFileMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedFileMs)
             => 0)
      (check (number?
              (benchmark-fixture-ref benchmark-gate-fixture 'maxPhaseMs))
             => #t)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedPhaseMs)
             => 6)
      (check (benchmark-fixture-ref benchmark-gate-fixture
                                    'expected_over_input_budget)
             => '15ms)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'observedTimings)
             => '(((name . collect-before) (durationMs . 6))
                  ((name . collect-after) (durationMs . 4))
                  ((name . policy-before) (durationMs . 0))
                  ((name . policy-after) (durationMs . 0))))
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
      (check (benchmark-fixture-input-expected-comparison-pass?
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

    (test-case "max gates require observed peer fields"
      (check (not
              (not
               (member 'observedCollectMs
                       (benchmark-fixture-missing-keys
                        benchmark-gate-missing-observed-peer-fixture))))
             => #t)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-missing-observed-peer-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-observed-over-max-fixture)
             => #f))

    (test-case "input and expected timing comparison is enforced"
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-slow-expected-fixture)
             => #t)
      (check (benchmark-fixture-input-expected-comparison-pass?
              benchmark-gate-slow-expected-fixture)
             => #f)
      (check (benchmark-fixture-contract-pass?
              benchmark-gate-slow-expected-fixture)
             => #f))

    (test-case "subsecond timing baselines satisfy the gate contract"
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'max_total)
             => '750us)
      (check (benchmark-fixture-ref benchmark-gate-subsecond-fixture
                                    'observed_total)
             => '250us)
      (check (benchmark-fixture-observed-timings-contract-pass?
              benchmark-gate-subsecond-fixture)
             => #t)
      (check (benchmark-fixture-input-expected-comparison-pass?
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
             (check (benchmark-gate-scenario-input-expected-pass? path) => #t)
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
        (check (benchmark-fixture-ref receipt 'observed_total)
               => '10ms)
        (check (benchmark-fixture-ref receipt 'target_total)
               => '25ms)
        (check (benchmark-fixture-ref receipt 'regression_budget)
               => '15ms)
        (check (benchmark-fixture-ref receipt 'observedTimings)
               => '(((name . collect-before) (durationMs . 6))
                    ((name . collect-after) (durationMs . 4))
                    ((name . policy-before) (durationMs . 0))
                    ((name . policy-after) (durationMs . 0))))
        (check (benchmark-fixture-ref receipt 'targetRationale)
               => "default generated benchmark fixture target")
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "run returns fail receipt at zero threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fail-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'max_total) => '0ns)
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
