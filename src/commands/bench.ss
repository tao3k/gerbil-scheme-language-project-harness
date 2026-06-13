;;; -*- Gerbil -*-
;;; Verification benchmark command for harness hot paths.

(import :checker/facade
        :constants
        :parser/facade
        :protocol/json
        :std/sugar
        :support/args
        :support/time
        :types/facade)

(export bench-main)

(def +bench-schema-id+ "agent.semantic-protocols.gerbil-scheme-harness-bench")

(def (positive-integer-option name args default)
  (let (raw (option name args))
    (if raw
      (let (value (string->number raw))
        (if (and value (integer? value) (> value 0))
          value
          (error "invalid positive integer option" name raw)))
      default)))

(def (optional-positive-integer-option name args)
  (let (raw (option name args))
    (and raw
         (let (value (string->number raw))
           (if (and value (integer? value) (> value 0))
             value
             (error "invalid positive integer option" name raw))))))

(def (bench-step name iterations thunk)
  (let (start (monotonic-ms))
    (let lp ((remaining iterations))
      (when (> remaining 0)
        (thunk)
        (lp (- remaining 1))))
    (let (elapsed-ms (duration-ms start (monotonic-ms)))
      (hash (name name)
            (iterations iterations)
            (durationMs elapsed-ms)
            (averageMicros (average-duration-micros elapsed-ms iterations))
            (averageMs (average-duration-ms elapsed-ms iterations))))))

(def (sum-duration-ms benchmarks)
  (foldl (lambda (benchmark total)
           (+ total (hash-get benchmark 'durationMs)))
         0
         benchmarks))

(def (slowest-benchmark benchmarks)
  (foldl (lambda (benchmark best)
           (if (> (hash-get benchmark 'durationMs)
                  (hash-get best 'durationMs))
             benchmark
             best))
         (car benchmarks)
         (cdr benchmarks)))

(def (bench-performance-findings total-ms max-total-ms slowest)
  (if (and max-total-ms (> total-ms max-total-ms))
    [(hash (kind "total-threshold-exceeded")
           (severity "warning")
           (summary "benchmark total exceeded --max-total-ms")
           (totalMs total-ms)
           (maxTotalMs max-total-ms)
           (exceededByMs (- total-ms max-total-ms))
           (slowestBenchmarkName (hash-get slowest 'name))
           (slowestBenchmarkDurationMs (hash-get slowest 'durationMs)))]
    '()))

(def (bench-packet root iterations max-total-ms index findings benchmarks)
  (let* ((total-ms (sum-duration-ms benchmarks))
         (slowest (slowest-benchmark benchmarks))
         (performance-findings
          (bench-performance-findings total-ms max-total-ms slowest))
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
    packet))

(def (display-bench-packet packet)
  (displayln "[gerbil-bench] status=" (hash-get packet 'status)
             " totalMs=" (hash-get packet 'totalMs)
             " iterations=" (hash-get packet 'iterations)
             " files=" (hash-get packet 'files)
             " definitions=" (hash-get packet 'definitions)
             " findings=" (hash-get packet 'findings))
  (displayln "|slowest name=" (hash-get (hash-get packet 'slowestBenchmark) 'name)
             " durationMs=" (hash-get (hash-get packet 'slowestBenchmark) 'durationMs))
  (for-each
   (lambda (finding)
     (displayln "|performanceFinding kind=" (hash-get finding 'kind)
                " severity=" (hash-get finding 'severity)
                " maxTotalMs=" (hash-get finding 'maxTotalMs)
                " exceededByMs=" (hash-get finding 'exceededByMs)
                " slowest=" (hash-get finding 'slowestBenchmarkName)))
   (hash-get packet 'performanceFindings))
  (for-each
   (lambda (benchmark)
     (displayln "|bench name=" (hash-get benchmark 'name)
                " iterations=" (hash-get benchmark 'iterations)
                " durationMs=" (hash-get benchmark 'durationMs)
                " averageMicros=" (hash-get benchmark 'averageMicros)
                " averageMs=" (hash-get benchmark 'averageMs)))
   (hash-get packet 'benchmarks)))

(def (bench-main args)
  (let* ((root (project-root args))
         (json? (flag? "--json" args))
         (iterations (positive-integer-option "--iterations" args 1))
         (max-total-ms (optional-positive-integer-option "--max-total-ms" args))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '()))
         (index #f)
         (findings '())
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
           (bench-step "structural-index-packet" iterations
                       (lambda ()
                         (structural-index-packet-json index)))])
         (packet (bench-packet root iterations max-total-ms index findings benchmarks)))
    (if json?
      (write-json-line packet)
      (display-bench-packet packet))
    (if (equal? (hash-get packet 'status) "pass") 0 1)))
