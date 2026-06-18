;;; -*- Gerbil -*-
;;; Verification benchmark command for harness hot paths.

(import :gerbil/gambit
        :checker/facade
        :constants
        :parser/facade
        :protocol/json
        (only-in :std/iter for in-range)
        (only-in :std/sugar filter-map foldl)
        :support/args
        :support/io
        :support/time
        :types/facade)

(export bench-main)
;; String
(def +bench-schema-id+ "agent.semantic-protocols.gerbil-scheme-harness-bench")
;; Integer
(def +default-max-interface-ms+ 50)
;; : (-> String (List String) Default PositiveIntegerOption )
(def (positive-integer-option name args default)
  (let (raw (option name args))
    (if raw
      (let (value (string->number raw))
        (if (and value (integer? value) (> value 0))
          value
          (error "invalid positive integer option" name raw)))
      default)))
;; : (-> String (List String) OptionalPositiveIntegerOption )
(def (optional-positive-integer-option name args)
  (let (raw (option name args))
    (and raw
         (let (value (string->number raw))
           (if (and value (integer? value) (> value 0))
             value
             (error "invalid positive integer option" name raw))))))
;; bench-step
;;   : (-> String Integer Thunk Benchmark)
;;   | doc m%
;;       `bench-step name iterations thunk` runs a benchmark thunk repeatedly
;;       and returns timing metadata for the named benchmark.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-step "noop" 1 (lambda () #!void))
;;       ;; => benchmark packet
;;       ```
;;     %
(def (bench-step name iterations thunk)
  (let (start (monotonic-ms))
    (for (_ (in-range iterations))
      (thunk))
    (let (elapsed-ms (duration-ms start (monotonic-ms)))
      (hash (name name)
            (iterations iterations)
            (durationMs elapsed-ms)
            (averageMicros (average-duration-micros elapsed-ms iterations))
            (averageMs (average-duration-ms elapsed-ms iterations))))))
;; : (-> Benchmark String )
(def (benchmark-name benchmark)
  (hash-get benchmark 'name))
;; : (-> Benchmark Milliseconds )
(def (benchmark-duration-ms benchmark)
  (hash-get benchmark 'durationMs))
;; sum-duration-ms
;;   : (-> (List Benchmark) Integer)
;;   | doc m%
;;       `sum-duration-ms benchmarks` returns the total duration for all
;;       benchmark packets.
;;
;;       # Examples
;;
;;       ```scheme
;;       (sum-duration-ms benchmarks)
;;       ;; => 42
;;       ```
;;     %
(def (sum-duration-ms benchmarks)
  (foldl (lambda (benchmark total)
           (+ total (benchmark-duration-ms benchmark)))
         0
         benchmarks))
;; slowest-benchmark
;;   : (-> (List Benchmark) Benchmark)
;;   | doc m%
;;       `slowest-benchmark benchmarks` returns the benchmark packet with the
;;       largest recorded duration.
;;
;;       # Examples
;;
;;       ```scheme
;;       (benchmark-name (slowest-benchmark benchmarks))
;;       ;; => "collect-project"
;;       ```
;;     %
(def (slowest-benchmark benchmarks)
  (foldl (lambda (benchmark best)
           (if (> (benchmark-duration-ms benchmark)
                  (benchmark-duration-ms best))
             benchmark
             best))
         (car benchmarks)
         (cdr benchmarks)))
;; : (-> TotalMs MaxTotalMs MaxInterfaceMs Slowest Benchmarks (List TypeFinding) )
(def (bench-performance-findings total-ms max-total-ms max-interface-ms slowest benchmarks)
  (append
   (if (and max-total-ms (> total-ms max-total-ms))
     [(hash (kind "total-threshold-exceeded")
            (severity "warning")
            (summary "benchmark total exceeded --max-total-ms")
            (totalMs total-ms)
            (maxTotalMs max-total-ms)
            (exceededByMs (- total-ms max-total-ms))
            (slowestBenchmarkName (benchmark-name slowest))
            (slowestBenchmarkDurationMs (benchmark-duration-ms slowest)))]
     '())
   (bench-interface-findings max-interface-ms benchmarks)))

;;; Boundary:
;;; - bench-interface-findings keeps ASP handoff performance separate from parser collection.
;;; - Only lightweight structural interface paths are judged here.
;; : (-> MaxInterfaceMs Benchmarks (List TypeFinding) )
(def (bench-interface-findings max-interface-ms benchmarks)
  (if max-interface-ms
    (filter-map
     (lambda (benchmark)
       (and (bench-interface-benchmark? benchmark)
            (> (benchmark-duration-ms benchmark) max-interface-ms)
            (hash
             (kind "interface-threshold-exceeded")
             (severity "warning")
             (summary "structural interface benchmark exceeded --max-interface-ms")
             (benchmarkName (benchmark-name benchmark))
             (durationMs (benchmark-duration-ms benchmark))
             (maxInterfaceMs max-interface-ms)
             (exceededByMs
              (- (benchmark-duration-ms benchmark) max-interface-ms)))))
     benchmarks)
    '()))
;; : (-> Benchmark Boolean )
(def (bench-interface-benchmark? benchmark)
  (member (benchmark-name benchmark)
          ["structural-interface-packet" "structural-owner-facts-packet"]))
;; bench-packet
;;   : (-> String Integer (U #f Integer) (U #f Integer) ProjectIndex
;;         (List TypeFinding) (List Benchmark)
;;         JsonPacket)
;;   | doc m%
;;       `bench-packet root iterations max-total-ms max-interface-ms index
;;       findings benchmarks` builds the benchmark result packet and threshold
;;       findings.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-packet "." 1 #f #f index findings benchmarks)
;;       ;; => benchmark JSON packet
;;       ```
;;     %
(def (bench-packet root iterations max-total-ms max-interface-ms index findings benchmarks)
  (let* ((total-ms (sum-duration-ms benchmarks))
         (slowest (slowest-benchmark benchmarks))
         (performance-findings
          (bench-performance-findings
           total-ms max-total-ms max-interface-ms slowest benchmarks))
         (status (if (null? performance-findings) "pass" "fail"))
         (packet
          (hash (schemaId +bench-schema-id+)
                (schemaVersion "1")
                (languageId +language-id+)
                (providerId +provider-id+)
                (projectRoot root)
                (status status)
                (iterations iterations)
                (totalMs total-ms)
                (files (length (project-index-files index)))
                (definitions (length (project-definitions index)))
                (findings (length findings))
                (performanceFindings performance-findings)
                (slowestBenchmark slowest)
                (benchmarks benchmarks))))
    (when max-total-ms
      (hash-put! packet 'maxTotalMs max-total-ms))
    (when max-interface-ms
      (hash-put! packet 'maxInterfaceMs max-interface-ms))
    packet))
;; display-bench-packet
;;   : (-> JsonPacket Unit)
;;   | doc m%
;;       `display-bench-packet packet` prints the human-readable benchmark
;;       summary, threshold findings, and per-benchmark rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (display-bench-packet packet)
;;       ;; => (void)
;;       ```
;;     %
(def (display-bench-packet packet)
  (emit-field-line
   "[gerbil-bench]"
   [(line-field "status" (hash-get packet 'status))
    (line-field "totalMs" (hash-get packet 'totalMs))
    (line-field "iterations" (hash-get packet 'iterations))
    (line-field "files" (hash-get packet 'files))
    (line-field "definitions" (hash-get packet 'definitions))
    (line-field "findings" (hash-get packet 'findings))])
  (let (slowest (hash-get packet 'slowestBenchmark))
    (emit-field-line
     "|slowest"
     [(line-field "name" (hash-get slowest 'name))
      (line-field "durationMs" (hash-get slowest 'durationMs))]))
  (for-each
   (lambda (finding)
     (if (equal? (hash-get finding 'kind) "total-threshold-exceeded")
       (emit-field-line
        "|performanceFinding"
        [(line-field "kind" (hash-get finding 'kind))
         (line-field "severity" (hash-get finding 'severity))
         (line-field "maxTotalMs" (hash-get finding 'maxTotalMs))
         (line-field "exceededByMs" (hash-get finding 'exceededByMs))
         (line-field "slowest" (hash-get finding 'slowestBenchmarkName))])
       (emit-field-line
        "|performanceFinding"
        [(line-field "kind" (hash-get finding 'kind))
         (line-field "severity" (hash-get finding 'severity))
         (line-field "maxInterfaceMs" (hash-get finding 'maxInterfaceMs))
         (line-field "exceededByMs" (hash-get finding 'exceededByMs))
         (line-field "benchmark" (hash-get finding 'benchmarkName))])))
   (hash-get packet 'performanceFindings))
  (for-each
   (lambda (benchmark)
     (emit-field-line
      "|bench"
      [(line-field "name" (benchmark-name benchmark))
       (line-field "iterations" (hash-get benchmark 'iterations))
       (line-field "durationMs" (benchmark-duration-ms benchmark))
       (line-field "averageMicros" (hash-get benchmark 'averageMicros))
       (line-field "averageMs" (hash-get benchmark 'averageMs))]))
   (hash-get packet 'benchmarks)))
;; stabilize-bench-runtime!
;;   : (-> Unit)
;;   | doc m%
;;       `stabilize-bench-runtime!` forces one GC before timing so benchmark
;;       gates measure provider work instead of earlier in-process parsing.
;;
;;       # Examples
;;
;;       ```scheme
;;       (stabilize-bench-runtime!)
;;       ;; => (void)
;;       ```
;;     %
(def (stabilize-bench-runtime!)
  (##gc))

;; bench-main
;;   : (-> (List String) Integer)
;;   | doc m%
;;       `bench-main args` coordinates collection, policy, and packet projection
;;       timings, then returns a process-style status code.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-main '("--workspace" "." "--iterations" "1"))
;;       ;; => 0
;;       ```
;;     %
(def (bench-main args)
  (stabilize-bench-runtime!)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (iterations (positive-integer-option "--iterations" args 1))
         (max-total-ms (optional-positive-integer-option "--max-total-ms" args))
         (max-interface-ms (or (optional-positive-integer-option "--max-interface-ms" args)
                               +default-max-interface-ms+))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (index #f)
         (findings '())
         (structural-packet #f)
         (owner-file #f)
         (benchmarks
          [(bench-step "collect-project" iterations
                       (lambda ()
                         (set! index (collect-project root))))
           (bench-step "type-check" iterations
                       (lambda ()
                         (set! findings
                           (run-type-checks/whitelist index '() whitelist))))
           (bench-step "search-prime-packet" iterations
                       (lambda ()
                         (search-prime-packet-json index)))
           (bench-step "structural-interface-packet" iterations
                       (lambda ()
                         (set! structural-packet
                           (structural-index-packet-json index))))
           (bench-step "structural-owner-facts-packet" iterations
                       (lambda ()
                         (unless owner-file
                           (set! owner-file
                             (car (project-index-files index))))
                         (native-syntax-owner-facts-packet-json
                          index owner-file)))])
         (packet (bench-packet root iterations max-total-ms max-interface-ms
                               index findings benchmarks)))
    (if json?
      (write-json-line packet)
      (display-bench-packet packet))
    (if (equal? (hash-get packet 'status) "pass") 0 1)))
