;;; -*- Gerbil -*-
;;; Verification benchmark command for harness hot paths.

(import :gerbil/gambit
        :checker/facade
        (only-in :commands/search-prime-light
                 search-prime-light-main)
        (only-in :commands/search-workspace-scope-light
                 search-workspace-scope-light-main)
        :constants
        :parser/facade
        :protocol/json
        (only-in :std/iter for in-range)
        (only-in :std/srfi/1 append-map)
        (only-in :std/sugar filter-map foldl)
        :support/args
        :support/io
        :support/time
        :types/facade)

(export bench-main)
;; String
(def +bench-schema-id+ "agent.semantic-protocols.gerbil-scheme-harness-bench")
;; String
(def +bench-mode-hot+ "hot")
;; String
(def +bench-mode-full+ "full")
;; Integer
(def +default-max-total-ms+ 100)
;; Integer
(def +default-max-collect-ms+ 1000)
;; Integer
(def +default-max-parse-ms+ 750)
;; Integer
(def +default-max-file-ms+ 250)
;; Integer
(def +default-max-phase-ms+ 100)
;; Integer
(def +default-max-interface-ms+ 50)
;; : (-> Args String)
(def (bench-mode args)
  (let (mode (or (option "--mode" args) +bench-mode-hot+))
    (cond
     ((or (equal? mode +bench-mode-hot+)
          (equal? mode +bench-mode-full+))
      mode)
     (else
      (error "invalid bench mode" mode)))))
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
;;       and returns timing metadata for the named benchmark. Runtime
;;       stabilization happens before each measured iteration so one benchmark
;;       step does not inherit heap pressure from a previous step.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-step "noop" 1 (lambda () #!void))
;;       ;; => benchmark packet
;;       ```
;;     %
(def (bench-step name iterations thunk)
  (let (elapsed-ms (bench-total-duration-ms iterations thunk))
    (hash (name name)
          (iterations iterations)
          (durationMs elapsed-ms)
          (averageMicros (average-duration-micros elapsed-ms iterations))
          (averageMs (average-duration-ms elapsed-ms iterations)))))
;; : (-> Integer Thunk Integer)
(def (bench-total-duration-ms iterations thunk)
  (foldl (lambda (_ elapsed-ms)
           (+ elapsed-ms (bench-iteration-duration-ms thunk)))
         0
         (make-list iterations #!void)))
;; : (-> Thunk Integer)
(def (bench-iteration-duration-ms thunk)
  (stabilize-bench-runtime!)
  (let (start (monotonic-ms))
    (thunk)
    (duration-ms start (monotonic-ms))))
;; : (-> Thunk Void)
(def (bench-silenced thunk)
  (let (value #!void)
    (call-with-output-string
      (lambda (out)
        (parameterize ((current-output-port out)
                       (current-error-port out))
          (set! value (thunk)))))
    value))

;; : (-> String Void)
(def (bench-search-prime-light root)
  (let (status
        (bench-silenced
         (lambda ()
           (search-prime-light-main
            ["prime" "--view" "seeds" "--workspace" root]))))
    (unless (= status 0)
      (error "search-prime-light benchmark failed" status))))

;; : (-> String Void)
(def (bench-workspace-scope-light root)
  (let (status
        (bench-silenced
         (lambda ()
           (search-workspace-scope-light-main
            ["workspace-scope" "--workspace" root]))))
    (unless (= status 0)
      (error "workspace-scope-light benchmark failed" status))))

;; : (-> String Integer (List Benchmark))
(def (bench-hot-paths root iterations)
  [(bench-step "search-prime-light" iterations
               (lambda () (bench-search-prime-light root)))
   (bench-step "workspace-scope-light" iterations
               (lambda () (bench-workspace-scope-light root)))])

;; : (-> String Integer Whitelist (Values ProjectIndex (List TypeFinding) (List Benchmark) CollectProfile))
(def (bench-full-paths root iterations whitelist)
  (let ((index #f)
        (collect-profile #f)
        (findings '())
        (structural-packet #f)
        (owner-file #f))
    (let (benchmarks
          [(bench-step "collect-project" iterations
                       (lambda ()
                         (let (result (collect-project/profile root))
                           (set! index (hash-get result 'index))
                           (set! collect-profile
                             (hash-get result 'profile)))))
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
      (values index findings benchmarks collect-profile))))
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
;; : (-> Hash Key Datum Datum)
(def (hash-get/default table key default)
  (if (hash-key? table key)
    (hash-get table key)
    default))
;; collect-profile-phase
;;   : (-> CollectProfile String (U #f Hash))
;;   | doc m%
;;       `collect-profile-phase collect-profile name` returns the first
;;       aggregate profile phase with the requested name.
;;
;;       # Examples
;;
;;       ```scheme
;;       (collect-profile-phase profile "parse-source-files")
;;       ;; => phase hash or #f
;;       ```
;;     %
(def (collect-profile-phase collect-profile name)
  (let loop ((rest (hash-get/default collect-profile 'phases '())))
    (match rest
      ([phase . more]
       (if (equal? (hash-get/default phase 'name "") name)
         phase
         (loop more)))
      (else #f))))
;; : (-> CollectProfile MaxCollectMs (List TypeFinding))
(def (bench-collect-findings collect-profile max-collect-ms)
  (if (and collect-profile max-collect-ms)
    (let (total-ms (hash-get/default collect-profile 'totalMs 0))
      (if (> total-ms max-collect-ms)
        [(hash (kind "collect-threshold-exceeded")
               (severity "warning")
               (summary "collect-project/profile exceeded --max-collect-ms")
               (durationMs total-ms)
               (maxCollectMs max-collect-ms)
               (exceededByMs (- total-ms max-collect-ms)))]
        '()))
    '()))
;; : (-> CollectProfile MaxParseMs (List TypeFinding))
(def (bench-parse-findings collect-profile max-parse-ms)
  (if (and collect-profile max-parse-ms)
    (let (phase (collect-profile-phase collect-profile "parse-source-files"))
      (if phase
        (let (duration-ms (hash-get/default phase 'durationMs 0))
          (if (> duration-ms max-parse-ms)
            [(hash (kind "parse-threshold-exceeded")
                   (severity "warning")
                   (summary "parse-source-files exceeded --max-parse-ms")
                   (phaseName "parse-source-files")
                   (durationMs duration-ms)
                   (maxParseMs max-parse-ms)
                   (workerCount (hash-get/default phase 'workerCount 0))
                   (scheduler (hash-get/default phase 'scheduler ""))
                   (exceededByMs (- duration-ms max-parse-ms)))]
            '()))
        '()))
    '()))
;; : (-> CollectProfile MaxFileMs (List TypeFinding))
(def (bench-file-findings collect-profile max-file-ms)
  (if (and collect-profile max-file-ms)
    (filter-map
     (lambda (file-profile)
       (let (duration-ms (hash-get/default file-profile 'durationMs 0))
         (and (> duration-ms max-file-ms)
              (hash (kind "file-threshold-exceeded")
                    (severity "warning")
                    (summary "source file parse profile exceeded --max-file-ms")
                    (path (hash-get/default file-profile 'path ""))
                    (durationMs duration-ms)
                    (maxFileMs max-file-ms)
                    (exceededByMs (- duration-ms max-file-ms))))))
     (hash-get/default collect-profile 'slowestFiles '()))
    '()))
;; bench-phase-findings
;;   : (-> CollectProfile MaxPhaseMs (List TypeFinding))
;;   | doc m%
;;       `bench-phase-findings collect-profile max-phase-ms` returns threshold
;;       findings for parse phases whose measured duration exceeds the phase
;;       budget.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-phase-findings profile 50)
;;       ;; => phase threshold findings
;;       ```
;;     %
(def (bench-phase-findings collect-profile max-phase-ms)
  (if (and collect-profile max-phase-ms)
    (let loop-files ((files (hash-get/default collect-profile 'slowestFiles '()))
                     (finding-groups '()))
      (match files
        ([file-profile . more-files]
         (let* ((path (hash-get/default file-profile 'path ""))
                (phase-findings
                 (filter-map
                  (lambda (phase)
                    (let (duration-ms (hash-get/default phase 'durationMs 0))
                      (and (> duration-ms max-phase-ms)
                           (hash (kind "phase-threshold-exceeded")
                                 (severity "warning")
                                 (summary "source file parse phase exceeded --max-phase-ms")
                                 (path path)
                                 (phaseName (hash-get/default phase 'name ""))
                                 (durationMs duration-ms)
                                 (maxPhaseMs max-phase-ms)
                                 (exceededByMs (- duration-ms max-phase-ms))))))
                  (hash-get/default file-profile 'phases '()))))
           (loop-files more-files (cons phase-findings finding-groups))))
        (else (apply append (reverse finding-groups)))))
    '()))
;; : (-> CollectProfile MaxCollectMs MaxParseMs MaxFileMs MaxPhaseMs (List TypeFinding))
(def (bench-collect-profile-findings collect-profile max-collect-ms max-parse-ms max-file-ms max-phase-ms)
  (append
   (bench-collect-findings collect-profile max-collect-ms)
   (bench-parse-findings collect-profile max-parse-ms)
   (bench-file-findings collect-profile max-file-ms)
   (bench-phase-findings collect-profile max-phase-ms)))
;; : (-> TotalMs MaxTotalMs MaxInterfaceMs MaxCollectMs MaxParseMs MaxFileMs MaxPhaseMs Slowest Benchmarks CollectProfile (List TypeFinding) )
(def (bench-performance-findings total-ms max-total-ms max-interface-ms
                                 max-collect-ms max-parse-ms max-file-ms max-phase-ms
                                 slowest benchmarks collect-profile)
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
   (bench-interface-findings max-interface-ms benchmarks)
   (bench-collect-profile-findings
    collect-profile max-collect-ms max-parse-ms max-file-ms max-phase-ms)))

;; : (-> (U #f CollectProfile) Number)
(def (bench-observed-collect-ms collect-profile)
  (if collect-profile
    (hash-get/default collect-profile 'totalMs 0)
    0))

;; : (-> (U #f CollectProfile) Number)
(def (bench-observed-parse-ms collect-profile)
  (if collect-profile
    (let (phase (collect-profile-phase collect-profile "parse-source-files"))
      (if phase (hash-get/default phase 'durationMs 0) 0))
    0))

;; : (-> (U #f CollectProfile) Number)
(def (bench-observed-file-ms collect-profile)
  (if collect-profile
    (let loop ((files (hash-get/default collect-profile 'slowestFiles '()))
               (max-ms 0))
      (match files
        ([file-profile . more]
         (let (duration-ms (hash-get/default file-profile 'durationMs 0))
           (loop more (if (> duration-ms max-ms) duration-ms max-ms))))
        (else max-ms)))
    0))

(def (bench-profile-duration-ms profile)
  (hash-get/default profile 'durationMs 0))

(def (bench-max-profile-duration-ms profiles)
  (foldl (lambda (profile max-ms)
           (max max-ms (bench-profile-duration-ms profile)))
         0
         profiles))

(def (bench-file-profile-phases file-profile)
  (hash-get/default file-profile 'phases '()))

;; : (-> (U #f CollectProfile) Number)
(def (bench-observed-phase-ms collect-profile)
  (if collect-profile
    (bench-max-profile-duration-ms
     (append-map bench-file-profile-phases
                 (hash-get/default collect-profile 'slowestFiles '())))
    0))

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
          ["search-prime-light"
           "workspace-scope-light"
           "structural-interface-packet"
           "structural-owner-facts-packet"]))
;; bench-packet
;;   : (-> String String Integer (U #f Integer) (U #f Integer) (U #f Integer)
;;         (U #f Integer) (U #f Integer) (U #f Integer) ProjectIndex
;;         (List TypeFinding) (List Benchmark)
;;         JsonPacket)
;;   | doc m%
;;       `bench-packet root iterations ... index findings benchmarks` builds
;;       the benchmark result packet and threshold findings.
;;
;;       # Examples
;;
;;       ```scheme
;;       (bench-packet "." "hot" 1 #f #f #f #f #f #f index findings benchmarks #f)
;;       ;; => benchmark JSON packet
;;       ```
;;     %
(def (bench-packet root mode iterations max-total-ms max-interface-ms
                   max-collect-ms max-parse-ms max-file-ms max-phase-ms
                   index findings benchmarks collect-profile)
  (let* ((total-ms (sum-duration-ms benchmarks))
         (slowest (slowest-benchmark benchmarks))
         (performance-findings
          (bench-performance-findings
           total-ms max-total-ms max-interface-ms
           max-collect-ms max-parse-ms max-file-ms max-phase-ms
           slowest benchmarks collect-profile))
         (status (if (null? performance-findings) "pass" "fail"))
         (packet
          (hash (schemaId +bench-schema-id+)
                (schemaVersion "1")
                (languageId +language-id+)
                (providerId +provider-id+)
                (projectRoot root)
                (mode mode)
                (status status)
                (iterations iterations)
                (totalMs total-ms)
                (files (if index (length (project-index-files index)) 0))
                (definitions (if index (length (project-definitions index)) 0))
                (findings (length findings))
                (performanceFindings performance-findings)
                (slowestBenchmark slowest)
                (benchmarks benchmarks))))
    (when collect-profile
      (hash-put! packet 'collectProjectProfile collect-profile))
    (when max-total-ms
      (hash-put! packet 'maxTotalMs max-total-ms))
    (when max-interface-ms
      (hash-put! packet 'maxInterfaceMs max-interface-ms))
    (when max-collect-ms
      (hash-put! packet 'maxCollectMs max-collect-ms)
      (hash-put! packet 'observedCollectMs
                 (bench-observed-collect-ms collect-profile)))
    (when max-parse-ms
      (hash-put! packet 'maxParseMs max-parse-ms)
      (hash-put! packet 'observedParseMs
                 (bench-observed-parse-ms collect-profile)))
    (when max-file-ms
      (hash-put! packet 'maxFileMs max-file-ms)
      (hash-put! packet 'observedFileMs
                 (bench-observed-file-ms collect-profile)))
    (when max-phase-ms
      (hash-put! packet 'maxPhaseMs max-phase-ms)
      (hash-put! packet 'observedPhaseMs
                 (bench-observed-phase-ms collect-profile)))
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
    (line-field "mode" (hash-get packet 'mode))
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
     (emit-field-line
      "|performanceFinding"
      [(line-field "kind" (hash-get/default finding 'kind ""))
       (line-field "severity" (hash-get/default finding 'severity ""))
       (line-field "summary" (hash-get/default finding 'summary ""))
       (line-field "path" (hash-get/default finding 'path ""))
       (line-field "phase" (hash-get/default finding 'phaseName ""))
       (line-field "benchmark" (hash-get/default finding 'benchmarkName ""))
       (line-field "totalMs" (hash-get/default finding 'totalMs ""))
       (line-field "durationMs" (hash-get/default finding 'durationMs ""))
       (line-field "maxTotalMs" (hash-get/default finding 'maxTotalMs ""))
       (line-field "maxInterfaceMs" (hash-get/default finding 'maxInterfaceMs ""))
       (line-field "maxCollectMs" (hash-get/default finding 'maxCollectMs ""))
       (line-field "maxParseMs" (hash-get/default finding 'maxParseMs ""))
       (line-field "maxFileMs" (hash-get/default finding 'maxFileMs ""))
       (line-field "maxPhaseMs" (hash-get/default finding 'maxPhaseMs ""))
       (line-field "exceededByMs" (hash-get/default finding 'exceededByMs ""))
       (line-field "slowest" (hash-get/default finding 'slowestBenchmarkName ""))
       (line-field "slowestDurationMs" (hash-get/default finding 'slowestBenchmarkDurationMs ""))
       (line-field "workerCount" (hash-get/default finding 'workerCount ""))
       (line-field "scheduler" (hash-get/default finding 'scheduler ""))]))
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
         (mode (bench-mode args))
         (json? (flag? "--json" args))
         (iterations (positive-integer-option "--iterations" args 1))
         (max-total-ms (or (optional-positive-integer-option "--max-total-ms" args)
                           +default-max-total-ms+))
         (max-interface-ms (or (optional-positive-integer-option "--max-interface-ms" args)
                               +default-max-interface-ms+))
         (max-collect-ms (or (optional-positive-integer-option "--max-collect-ms" args)
                             +default-max-collect-ms+))
         (max-parse-ms (or (optional-positive-integer-option "--max-parse-ms" args)
                           +default-max-parse-ms+))
         (max-file-ms (or (optional-positive-integer-option "--max-file-ms" args)
                          +default-max-file-ms+))
         (max-phase-ms (or (optional-positive-integer-option "--max-phase-ms" args)
                           +default-max-phase-ms+))
         (whitelist-path (option "--whitelist" args))
         (whitelist (if whitelist-path
                      (load-call-whitelist whitelist-path)
                      '())))
    (let* ((index #f)
           (findings '())
           (collect-profile #f)
           (benchmarks
            (if (equal? mode +bench-mode-full+)
              (let-values (((full-index full-findings full-benchmarks full-profile)
                            (bench-full-paths root iterations whitelist)))
                (set! index full-index)
                (set! findings full-findings)
                (set! collect-profile full-profile)
                full-benchmarks)
              (bench-hot-paths root iterations)))
           (packet (bench-packet root mode iterations
                                 max-total-ms max-interface-ms
                                 max-collect-ms max-parse-ms max-file-ms max-phase-ms
                                 index findings benchmarks collect-profile)))
      (if json?
        (write-json-line packet)
        (display-bench-packet packet))
      (if (equal? (hash-get packet 'status) "pass") 0 1))))
