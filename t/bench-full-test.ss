;;; -*- Gerbil -*-
;;; Full bench receipt tests.

(import :std/test
        :bench-support
        (only-in :std/text/json read-json)
        (only-in :std/sugar foldl))
(export bench-full-test)

;; Integer
(def +bench-function-quality-phase-max-ms+ 500)
;; Integer
(def +bench-typed-contract-phase-max-ms+ 350)
;; Integer
(def +bench-comment-quality-phase-max-ms+ 300)
;; Integer
(def +bench-top-form-scan-phase-max-ms+ 500)

;; : (-> JsonObject String Boolean)
(def (bench-phase-finding-for? finding phase-name)
  (and (equal? (json-get finding "kind") "phase-threshold-exceeded")
       (equal? (json-get finding "phaseName") phase-name)))

;; bench-max-phase-duration
;;   : (-> (List JsonObject) String Integer)
;;   | doc m%
;;       `bench-max-phase-duration findings phase-name` returns the largest
;;       duration for phase-threshold findings that match `phase-name`.
;;
;;       # Examples
;;       ```scheme
;;       (bench-max-phase-duration findings "function-quality-profiles")
;;       ;; => 155
;;       ```
;;     %
(def (bench-max-phase-duration findings phase-name)
  (foldl (lambda (finding best)
           (if (bench-phase-finding-for? finding phase-name)
             (max best (json-get finding "durationMs"))
             best))
         0
         findings))

;; BenchFullTest
(def bench-full-test
  (test-suite "gerbil scheme harness full bench"
    (test-case "bench full mode records cold profile and threshold findings"
      (let* ((output (bench-output/status
                      ["--json" "--mode" "full" "--iterations" "1"
                       "--max-total-ms" "1"
                       "--max-interface-ms" "1"
                       "--max-collect-ms" "1"
                       "--max-parse-ms" "1"
                       "--max-file-ms" "1"
                       "--max-phase-ms" "1"
                       "."]
                      1))
             (packet (call-with-input-string output read-json))
             (benchmarks (json-get packet "benchmarks"))
             (first-benchmark (car benchmarks))
             (collect-profile (json-get packet "collectProjectProfile"))
             (profile-phases (json-get collect-profile "phases"))
             (slowest-files (json-get collect-profile "slowestFiles"))
             (findings (json-get packet "performanceFindings"))
             (finding (find-performance-finding findings "total-threshold-exceeded"))
             (collect-finding (find-performance-finding findings "collect-threshold-exceeded"))
             (interface-finding (find-performance-finding findings "interface-threshold-exceeded"))
             (parse-finding (find-performance-finding findings "parse-threshold-exceeded"))
             (file-finding (find-performance-finding findings "file-threshold-exceeded"))
             (phase-finding (find-performance-finding findings "phase-threshold-exceeded"))
             (slowest (json-get packet "slowestBenchmark")))
        (check (json-get packet "schemaId")
               => "agent.semantic-protocols.gerbil-scheme-harness-bench")
        (check (json-get packet "mode") => "full")
        (check (json-get packet "status") => "fail")
        (check (json-get packet "iterations") => 1)
        (check (json-get packet "maxInterfaceMs") => 1)
        (check (json-get packet "maxCollectMs") => 1)
        (check (json-get packet "maxParseMs") => 1)
        (check (json-get packet "maxFileMs") => 1)
        (check (json-get packet "maxPhaseMs") => 1)
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
        (check (<= (bench-max-phase-duration
                    findings "function-quality-profiles")
                   +bench-function-quality-phase-max-ms+)
               => #t)
        (check (<= (bench-max-phase-duration
                    findings "typed-contract-facts")
                   +bench-typed-contract-phase-max-ms+)
               => #t)
        (check (<= (bench-max-phase-duration
                    findings "comment-quality-facts")
                   +bench-comment-quality-phase-max-ms+)
               => #t)
        (check (<= (bench-max-phase-duration
                    findings "top-form-scan")
                   +bench-top-form-scan-phase-max-ms+)
               => #t)
        (check (json-get finding "slowestBenchmarkName")
               => (json-get slowest "name"))))))
