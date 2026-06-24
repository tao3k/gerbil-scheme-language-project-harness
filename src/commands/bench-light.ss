;;; -*- Gerbil -*-
;;; Lightweight benchmark command for native hot-path gates.

(import :gerbil/gambit
        :constants
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/srfi/1 last)
        (only-in :std/srfi/13 string-prefix?)
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

(def (flag? flag args)
  (and (member flag args) #t))

(def (option flag args)
  (match args
    ([] #f)
    ([hd value . rest]
     (if (equal? hd flag) value (option flag (cons value rest))))
    ([_] #f)))

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

(def (file-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))

(def (project-root args)
  (or (option "--workspace" args)
      (let (pos (positional-args args))
        (if (and (pair? pos) (file-directory? (last pos)))
          (last pos)
          "."))))

(def (bench-mode args)
  (cond
   ((flag? "--full" args) +bench-mode-full+)
   ((option "--mode" args) => identity)
   (else +bench-mode-hot+)))

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

(def (bench-silenced thunk)
  (let (value #!void)
    (call-with-output-string
      (lambda (out)
        (parameterize ((current-output-port out)
                       (current-error-port out))
          (set! value (thunk)))))
    value))

(def (bench-step name iterations thunk)
  (let loop ((remaining iterations)
             (elapsed-ms 0))
    (if (fxzero? remaining)
      (hash (name name)
            (iterations iterations)
            (durationMs elapsed-ms)
            (averageMicros (average-duration-micros elapsed-ms iterations))
            (averageMs (average-duration-ms elapsed-ms iterations)))
      (let (start (monotonic-ms))
        (thunk)
        (loop (fx1- remaining)
              (+ elapsed-ms
                 (duration-ms start (monotonic-ms))))))))

(def (run-fast-search args)
  (let (status (bench-silenced (lambda () (try-search-light-main args))))
    (unless (= status 0)
      (error "native fast search benchmark failed" args status))))

(def (bench-hot-paths root iterations)
  [(bench-step "search-prime-light" iterations
               (lambda ()
                 (run-fast-search
                  ["prime" "--view" "seeds" "--workspace" root])))
   (bench-step "workspace-scope-light" iterations
               (lambda ()
                 (run-fast-search
                  ["workspace-scope" "--workspace" root])))])

(def (benchmark-name benchmark)
  (hash-get benchmark 'name))

(def (benchmark-duration-ms benchmark)
  (hash-get benchmark 'durationMs))

(def (sum-duration-ms benchmarks)
  (let loop ((rest benchmarks) (total 0))
    (match rest
      ([] total)
      ([benchmark . more]
       (loop more (+ total (benchmark-duration-ms benchmark)))))))

(def (slowest-benchmark benchmarks)
  (let loop ((rest (cdr benchmarks)) (best (car benchmarks)))
    (match rest
      ([] best)
      ([benchmark . more]
       (if (> (benchmark-duration-ms benchmark)
              (benchmark-duration-ms best))
         (loop more benchmark)
         (loop more best))))))

(def (bench-interface-benchmark? benchmark)
  (member (benchmark-name benchmark)
          ["search-prime-light" "workspace-scope-light"]))

(def (bench-interface-findings max-interface-ms benchmarks)
  (if max-interface-ms
    (let loop ((rest benchmarks) (out '()))
      (match rest
        ([] (reverse out))
        ([benchmark . more]
         (if (and (bench-interface-benchmark? benchmark)
                  (> (benchmark-duration-ms benchmark) max-interface-ms))
           (loop more
                 (cons (hash
                        (kind "interface-threshold-exceeded")
                        (severity "warning")
                        (summary "native hot-path benchmark exceeded --max-interface-ms")
                        (benchmarkName (benchmark-name benchmark))
                        (durationMs (benchmark-duration-ms benchmark))
                        (maxInterfaceMs max-interface-ms)
                        (exceededByMs
                         (- (benchmark-duration-ms benchmark)
                            max-interface-ms)))
                       out))
           (loop more out)))))
    '()))

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

(def (hash-get/default table key default)
  (if (hash-key? table key)
    (hash-get table key)
    default))

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

(def (display-benchmark benchmark)
  (displayln "|bench name=" (benchmark-name benchmark)
             " iterations=" (hash-get benchmark 'iterations)
             " durationMs=" (benchmark-duration-ms benchmark)
             " averageMicros=" (hash-get benchmark 'averageMicros)
             " averageMs=" (hash-get benchmark 'averageMs)))

(def (display-bench-packet packet)
  (displayln "[gerbil-bench] status=" (hash-get packet 'status)
             " mode=" (hash-get packet 'mode)
             " totalMs=" (hash-get packet 'totalMs)
             " iterations=" (hash-get packet 'iterations)
             " files=" (hash-get packet 'files)
             " definitions=" (hash-get packet 'definitions)
             " findings=" (hash-get packet 'findings))
  (let (slowest (hash-get packet 'slowestBenchmark))
    (displayln "|slowest name=" (hash-get slowest 'name)
               " durationMs=" (hash-get slowest 'durationMs)))
  (for-each display-performance-finding
            (hash-get packet 'performanceFindings))
  (for-each display-benchmark
            (hash-get packet 'benchmarks)))

(def (write-json-line value)
  (write-json value)
  (newline))

(def (ensure-runtime-loader!)
  (##global-var-set! (##make-global-var 'load-module) load-module))

(def (bench-full-main args)
  (ensure-runtime-loader!)
  (load-module "gslph/src/commands/bench")
  ((eval 'gslph/src/commands/bench#bench-main) args))

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

(def (bench-light-main args)
  (if (equal? (bench-mode args) +bench-mode-full+)
    (bench-full-main args)
    (bench-hot-main args)))
