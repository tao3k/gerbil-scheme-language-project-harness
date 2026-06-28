;;; -*- Gerbil -*-
;;; Full bench receipt tests.

(import :gerbil/gambit
        :std/test
        :bench-support
        (only-in :std/text/json read-json))
(export bench-full-test)

;; String
(def +bench-full-fixture-root+ ".run/bench-full-fixture")

;; : (-> String Void)
(def (bench-full-ensure-dir path)
  (with-catch
   (lambda (_) #!void)
   (lambda ()
     (unless (file-exists? path)
       (create-directory path)))))

;; : (-> String String Void)
(def (bench-full-write-text path text)
  (with-catch
   (lambda (_) #!void)
   (lambda () (delete-file path)))
  (call-with-output-file path
    (lambda (out) (display text out))))

;; : (-> Void)
(def (prepare-bench-full-fixture!)
  (let (src-root (string-append +bench-full-fixture-root+ "/src"))
    (bench-full-ensure-dir ".run")
    (bench-full-ensure-dir +bench-full-fixture-root+)
    (bench-full-ensure-dir src-root)
    (bench-full-write-text
     (string-append +bench-full-fixture-root+ "/gerbil.pkg")
     ";;; Boundary:\n;;; - Full bench fixture keeps unit tests independent of harness repository size.\n(package: bench/full-fixture)\n")
    (bench-full-write-text
     (string-append src-root "/core.ss")
     ";;; -*- Gerbil -*-\n;;; Boundary:\n;;; - This fixture exercises full bench collect/type-check/profile packet shape.\n(import :gerbil/gambit)\n(export fixture-score fixture-fold)\n;; : (-> Integer Integer)\n(def (fixture-score n)\n  (+ n 1))\n;; : (-> (List Integer) Integer)\n(def (fixture-fold values)\n  (let loop ((rest values) (total 0))\n    (match rest\n      ([] total)\n      ([value . more]\n       (loop more (+ total (fixture-score value)))))))\n")))

;; BenchFullTest
(def bench-full-test
  (test-suite "gerbil scheme harness full bench"
    (test-case "bench full mode records cold profile and threshold findings"
      (prepare-bench-full-fixture!)
      (let* ((output (bench-output/status
                      ["--json" "--mode" "full" "--iterations" "1"
                       "--max-total-ms" "1"
                       "--max-interface-ms" "1"
                       "--max-collect-ms" "1"
                       "--max-parse-ms" "1"
                       "--max-file-ms" "1"
                       "--max-phase-ms" "1"
                       +bench-full-fixture-root+]
                      1))
             (packet (call-with-input-string output read-json))
             (benchmarks (json-get packet "benchmarks"))
             (first-benchmark (car benchmarks))
             (collect-profile (json-get packet "collectProjectProfile"))
             (profile-phases (json-get collect-profile "phases"))
             (slowest-files (json-get collect-profile "slowestFiles"))
             (findings (json-get packet "performanceFindings"))
             (finding (find-performance-finding findings "total-threshold-exceeded"))
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
        (check (>= (json-get packet "observedCollectMs") 0) => #t)
        (check (>= (json-get packet "observedParseMs") 0) => #t)
        (check (>= (json-get packet "observedFileMs") 0) => #t)
        (check (>= (json-get packet "observedPhaseMs") 0) => #t)
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
        (check (json-get finding "kind") => "total-threshold-exceeded")
        (check (json-get finding "severity") => "warning")
        (check (json-get finding "maxTotalMs") => 1)
        (check (>= (json-get finding "exceededByMs") 0) => #t)
        (check (json-get finding "slowestBenchmarkName")
               => (json-get slowest "name"))))))
