;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :commands/bench
        :std/misc/ports
        (only-in :std/text/json read-json))
(export bench-test)
;; Json <- Table Key
(def (json-get table key)
  (hash-get table key))
;; BenchOutput <- (List XX)
(def (bench-output args)
  (bench-output/status args 0))
;; Status <- (List XX) ExpectedStatus
(def (bench-output/status args expected-status)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (bench-main args)))))))
    (check status => expected-status)
    output))
;; Boolean <- OutputPort Fragment
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
;; BenchTest
(def bench-test
  (test-suite "gerbil scheme harness bench"
    (test-case "bench text output records verification hot paths"
      (let (output (bench-output ["--iterations" "1" "--max-total-ms" "60000" "."]))
        (check (contains? output "[gerbil-bench] status=pass") => #t)
        (check (contains? output "|bench name=collect-project") => #t)
        (check (contains? output "|bench name=type-check") => #t)
        (check (contains? output "|bench name=search-prime-packet") => #t)
        (check (contains? output "|bench name=structural-index-packet") => #t)
        (check (contains? output "|bench name=structural-compact-syntax-render") => #t)))
    (test-case "bench json output is a CI verification receipt"
      (let* ((output (bench-output ["--json" "--iterations" "1" "--max-total-ms" "60000" "."]))
             (packet (call-with-input-string output read-json))
             (benchmarks (json-get packet "benchmarks"))
             (first-benchmark (car benchmarks)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.gerbil-scheme-harness-bench")
        (check (json-get packet "status") => "pass")
        (check (json-get packet "iterations") => 1)
        (check (>= (json-get packet "files") 1) => #t)
        (check (>= (json-get packet "definitions") 1) => #t)
        (check (length benchmarks) => 5)
        (check (json-get first-benchmark "name") => "collect-project")
        (check (>= (json-get first-benchmark "durationMs") 0) => #t)
        (check (>= (json-get first-benchmark "averageMicros") 0) => #t)
        (check (length (json-get packet "performanceFindings")) => 0)))
    (test-case "bench json output reports threshold performance findings"
      (let* ((output (bench-output/status
                      ["--json" "--iterations" "2" "--max-total-ms" "1" "."]
                      1))
             (packet (call-with-input-string output read-json))
             (findings (json-get packet "performanceFindings"))
             (finding (car findings))
             (slowest (json-get packet "slowestBenchmark")))
        (check (json-get packet "status") => "fail")
        (check (length findings) => 1)
        (check (json-get finding "kind") => "total-threshold-exceeded")
        (check (json-get finding "severity") => "warning")
        (check (json-get finding "maxTotalMs") => 1)
        (check (>= (json-get finding "exceededByMs") 0) => #t)
        (check (json-get finding "slowestBenchmarkName")
               => (json-get slowest "name"))))))
