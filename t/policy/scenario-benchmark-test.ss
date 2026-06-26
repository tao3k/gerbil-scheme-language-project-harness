;;; -*- Gerbil -*-
;;; All policy scenario benchmarks must expose measured target budgets.

(import :gerbil/gambit
        :std/test
        :scenario/policy
        (only-in :support/time duration-literal->nanos))
(export scenario-benchmark-policy-test)

(def +scenario-benchmark-include-dirs+
  '("t/scenarios/policy"))
(def +scenario-benchmark-file+ "benchmark.ss")

;; : (-> String String )
(def (scenario-benchmark-dir path)
  (path-directory path))

;; : (-> String String )
(def (scenario-benchmark-child root name)
  (if (equal? root ".")
    name
    (string-append root "/" name)))

;; : (-> String (List String) (List String) )
(def (scenario-benchmark-paths/entries root entries)
  (cond
   ((null? entries) [])
   (else
    (let* ((name (car entries))
           (path (scenario-benchmark-child root name)))
      (cond
       ((eq? (file-type path) 'directory)
        (append (scenario-benchmark-paths path)
                (scenario-benchmark-paths/entries root (cdr entries))))
       ((equal? name +scenario-benchmark-file+)
        (cons path
              (scenario-benchmark-paths/entries root (cdr entries))))
       (else
        (scenario-benchmark-paths/entries root (cdr entries))))))))

;; : (-> (List String) )
(def (scenario-benchmark-paths root)
  (scenario-benchmark-paths/entries root (directory-files root)))

;; : (-> (List String) (List String) )
(def (scenario-benchmark-paths/include-dirs roots)
  (if (null? roots)
    []
    (append (scenario-benchmark-paths (car roots))
            (scenario-benchmark-paths/include-dirs (cdr roots)))))

;; : (-> String BenchmarkContract )
(def (scenario-benchmark-contract path)
  (policy-scenario-benchmark-contract
   (make-policy-scenario path (scenario-benchmark-dir path))))

;; : (-> BenchmarkContract Boolean )
(def (scenario-benchmark-targeted? contract)
  (let* ((observed-ns
          (duration-literal->nanos (hash-get contract 'observed_total)))
         (target-ns
          (duration-literal->nanos (hash-get contract 'target_total)))
         (max-ns
          (duration-literal->nanos (hash-get contract 'max_total)))
         (regression-budget-ns
          (duration-literal->nanos (hash-get contract 'regression_budget)))
         (observed-timings (hash-get contract 'observedTimings))
         (target-rationale (hash-get contract 'targetRationale)))
    (and observed-ns
         target-ns
         max-ns
         regression-budget-ns
         (pair? observed-timings)
         (string? target-rationale)
         (<= observed-ns target-ns)
         (< target-ns max-ns)
         (= max-ns (+ observed-ns regression-budget-ns)))))

;; : (-> (List String) (List String) )
(def (scenario-benchmark-paths-without-targets paths)
  (cond
   ((null? paths) [])
   ((scenario-benchmark-targeted?
     (scenario-benchmark-contract (car paths)))
    (scenario-benchmark-paths-without-targets (cdr paths)))
   (else
    (cons (car paths)
          (scenario-benchmark-paths-without-targets (cdr paths))))))

(def scenario-benchmark-policy-test
  (test-suite "gerbil scheme harness policy scenario benchmark contracts"
    (test-case "all policy scenario benchmarks carry measured target budgets"
      (let (paths (scenario-benchmark-paths/include-dirs
                   +scenario-benchmark-include-dirs+))
        (check (pair? paths) => #t)
        (check (scenario-benchmark-paths-without-targets paths)
               => [])))))
