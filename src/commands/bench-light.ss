;;; -*- Gerbil -*-
;;; Lightweight benchmark command for native hot-path gates.

(import :gerbil/gambit
        :constants
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/srfi/1 iota last)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar filter-map foldl)
        (only-in :std/text/json write-json)
        :support/time)

(export bench-light-main)

(def +bench-schema-id+
  "agent.semantic-protocols.gerbil-scheme-harness-bench")
(def +bench-mode-hot+ "hot")
(def +bench-mode-full+ "full")
(def +default-max-total-ms+ 100)
(def +default-max-interface-ms+ 50)

(def +value-options+
  '("--workspace" "--mode" "--iterations" "--max-total-ms"
    "--max-interface-ms" "--max-collect-ms" "--max-parse-ms"
    "--max-file-ms" "--max-phase-ms" "--whitelist"))

(def +boolean-flags+
  '("--json" "--full"))

;; : (-> String (List String) Boolean)
(def (flag? flag args)
  (and (member flag args) #t))

;; : (-> String (List String) (U #f String))
(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))

;; positional-args
;;   : (-> (List String) (List String))
;;   | doc m%
;;       Return non-option command arguments while preserving option value
;;       skipping for benchmark-owned flags.
;;
;;       # Examples
;;
;;       ```scheme
;;       (positional-args '("--workspace" "." "src"))
;;       ;; => ("src")
;;       ```
;;     %
(def (positional-args args)
  (let loop ((rest args) (out '()) (skip? #f))
    (match rest
      ([] (reverse out))
      ([arg . more]
       (cond
        (skip? (loop more out #f))
        ((member arg +value-options+) (loop more out #t))
        ((or (member arg +boolean-flags+)
             (string-prefix? "--" arg))
         (loop more out #f))
        (else
         (loop more (cons arg out) #f)))))))

;; : (-> String Boolean)
(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

;; : (-> (List String) String)
(def (project-root args)
  (or (option "--workspace" args)
      (let (pos (positional-args args))
        (if (and (pair? pos) (file-directory? (last pos)))
          (last pos)
          "."))))

;; : (-> (List String) String)
(def (bench-mode args)
  (cond
   ((flag? "--full" args) +bench-mode-full+)
   ((option "--mode" args) => identity)
   (else +bench-mode-hot+)))

;; : (-> String (List String) Integer Integer)
(def (positive-integer-option name args default)
  (let (raw (option name args))
    (if raw
      (let (value (string->number raw))
        (if (and value (integer? value) (> value 0))
          value
          (error "invalid positive integer option" name raw)))
      default)))

;; : (-> String (List String) (U #f Integer))
(def (optional-positive-integer-option name args)
  (let (raw (option name args))
    (and raw
         (let (value (string->number raw))
           (if (and value (integer? value) (> value 0))
             value
             (error "invalid positive integer option" name raw))))))

;; : (-> (-> Value) Value)
(def (bench-silenced thunk)
  (let (value #!void)
    (call-with-output-string
      (lambda (out)
        (parameterize ((current-output-port out)
                       (current-error-port out))
          (set! value (thunk)))))
    value))

;; bench-step
;;   : (-> String Integer (-> Value) Benchmark)
;;   | doc m%
;;       Run one benchmark thunk for `iterations` and return a timing packet.
;;
;;       The local recursion is the measurement driver: each iteration must
;;       run sequentially so elapsed time remains attributable to the thunk.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-step "noop" 1 (lambda () #!void))
;;       ;; => benchmark hash
;;       ```
;;     %
(def (bench-step name iterations thunk)
  (let (elapsed-ms
        (foldl (lambda (_ elapsed-ms)
                 (+ elapsed-ms (bench-iteration-elapsed-ms thunk)))
               0
               (iota iterations)))
    (hash (name name)
          (iterations iterations)
          (durationMs elapsed-ms)
          (averageMicros (average-duration-micros elapsed-ms iterations))
          (averageMs (average-duration-ms elapsed-ms iterations)))))

;; : (-> (-> Value) Integer)
(def (bench-iteration-elapsed-ms thunk)
  (let (start (monotonic-ms))
    (thunk)
    (duration-ms start (monotonic-ms))))

;; : (-> (List String) Void)
(def (run-fast-search args)
  (let (status (bench-silenced (lambda () (try-search-light-main args))))
    (unless (= status 0)
      (error "native fast search benchmark failed" args status))))

;; : (-> String Integer (List Benchmark))
(def (bench-hot-paths root iterations)
  [(bench-step "search-prime-light" iterations
               (lambda ()
                 (run-fast-search
                  ["prime" "--view" "seeds" "--workspace" root])))
   (bench-step "workspace-scope-light" iterations
               (lambda ()
                 (run-fast-search
                  ["workspace-scope" "--workspace" root])))])

;; : (-> Benchmark String)
(def (benchmark-name benchmark)
  (hash-get benchmark 'name))

;; : (-> Benchmark Integer)
(def (benchmark-duration-ms benchmark)
  (hash-get benchmark 'durationMs))

;; sum-duration-ms
;;   : (-> (List Benchmark) Integer)
;;   | doc m%
;;       Sum benchmark durations with a fold so the aggregation shape stays
;;       visible to the parser and future benchmark fields do not affect it.
;;     %
(def (sum-duration-ms benchmarks)
  (foldl (lambda (benchmark total)
           (+ total (benchmark-duration-ms benchmark)))
         0
         benchmarks))

;; slowest-benchmark
;;   : (-> (List Benchmark) Benchmark)
;;   | doc m%
;;       Return the benchmark with the largest duration.
;;
;;       Callers pass a non-empty benchmark list from `bench-hot-paths`.
;;     %
(def (slowest-benchmark benchmarks)
  (foldl slower-benchmark (car benchmarks) (cdr benchmarks)))

;; : (-> Benchmark Benchmark Benchmark)
(def (slower-benchmark benchmark best)
  (if (> (benchmark-duration-ms benchmark)
         (benchmark-duration-ms best))
    benchmark
    best))

;; : (-> Benchmark Boolean)
(def (bench-interface-benchmark? benchmark)
  (member (benchmark-name benchmark)
          ["search-prime-light" "workspace-scope-light"]))

;; bench-interface-findings
;;   : (-> (U #f Integer) (List Benchmark) (List PerformanceFinding))
;;   | doc m%
;;       Return per-interface threshold findings for hot-path benchmarks.
;;
;;       `filter-map` keeps predicate and finding construction in one bounded
;;       traversal without a hand-written output accumulator.
;;     %
(def (bench-interface-findings max-interface-ms benchmarks)
  (if max-interface-ms
    (filter-map (lambda (benchmark)
                  (bench-interface-finding max-interface-ms benchmark))
                benchmarks)
    '()))

;; : (-> Integer Benchmark (U #f PerformanceFinding))
(def (bench-interface-finding max-interface-ms benchmark)
  (and (bench-interface-benchmark? benchmark)
       (> (benchmark-duration-ms benchmark) max-interface-ms)
       (hash
        (kind "interface-threshold-exceeded")
        (severity "warning")
        (summary "native hot-path benchmark exceeded --max-interface-ms")
        (benchmarkName (benchmark-name benchmark))
        (durationMs (benchmark-duration-ms benchmark))
        (maxInterfaceMs max-interface-ms)
        (exceededByMs
         (- (benchmark-duration-ms benchmark)
            max-interface-ms)))))

;; : (-> Integer Integer (U #f Integer) Benchmark (List Benchmark) (List PerformanceFinding))
(def (bench-performance-findings total-ms max-total-ms max-interface-ms
                                 slowest benchmarks)
  (append
   (if (and max-total-ms (> total-ms max-total-ms))
     [(hash (kind "total-threshold-exceeded")
            (severity "warning")
            (summary "native hot-path benchmark total exceeded --max-total-ms")
            (totalMs total-ms)
            (maxTotalMs max-total-ms)
            (exceededByMs (- total-ms max-total-ms))
            (slowestBenchmarkName (benchmark-name slowest))
            (slowestBenchmarkDurationMs (benchmark-duration-ms slowest)))]
     '())
   (bench-interface-findings max-interface-ms benchmarks)))

;; : (-> String Integer Integer Integer (List Benchmark) BenchPacket)
(def (bench-packet root iterations max-total-ms max-interface-ms benchmarks)
  (let* ((total-ms (sum-duration-ms benchmarks))
         (slowest (slowest-benchmark benchmarks))
         (performance-findings
          (bench-performance-findings
           total-ms max-total-ms max-interface-ms slowest benchmarks))
         (status (if (null? performance-findings) "pass" "fail")))
    (hash (schemaId +bench-schema-id+)
          (schemaVersion "1")
          (languageId +language-id+)
          (providerId +provider-id+)
          (projectRoot root)
          (mode +bench-mode-hot+)
          (status status)
          (iterations iterations)
          (totalMs total-ms)
          (files 0)
          (definitions 0)
          (findings 0)
          (maxTotalMs max-total-ms)
          (maxInterfaceMs max-interface-ms)
          (performanceFindings performance-findings)
          (slowestBenchmark slowest)
          (benchmarks benchmarks))))

;; : (-> HashTable Symbol Value Value)
(def (hash-get/default table key default)
  (if (hash-key? table key)
    (hash-get table key)
    default))

;; : (-> PerformanceFinding Void)
(def (display-performance-finding finding)
  (displayln "|performanceFinding kind=" (hash-get/default finding 'kind "")
             " severity=" (hash-get/default finding 'severity "")
             " summary=" (hash-get/default finding 'summary "")
             " benchmark=" (hash-get/default finding 'benchmarkName "")
             " totalMs=" (hash-get/default finding 'totalMs "")
             " durationMs=" (hash-get/default finding 'durationMs "")
             " maxTotalMs=" (hash-get/default finding 'maxTotalMs "")
             " maxInterfaceMs=" (hash-get/default finding 'maxInterfaceMs "")
             " exceededByMs=" (hash-get/default finding 'exceededByMs "")
             " slowest=" (hash-get/default finding 'slowestBenchmarkName "")
             " slowestDurationMs="
             (hash-get/default finding 'slowestBenchmarkDurationMs "")))

;; : (-> Benchmark Void)
(def (display-benchmark benchmark)
  (displayln "|bench name=" (benchmark-name benchmark)
             " iterations=" (hash-get benchmark 'iterations)
             " durationMs=" (benchmark-duration-ms benchmark)
             " averageMicros=" (hash-get benchmark 'averageMicros)
             " averageMs=" (hash-get benchmark 'averageMs)))

;; : (-> BenchPacket Void)
(def (display-bench-packet packet)
  (display-bench-summary packet)
  (display-bench-slowest packet)
  (for-each display-performance-finding
            (hash-get packet 'performanceFindings))
  (for-each display-benchmark
            (hash-get packet 'benchmarks)))

;; : (-> BenchPacket Void)
(def (display-bench-summary packet)
  (displayln "[gerbil-bench] status=" (hash-get packet 'status)
             " mode=" (hash-get packet 'mode)
             " totalMs=" (hash-get packet 'totalMs)
             " iterations=" (hash-get packet 'iterations)
             " files=" (hash-get packet 'files)
             " definitions=" (hash-get packet 'definitions)
             " findings=" (hash-get packet 'findings)))

;; : (-> BenchPacket Void)
(def (display-bench-slowest packet)
  (let (slowest (hash-get packet 'slowestBenchmark))
    (displayln "|slowest name=" (hash-get slowest 'name)
               " durationMs=" (hash-get slowest 'durationMs))))

;; : (-> Value Void)
(def (write-json-line value)
  (write-json value)
  (newline))

;; : (-> Void)
(def (ensure-runtime-loader!)
  (##global-var-set! (##make-global-var 'load-module) load-module))

;; : (-> (List String) Integer)
(def (bench-full-main args)
  (ensure-runtime-loader!)
  (load-module "gslph/src/commands/bench")
  ((eval 'gslph/src/commands/bench#bench-main) args))

;; : (-> (List String) Integer)
(def (bench-hot-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (iterations (positive-integer-option "--iterations" args 1))
         (max-total-ms (or (optional-positive-integer-option "--max-total-ms" args)
                           +default-max-total-ms+))
         (max-interface-ms (or (optional-positive-integer-option "--max-interface-ms" args)
                               +default-max-interface-ms+))
         (benchmarks (bench-hot-paths root iterations))
         (packet (bench-packet root iterations max-total-ms
                               max-interface-ms benchmarks)))
    (if json?
      (write-json-line packet)
      (display-bench-packet packet))
    (if (equal? (hash-get packet 'status) "pass") 0 1)))

;; : (-> (List String) Integer)
(def (bench-light-main args)
  (if (equal? (bench-mode args) +bench-mode-full+)
    (bench-full-main args)
    (bench-hot-main args)))
