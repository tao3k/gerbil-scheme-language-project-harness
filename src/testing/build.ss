;;; -*- Gerbil -*-
;;; Thin downstream build.ss API over the POO testing framework.

(import :gerbil/gambit
        (only-in :std/sugar filter)
        :testing/model
        :testing/framework)

(export #t)

(def (testing-build-path build relative)
  (path-expand relative (testing-object-ref build 'root ".")))

(def (testing-build-contract-root build)
  (testing-object-ref build 'contractRoot
                      (testing-object-ref build 'root ".")))

(def (testing-build-import->file build import)
  (and (string? import)
       (testing-build-path build (string-append "t/" import))))

(def (testing-build-gxtest-name spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (string? (car spec))) (car spec))
   (else "gxtest")))

(def (testing-build-gxtest-root spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (pair? (cdr spec))) (cadr spec))
   (else spec)))

(def (testing-build-policy-runner build)
  (lambda (scenario)
    (let (runs (testing-object-ref build 'scenarioRuns []))
      (vector-set! runs 0
                   (cons (testing-scenario-id scenario)
                         (vector-ref runs 0))))
    scenario))

(def (testing-build-gxtest-runner build)
  (lambda (files)
    (let (runs (testing-object-ref build 'gxtestRuns []))
      (vector-set! runs 0 (cons files (vector-ref runs 0))))
    0))

(def (testing-build-scenario-metadata build id)
  (let (entry (assoc id (testing-object-ref build 'scenarioMetadata [])))
    (if entry (cdr entry) [])))

(def (testing-build-policy-scenario build id)
  (make-policy-scenario
   id
   (testing-build-path
    build
    (path-expand id (testing-object-ref build 'scenarioRoot "policy-scenarios")))
   (testing-build-scenario-metadata build id)))

(def (testing-build-gxtest-suite build spec)
  (let ((root (testing-build-path build (testing-build-gxtest-root spec)))
        (contract-root (testing-build-contract-root build)))
    (gxtest-suite
     name: (testing-build-gxtest-name spec)
     default-root: root
     roots: (list root)
     batch-size: (testing-object-ref build 'batchSize 2)
     import->file: (lambda (import)
                     (testing-build-import->file build import))
     max-selected-files: (testing-object-ref build 'maxSelectedFiles 2)
     max-selected-sources: (testing-object-ref build 'maxSelectedSources 4)
     max-selected-outputs: (testing-object-ref build 'maxSelectedOutputs 4)
     gates: (list
             (performance-gate
              name: (testing-object-ref build 'name "testing-build")
              contract-root: contract-root)))))

(def (testing-build-policy-suite build)
  (let ((scenario-ids (testing-object-ref build 'scenarios [])))
    (and (not (null? scenario-ids))
         (policy-scenario-suite
          name: (testing-object-ref build 'scenarioSuiteName "policy-scenarios")
          root: (testing-build-path
                 build
                 (testing-object-ref build 'scenarioRoot "policy-scenarios"))
          scenarios: (map (lambda (id)
                            (testing-build-policy-scenario build id))
                          scenario-ids)
          batch-size: 1
          runner: (testing-build-policy-runner build)
          gates: (list
                  (performance-gate
                   name: (testing-object-ref build 'name "testing-build")
                   contract-root: (testing-build-contract-root build)))))))

(def (testing-build-filter values)
  (filter identity values))

(def (testing-build-project build)
  (let* ((gxtest-suites
          (map (lambda (spec)
                 (testing-build-gxtest-suite build spec))
               (testing-object-ref build 'gxtest [])))
         (policy-suite (testing-build-policy-suite build))
         (project-roots
          (map (lambda (root)
                 (testing-build-path build root))
               (testing-object-ref build 'roots
                                   ["src" "t" "policy-scenarios"]))))
    (testing-project
     name: (testing-object-ref build 'name "testing-build")
     suites: (append gxtest-suites (testing-build-filter (list policy-suite)))
     roots: project-roots
     batch-size: (testing-object-ref build 'batchSize 2)
     receipt-prefix: (testing-object-ref build 'receiptPrefix
                                         (testing-object-ref build 'name "testing-build")))))

(def (testing-build name: (name "testing-build")
                    root: (root ".")
                    contract-root: (contract-root #f)
                    gxtest: (gxtest [])
                    scenarios: (scenarios [])
                    improvement-scenarios: (improvement-scenarios #f)
                    scenario-metadata: (scenario-metadata [])
                    scenario-root: (scenario-root "policy-scenarios")
                    scenario-suite-name: (scenario-suite-name "policy-scenarios")
                    roots: (roots ["src" "t" "policy-scenarios"])
                    batch-size: (batch-size 2)
                    max-selected-files: (max-selected-files 2)
                    max-selected-sources: (max-selected-sources 4)
                    max-selected-outputs: (max-selected-outputs 4)
                    receipt-prefix: (receipt-prefix #f))
  (testing-object
   'testing-build
   `((name . ,name)
     (root . ,root)
     (contractRoot . ,(or contract-root root))
     (gxtest . ,gxtest)
     (scenarios . ,(or improvement-scenarios scenarios))
     (scenarioMetadata . ,scenario-metadata)
     (scenarioRoot . ,scenario-root)
     (scenarioSuiteName . ,scenario-suite-name)
     (roots . ,roots)
     (batchSize . ,batch-size)
     (maxSelectedFiles . ,max-selected-files)
     (maxSelectedSources . ,max-selected-sources)
     (maxSelectedOutputs . ,max-selected-outputs)
     (receiptPrefix . ,(or receipt-prefix name))
     (gxtestRuns . ,(vector []))
     (scenarioRuns . ,(vector [])))))

(def (testing-build-reset! build)
  (vector-set! (testing-object-ref build 'gxtestRuns) 0 [])
  (vector-set! (testing-object-ref build 'scenarioRuns) 0 []))

(def (testing-build-gxtest-runs build)
  (reverse (vector-ref (testing-object-ref build 'gxtestRuns) 0)))

(def (testing-build-scenario-runs build)
  (reverse (vector-ref (testing-object-ref build 'scenarioRuns) 0)))

(def (testing-build-select build args)
  (testing-select-project (testing-build-project build) args))

(def (testing-build-main build args)
  (testing-run-selection
   (testing-build-select build args)
   (testing-build-gxtest-runner build)))
