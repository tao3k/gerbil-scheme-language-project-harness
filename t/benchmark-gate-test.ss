;;; -*- Gerbil -*-
;;; Boundary: upstream benchmark gate helpers stay reusable by downstream tests.

(import :gerbil/gambit
        :std/sort
        :std/test
        (only-in :gslph/src/commands/check check-main)
        (rename-in :gslph/src/cli-launcher (main launcher-main))
        (only-in :gslph/src/support/time monotonic-ms duration-ms)
        :gslph/src/benchmark/gate)

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

;; Integer
(def +check-cache-gate-max-warm-ms+ 100)

;; Integer
(def +check-cache-gate-max-launcher-warm-ms+ 100)

;; : (-> Path Boolean)
(def (benchmark-gate-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> String Boolean)
(def (benchmark-gate-scenario-entry? entry)
  (not (member entry '("." ".."))))

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
  (call-with-input-file path read))

;; : (-> String String)
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
   "(package: check-cache-gate)\n")
  (write-text-file
   (path-expand "src/core.ss" +check-cache-gate-root+)
   ";;; -*- Gerbil -*-\n(import :gerbil/gambit)\n(export add1*)\n;; : (-> Integer Integer)\n(def (add1* n) (+ n 1))\n"))

;; : (-> Path Alist)
(def (run-check-full/silent root)
  (let* ((start-ms (monotonic-ms))
         (status
          (parameterize ((current-output-port (open-output-string)))
            (check-main ["--workspace" root "--full"])))
         (elapsed-ms (duration-ms start-ms (monotonic-ms))))
    (list (cons 'status status)
          (cons 'elapsedMs elapsed-ms))))

;; : (-> Path Alist)
(def (run-launcher-check-full/silent root)
  (let* ((start-ms (monotonic-ms))
         (status
          (parameterize ((current-output-port (open-output-string)))
            (apply launcher-main ["check" "--workspace" root "--full"])))
         (elapsed-ms (duration-ms start-ms (monotonic-ms))))
    (list (cons 'status status)
          (cons 'elapsedMs elapsed-ms))))

;; : TestSuite
(def benchmark-gate-test
  (test-suite "gerbil scheme benchmark gate"
    (test-case "fixture carries reusable gate metadata"
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxTotalMs)
             => 1000)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'maxRssMb)
             => 512)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryMetric)
             => 'resident-set-size)
      (check (benchmark-fixture-ref benchmark-gate-fixture 'memoryUnit)
             => "MB")
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
      (check (benchmark-fixture-contract-pass? benchmark-gate-fixture) => #t))

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
        (check (benchmark-receipt-pass? receipt) => #t)))

    (test-case "run returns fail receipt at zero threshold"
      (let (receipt
            (benchmark-run benchmark-gate-fail-fixture
                           (lambda () 'ok)))
        (check (benchmark-fixture-ref receipt 'maxTotalMs) => 0)
        (check (benchmark-receipt-pass? receipt) => #f)))

    (test-case "check full warm cache stays in millisecond budget"
      (prepare-check-cache-gate-project!)
      (let* ((cold (run-check-full/silent +check-cache-gate-root+))
             (warm (run-check-full/silent +check-cache-gate-root+)))
        (check (integer? (benchmark-fixture-ref cold 'status)) => #t)
        (check (integer? (benchmark-fixture-ref warm 'status)) => #t)
        (check (< (benchmark-fixture-ref warm 'elapsedMs)
                  +check-cache-gate-max-warm-ms+)
               => #t)))

    (test-case "launcher check full warm cache stays in millisecond budget"
      (prepare-check-cache-gate-project!)
      (let* ((cold (run-check-full/silent +check-cache-gate-root+))
             (prime (run-launcher-check-full/silent +check-cache-gate-root+))
             (warm (run-launcher-check-full/silent +check-cache-gate-root+)))
        (check (integer? (benchmark-fixture-ref cold 'status)) => #t)
        (check (integer? (benchmark-fixture-ref prime 'status)) => #t)
        (check (integer? (benchmark-fixture-ref warm 'status)) => #t)
        (check (< (benchmark-fixture-ref warm 'elapsedMs)
                  +check-cache-gate-max-launcher-warm-ms+)
               => #t)))))
