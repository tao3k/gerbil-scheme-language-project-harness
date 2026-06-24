;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :std/test
        :commands/bench-light
        :std/misc/ports
        (rename-in :cli-launcher (main cli-main))
        (only-in :std/text/json read-json))
(export bench-test)
;; : (-> Table Key Json )
(def (json-get table key)
  (hash-get table key))
;; : (-> Table Key Boolean)
(def (json-key? table key)
  (hash-key? table key))
;; : (-> (List Json) String Json )
(def (find-performance-finding findings kind)
  (cond
   ((null? findings) #f)
   ((equal? (json-get (car findings) "kind") kind) (car findings))
   (else (find-performance-finding (cdr findings) kind))))
;; : (-> (List XX) BenchOutput )
(def (bench-output args)
  (bench-output/status args 0))
;; : (-> (List XX) ExpectedStatus Status )
(def (bench-output/status args expected-status)
  (bench-output/status* bench-light-main args expected-status))
;; : (-> (List XX) BenchOutput )
(def (cli-bench-output args)
  (bench-output/status*
   (lambda (runner-args)
     (apply cli-main (cons "bench" runner-args)))
   args
   0))
;; : (-> Procedure (List XX) ExpectedStatus Status )
(def (bench-output/status* runner args expected-status)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (runner args)))))))
    (check status => expected-status)
    output))
;; : (-> OutputPort Fragment Boolean )
(def (contains? output fragment)
  (and (string-contains output fragment) #t))
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
        (check (length (json-get packet "performanceFindings")) => 0)))
    (test-case "bench full mode records cold collect and type-check profile"
      (let* ((output (bench-output ["--json" "--mode" "full" "--iterations" "1"
                                    "--max-total-ms" "3600000"
                                    "--max-interface-ms" "3600000"
                                    "--max-collect-ms" "3600000"
                                    "--max-parse-ms" "3600000"
                                    "--max-file-ms" "3600000"
                                    "--max-phase-ms" "3600000"
                                    "."]))
             (packet (call-with-input-string output read-json))
             (benchmarks (json-get packet "benchmarks"))
             (first-benchmark (car benchmarks))
             (collect-profile (json-get packet "collectProjectProfile"))
             (profile-phases (json-get collect-profile "phases"))
             (slowest-files (json-get collect-profile "slowestFiles")))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.gerbil-scheme-harness-bench")
        (check (json-get packet "mode") => "full")
        (check (json-get packet "status") => "pass")
        (check (json-get packet "iterations") => 1)
        (check (json-get packet "maxInterfaceMs") => 3600000)
        (check (json-get packet "maxCollectMs") => 3600000)
        (check (json-get packet "maxParseMs") => 3600000)
        (check (json-get packet "maxFileMs") => 3600000)
        (check (json-get packet "maxPhaseMs") => 3600000)
        (check (>= (json-get packet "files") 1) => #t)
        (check (>= (json-get packet "definitions") 1) => #t)
        (check (length benchmarks) => 5)
        (check (json-get first-benchmark "name") => "collect-project")
        (check (>= (json-get first-benchmark "durationMs") 0) => #t)
        (check (>= (json-get first-benchmark "averageMicros") 0) => #t)
        (check (json-get collect-profile "fileCount")
               => (json-get packet "files"))
        (check (json-get collect-profile "definitionCount")
               => (json-get packet "definitions"))
        (check (length profile-phases) => 3)
        (check (json-get (car profile-phases) "name")
               => "read-project-package")
        (check (json-get (cadr profile-phases) "name")
               => "collect-source-files")
        (check (json-get (caddr profile-phases) "name")
               => "parse-source-files")
        (check (>= (length slowest-files) 1) => #t)
        (check (length (json-get packet "performanceFindings")) => 0)))
    (test-case "bench json output reports threshold performance findings"
      (let* ((output (bench-output/status
                      ["--json" "--mode" "full" "--iterations" "2"
                       "--max-total-ms" "1"
                       "--max-interface-ms" "1"
                       "--max-collect-ms" "1"
                       "--max-parse-ms" "1"
                       "--max-file-ms" "1"
                       "--max-phase-ms" "1"
                       "."]
                      1))
             (packet (call-with-input-string output read-json))
             (findings (json-get packet "performanceFindings"))
             (finding (find-performance-finding findings "total-threshold-exceeded"))
             (collect-finding (find-performance-finding findings "collect-threshold-exceeded"))
             (interface-finding (find-performance-finding findings "interface-threshold-exceeded"))
             (parse-finding (find-performance-finding findings "parse-threshold-exceeded"))
             (file-finding (find-performance-finding findings "file-threshold-exceeded"))
             (phase-finding (find-performance-finding findings "phase-threshold-exceeded"))
             (slowest (json-get packet "slowestBenchmark")))
        (check (json-get packet "status") => "fail")
        (check (>= (length findings) 1) => #t)
        (check (not (not finding)) => #t)
        (check (not (not collect-finding)) => #t)
        (check (not (not interface-finding)) => #t)
        (check (not (not parse-finding)) => #t)
        (check (not (not file-finding)) => #t)
        (check (not (not phase-finding)) => #t)
        (check (json-get finding "kind") => "total-threshold-exceeded")
        (check (json-get finding "severity") => "warning")
        (check (json-get finding "maxTotalMs") => 1)
        (check (>= (json-get finding "exceededByMs") 0) => #t)
        (check (json-get collect-finding "maxCollectMs") => 1)
        (check (json-get interface-finding "maxInterfaceMs") => 1)
        (check (json-get parse-finding "maxParseMs") => 1)
        (check (json-get file-finding "maxFileMs") => 1)
        (check (json-get phase-finding "maxPhaseMs") => 1)
        (check (>= (json-get collect-finding "durationMs") 1) => #t)
        (check (>= (json-get parse-finding "durationMs") 1) => #t)
        (check (>= (json-get file-finding "durationMs") 1) => #t)
        (check (>= (json-get phase-finding "durationMs") 1) => #t)
        (check (json-get finding "slowestBenchmarkName")
               => (json-get slowest "name"))))))
