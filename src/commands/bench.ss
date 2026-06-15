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
        :support/time
        :types/facade)

(export bench-main)
;; String
(def +bench-schema-id+ "agent.semantic-protocols.gerbil-scheme-harness-bench")
;; Integer
(def +default-max-interface-ms+ 50)
;; PositiveIntegerOption <- String (List String) Default
(def (positive-integer-option name args default)
  (let (raw (option name args))
    (if raw
      (let (value (string->number raw))
        (if (and value (integer? value) (> value 0))
          value
          (error "invalid positive integer option" name raw)))
      default)))
;; OptionalPositiveIntegerOption <- String (List String)
(def (optional-positive-integer-option name args)
  (let (raw (option name args))
    (and raw
         (let (value (string->number raw))
           (if (and value (integer? value) (> value 0))
             value
             (error "invalid positive integer option" name raw))))))
;;; Invariant:
;;; - bench-step owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; BenchStep <- String Iterations Thunk
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
;;; Boundary:
;;; - sum-duration-ms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- Benchmarks
(def (sum-duration-ms benchmarks)
  (foldl (lambda (benchmark total)
           (+ total (hash-get benchmark 'durationMs)))
         0
         benchmarks))
;;; Boundary:
;;; - slowest-benchmark composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; SlowestBenchmark <- Benchmarks
(def (slowest-benchmark benchmarks)
  (foldl (lambda (benchmark best)
           (if (> (hash-get benchmark 'durationMs)
                  (hash-get best 'durationMs))
             benchmark
             best))
         (car benchmarks)
         (cdr benchmarks)))
;; (List TypeFinding) <- TotalMs MaxTotalMs MaxInterfaceMs Slowest Benchmarks
(def (bench-performance-findings total-ms max-total-ms max-interface-ms slowest benchmarks)
  (append
   (if (and max-total-ms (> total-ms max-total-ms))
     [(hash (kind "total-threshold-exceeded")
            (severity "warning")
            (summary "benchmark total exceeded --max-total-ms")
            (totalMs total-ms)
            (maxTotalMs max-total-ms)
            (exceededByMs (- total-ms max-total-ms))
            (slowestBenchmarkName (hash-get slowest 'name))
            (slowestBenchmarkDurationMs (hash-get slowest 'durationMs)))]
     '())
   (bench-interface-findings max-interface-ms benchmarks)))

;;; Boundary:
;;; - bench-interface-findings keeps ASP handoff performance separate from parser collection.
;;; - Only lightweight structural interface paths are judged here.
;; (List TypeFinding) <- MaxInterfaceMs Benchmarks
(def (bench-interface-findings max-interface-ms benchmarks)
  (if max-interface-ms
    (filter-map
     (lambda (benchmark)
       (and (bench-interface-benchmark? benchmark)
            (> (hash-get benchmark 'durationMs) max-interface-ms)
            (hash
             (kind "interface-threshold-exceeded")
             (severity "warning")
             (summary "structural interface benchmark exceeded --max-interface-ms")
             (benchmarkName (hash-get benchmark 'name))
             (durationMs (hash-get benchmark 'durationMs))
             (maxInterfaceMs max-interface-ms)
             (exceededByMs
              (- (hash-get benchmark 'durationMs) max-interface-ms)))))
     benchmarks)
    '()))
;; Boolean <- Benchmark
(def (bench-interface-benchmark? benchmark)
  (member (hash-get benchmark 'name)
          ["structural-interface-packet" "structural-owner-facts-packet"]))
;;; Boundary:
;;; - bench-packet coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; JsonPacket <- String Iterations MaxTotalMs MaxInterfaceMs ProjectIndex (List XX) Benchmarks
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
;;; Boundary:
;;; - display-bench-packet composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; JsonPacket <- Packet
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
     (if (equal? (hash-get finding 'kind) "total-threshold-exceeded")
       (displayln "|performanceFinding kind=" (hash-get finding 'kind)
                  " severity=" (hash-get finding 'severity)
                  " maxTotalMs=" (hash-get finding 'maxTotalMs)
                  " exceededByMs=" (hash-get finding 'exceededByMs)
                  " slowest=" (hash-get finding 'slowestBenchmarkName))
       (displayln "|performanceFinding kind=" (hash-get finding 'kind)
                  " severity=" (hash-get finding 'severity)
                  " maxInterfaceMs=" (hash-get finding 'maxInterfaceMs)
                  " exceededByMs=" (hash-get finding 'exceededByMs)
                  " benchmark=" (hash-get finding 'benchmarkName))))
   (hash-get packet 'performanceFindings))
  (for-each
   (lambda (benchmark)
     (displayln "|bench name=" (hash-get benchmark 'name)
                " iterations=" (hash-get benchmark 'iterations)
                " durationMs=" (hash-get benchmark 'durationMs)
                " averageMicros=" (hash-get benchmark 'averageMicros)
                " averageMs=" (hash-get benchmark 'averageMs)))
   (hash-get packet 'benchmarks)))
;;; Boundary:
;;; Boundary:
;;; - Bench runs inside tests and CLI processes that may have done heavy parsing.
;;; - Force one GC before timing so interface gates measure provider work.
;; Unit
(def (stabilize-bench-runtime!)
  (##gc))

;;; Boundary:
;;; - bench-main coordinates collection, policy, and packet projection timings.
;;; - Keep thresholds strict while isolating them from previous in-process tests.
;; BenchMain <- (List XX)
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
