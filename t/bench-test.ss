;;; -*- Gerbil -*-
;;; Hot bench command tests.

(import :std/test
        :bench-support
        (only-in :std/text/json read-json))
(export bench-test)

;; BenchTest
(def bench-test
  (test-suite "gerbil scheme harness bench"
    (test-case "bench text output records verification hot paths"
      (let (output (bench-output ["--iterations" "1"
                                  "--max-total-ms" "3600000"
                                  "--max-interface-ms" "3600000"
                                  "--max-collect-ms" "3600000"
                                  "--max-parse-ms" "3600000"
                                  "--max-file-ms" "3600000"
                                  "--max-phase-ms" "3600000"
                                  "."]))
        (check (contains? output "[gerbil-bench] status=pass") => #t)
        (check (contains? output "mode=hot") => #t)
        (check (contains? output "|bench name=search-prime-light") => #t)
        (check (contains? output "|bench name=workspace-scope-light") => #t)
        (check (contains? output "|bench name=collect-project") => #f)
        (check (contains? output "|bench name=type-check") => #f)))
    (test-case "cli bench entry uses native hot path"
      (let (output (cli-bench-output ["--iterations" "1"
                                      "--max-total-ms" "3600000"
                                      "--max-interface-ms" "3600000"
                                      "."]))
        (check (contains? output "[gerbil-bench] status=pass") => #t)
        (check (contains? output "mode=hot") => #t)
        (check (contains? output "|bench name=search-prime-light") => #t)
        (check (contains? output "|bench name=workspace-scope-light") => #t)
        (check (contains? output "|bench name=collect-project") => #f)
        (check (contains? output "|bench name=type-check") => #f)))
    (test-case "bench json output is a CI verification receipt"
      (let* ((output (bench-output ["--json" "--iterations" "1"
                                    "--max-total-ms" "3600000"
                                    "--max-interface-ms" "3600000"
                                    "--max-collect-ms" "3600000"
                                    "--max-parse-ms" "3600000"
                                    "--max-file-ms" "3600000"
                                    "--max-phase-ms" "3600000"
                                    "."]))
             (packet (call-with-input-string output read-json))
             (benchmarks (json-get packet "benchmarks"))
             (first-benchmark (car benchmarks)))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.gerbil-scheme-harness-bench")
        (check (json-get packet "mode") => "hot")
        (check (json-get packet "status") => "pass")
        (check (json-get packet "iterations") => 1)
        (check (json-get packet "maxInterfaceMs") => 3600000)
        (check (json-get packet "files") => 0)
        (check (json-get packet "definitions") => 0)
        (check (length benchmarks) => 2)
        (check (json-get first-benchmark "name") => "search-prime-light")
        (check (>= (json-get first-benchmark "durationMs") 0) => #t)
        (check (>= (json-get first-benchmark "averageMicros") 0) => #t)
        (check (json-key? packet "collectProjectProfile") => #f)
        (check (length (json-get packet "performanceFindings")) => 0)))))
