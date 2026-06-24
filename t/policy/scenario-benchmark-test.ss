;;; -*- Gerbil -*-
;;; All policy scenario benchmarks must expose measured target budgets.

(import :gerbil/gambit
        :std/test
        :scenario/policy)
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
  (let* ((observed-ms (hash-get contract 'observedTotalMs))
         (target-ms (hash-get contract 'targetTotalMs))
         (max-ms (hash-get contract 'maxTotalMs))
         (regression-budget-ms (hash-get contract 'regressionBudgetMs))
         (observed-timings (hash-get contract 'observedTimings))
         (target-rationale (hash-get contract 'targetRationale)))
    (and (number? observed-ms)
         (number? target-ms)
         (number? max-ms)
         (number? regression-budget-ms)
         (pair? observed-timings)
         (string? target-rationale)
         (<= observed-ms target-ms)
         (< target-ms max-ms)
         (= max-ms (+ observed-ms regression-budget-ms)))))

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
