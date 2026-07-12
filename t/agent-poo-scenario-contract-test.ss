(import
 :gerbil/gambit
 :std/test
 (only-in :std/misc/path path-expand)
 :gslph/t/policy/agent-poo-scenario-registry)

(export agent-poo-scenario-contract-test)

(def +representative-poo-scenario+
  "poo-marlin-config-interface-large-object-performance")

(def (scenario-benchmark-path scenario-id)
  (path-expand "benchmark.ss" (path-expand scenario-id "t/scenarios/policy")))

(def (missing-scenario-benchmarks scenario-ids)
  (cond
   ((null? scenario-ids) (@list))
   ((file-exists? (scenario-benchmark-path (car scenario-ids)))
    (missing-scenario-benchmarks (cdr scenario-ids)))
   (else
    (cons (scenario-benchmark-path (car scenario-ids))
          (missing-scenario-benchmarks (cdr scenario-ids))))))

(def agent-poo-scenario-contract-test
  (test-suite
   "gerbil scheme harness agent POO scenario smoke"
   (test-case
    "POO performance scenarios own benchmark files"
    (check (missing-scenario-benchmarks +poo-performance-scenario-ids+) => (@list)))
   (test-case
    "representative POO scenario is covered by native POO registry"
    (check (member +representative-poo-scenario+
                   +poo-native-primary-scenario-ids+)
           ? true)
    (check (member +representative-poo-scenario+
                   +poo-optimizer-visible-scenario-ids+)
           ? true))))
