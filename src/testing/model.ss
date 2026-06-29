;;; -*- Gerbil -*-
;;; POO-shaped testing model for downstream Gerbil build.ss entrypoints.

(import :gerbil/gambit
        (only-in :clan/poo/object object? object<-alist .ref .slot?))

(export #t)

(def (testing-object kind fields)
  (object<-alist (cons (cons 'kind kind) fields)))

(def (testing-native-poo-object kind source fields)
  (unless (object? source)
    (error "testing-native-poo-object expects a POO object" source))
  (testing-object
   kind
   (map (lambda (field)
          (cons field (.ref source field)))
        fields)))

(def (testing-object-kind object)
  (testing-object-ref object 'kind))

(def (testing-object-ref object key (default #f))
  (unless (object? object)
    (error "testing-object-ref expects a POO object" object))
  (if (.slot? object key)
    (.ref object key)
    default))

(def (testing-project name: (name "gerbil-project")
                      suites: (suites [])
                      roots: (roots '("t"))
                      batch-size: (batch-size #f)
                      receipt-prefix: (receipt-prefix "gslph-test"))
  (testing-object
   'testing-project
   `((name . ,name)
     (suites . ,suites)
     (roots . ,roots)
     (batchSize . ,batch-size)
     (receiptPrefix . ,receipt-prefix))))

(def (gxtest-suite name: (name "gxtest")
                   default-root: (default-root #f)
                   roots: (roots [])
                   files: (files 'auto)
                   batch-size: (batch-size #f)
                   gates: (gates [])
                   max-selected-files: (max-selected-files #f)
                   max-selected-sources: (max-selected-sources #f)
                   max-selected-outputs: (max-selected-outputs #f)
                   import->file: (import->file default-testing-import->file))
  (testing-object
   'gxtest-suite
   `((name . ,name)
     (defaultRoot . ,default-root)
     (roots . ,roots)
     (files . ,files)
     (batchSize . ,batch-size)
     (gates . ,gates)
     (maxSelectedFiles . ,max-selected-files)
     (maxSelectedSources . ,max-selected-sources)
     (maxSelectedOutputs . ,max-selected-outputs)
     (import->file . ,import->file))))

(def (scenario-suite name: (name "policy-scenarios")
                     roots: (roots '("t/scenarios/policy"))
                     scenarios: (scenarios [])
                     batch-size: (batch-size #f)
                     gates: (gates [])
                     runner: (runner #f))
  (testing-object
   'scenario-suite
   `((name . ,name)
     (roots . ,roots)
     (scenarios . ,scenarios)
     (batchSize . ,batch-size)
     (gates . ,gates)
     (runner . ,runner))))

(def (performance-gate name: (name "performance")
                       contract-root: (contract-root #f)
                       contract: (contract #f)
                       scope: (scope 'tested-files))
  (testing-object
   'performance-gate
   `((name . ,name)
     (contractRoot . ,contract-root)
     (contract . ,contract)
     (scope . ,scope))))

(def (policy-gate name: (name "policy")
                  scope: (scope 'tested-files))
  (testing-object
   'policy-gate
   `((name . ,name)
     (scope . ,scope))))

(def (testing-receipt kind: (kind 'testing-run)
                      status: (status 'ok)
                      suite: (suite #f)
                      files: (files [])
                      elapsed-seconds: (elapsed-seconds 0)
                      children: (children [])
                      details: (details []))
  (testing-object
   'testing-receipt
   `((receiptKind . ,kind)
     (status . ,status)
     (suite . ,suite)
     (files . ,files)
     (elapsedSeconds . ,elapsed-seconds)
     (children . ,children)
     (details . ,details))))

(def (testing-selection project: (project #f)
                        args: (args [])
                        suites: (suites [])
                        status: (status 'ok)
                        details: (details []))
  (testing-object
   'testing-selection
   `((project . ,project)
     (args . ,args)
     (suites . ,suites)
     (status . ,status)
     (details . ,details))))

(def (testing-project-name project)
  (testing-object-ref project 'name))

(def (testing-project-suites project)
  (testing-object-ref project 'suites []))

(def (testing-project-batch-size project)
  (testing-object-ref project 'batchSize #f))

(def (testing-project-receipt-prefix project)
  (testing-object-ref project 'receiptPrefix "gslph-test"))

(def (testing-suite-name suite)
  (testing-object-ref suite 'name))

(def (testing-suite-default-root suite)
  (testing-object-ref suite 'defaultRoot #f))

(def (testing-suite-roots suite)
  (testing-object-ref suite 'roots []))

(def (testing-suite-files suite)
  (testing-object-ref suite 'files 'auto))

(def (testing-suite-batch-size suite)
  (testing-object-ref suite 'batchSize #f))

(def (testing-suite-gates suite)
  (testing-object-ref suite 'gates []))

(def (testing-suite-max-selected-files suite)
  (testing-object-ref suite 'maxSelectedFiles #f))

(def (testing-suite-max-selected-sources suite)
  (testing-object-ref suite 'maxSelectedSources #f))

(def (testing-suite-max-selected-outputs suite)
  (testing-object-ref suite 'maxSelectedOutputs #f))

(def (testing-suite-import->file suite)
  (testing-object-ref suite 'import->file default-testing-import->file))

(def (testing-scenario-suite-scenarios suite)
  (testing-object-ref suite 'scenarios []))

(def (testing-scenario-suite-runner suite)
  (testing-object-ref suite 'runner #f))

(def (testing-gate-name gate)
  (testing-object-ref gate 'name))

(def (testing-gate-scope gate)
  (testing-object-ref gate 'scope))

(def (testing-performance-gate-contract-root gate)
  (testing-object-ref gate 'contractRoot))

(def (testing-receipt-status receipt)
  (testing-object-ref receipt 'status))

(def (testing-receipt-kind receipt)
  (testing-object-ref receipt 'receiptKind))

(def (testing-receipt-files receipt)
  (testing-object-ref receipt 'files []))

(def (testing-receipt-children receipt)
  (testing-object-ref receipt 'children []))

(def (testing-receipt-details receipt)
  (testing-object-ref receipt 'details []))

(def (testing-receipt-phases receipt)
  (let (entry (assq 'phases (testing-receipt-details receipt)))
    (if entry (cdr entry) [])))

(def (testing-receipt-ok? receipt)
  (eq? (testing-receipt-status receipt) 'ok))

(def (testing-selection-project selection)
  (testing-object-ref selection 'project))

(def (testing-selection-args selection)
  (testing-object-ref selection 'args []))

(def (testing-selection-suites selection)
  (testing-object-ref selection 'suites []))

(def (testing-selection-status selection)
  (testing-object-ref selection 'status))

(def (testing-selection-details selection)
  (testing-object-ref selection 'details []))

(def (testing-selection-ok? selection)
  (eq? (testing-selection-status selection) 'ok))

(def (default-testing-import->file import)
  (cond
   ((string? import) import)
   ((symbol? import) (symbol->string import))
   (else #f)))
