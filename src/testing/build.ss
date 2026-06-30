;;; -*- Gerbil -*-
;;; Thin downstream build.ss API over the POO testing framework.

(import :gerbil/gambit
        (only-in :std/misc/process run-process)
        (only-in :std/sugar filter)
        :testing/model
        :testing/framework)

(export #t)

;; : (-> TestingBuild Path Path)
(def (testing-build-path build relative)
  (path-expand relative (testing-object-ref build 'root ".")))

;; : (-> TestingBuild Path)
(def (testing-build-contract-root build)
  (testing-object-ref build 'contractRoot
                      (testing-object-ref build 'root ".")))

;; : (-> TestingBuild String MaybePath)
(def (testing-build-prefixed-import->file build module-name)
  (let (prefix (testing-object-ref build 'importPrefix #f))
    (and prefix
         (testing-string-prefix? prefix module-name)
         (string-append
          "t/"
          (substring module-name
                     (string-length prefix)
                     (string-length module-name))
          ".ss"))))

;; : (-> TestingBuild Datum MaybePath)
(def (testing-build-import->file build import)
  (cond
   ((string? import)
    (testing-build-path build (string-append "t/" import)))
   ((symbol? import)
    (let (file (testing-build-prefixed-import->file
                build
                (symbol->string import)))
      (and file (testing-build-path build file))))
   (else #f)))

;; : (-> Datum String)
(def (testing-build-gxtest-name spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (string? (car spec))) (car spec))
   (else "gxtest")))

;; : (-> Datum Path)
(def (testing-build-gxtest-root spec)
  (cond
   ((string? spec) spec)
   ((and (pair? spec) (pair? (cdr spec))) (cadr spec))
   (else spec)))

;; : (-> TestingBuild Procedure)
(def (testing-build-policy-runner build)
  (lambda (scenario)
    (let (runs (testing-object-ref build 'scenarioRuns []))
      (vector-set! runs 0
                   (cons (testing-scenario-id scenario)
                         (vector-ref runs 0))))
    scenario))

;; : (-> TestingBuild Procedure)
(def (testing-build-dry-gxtest-runner build)
  (lambda (files)
    (let (runs (testing-object-ref build 'gxtestRuns []))
      (vector-set! runs 0 (cons files (vector-ref runs 0))))
    0))

;; : (-> Datum String)
(def (testing-build-write-datum value)
  (call-with-output-string ""
    (lambda (port) (write value port))))

;; : (-> Integer Integer)
(def (testing-build-exit-code status)
  (cond
   ((< status 0) 1)
   ((> status 255) (quotient status 256))
   (else status)))

;; : (-> TestingBuild [String] MaybeString)
(def (testing-build-scope-env build files)
  (let (name (testing-object-ref build 'scopeEnv #f))
    (and name
         (string-append name "=" (testing-build-write-datum files)))))

;; : (-> TestingBuild MaybeString)
(def (testing-build-loadpath-env build)
  (let (loadpath (testing-object-ref build 'loadpath #f))
    (and loadpath
         (string-append "GERBIL_LOADPATH=" loadpath))))

;; : (-> TestingBuild [String] [String])
(def (testing-build-process-env build files)
  (filter values
          [(testing-build-loadpath-env build)
           (testing-build-scope-env build files)]))

;; : (-> TestingBuild [String] [String])
(def (testing-build-gxtest-command build files)
  (let (policy-file (testing-object-ref build 'policyFile #f))
    (append ["env"]
            (testing-build-process-env build files)
            ["gxtest"]
            files
            (if policy-file [policy-file] []))))

;; : (-> TestingBuild Procedure)
(def (testing-build-gxtest-runner build)
  (lambda (files)
    (let (status 0)
      (run-process (testing-build-gxtest-command build files)
                   stdin-redirection: #f
                   stdout-redirection: #f
                   stderr-redirection: #f
                   check-status:
                   (lambda (exit-status _settings)
                     (set! status exit-status)))
      (testing-build-exit-code status))))

;; : (-> TestingBuild String Alist)
(def (testing-build-scenario-metadata build id)
  (let (entry (assoc id (testing-object-ref build 'scenarioMetadata [])))
    (if entry (cdr entry) [])))

;; : (-> TestingBuild String PolicyScenario)
(def (testing-build-policy-scenario build id)
  (make-policy-scenario
   id
   (testing-build-path
    build
    (path-expand id (testing-object-ref build 'scenarioRoot "policy-scenarios")))
   (testing-build-scenario-metadata build id)))

;; : (-> TestingBuild Datum GxTestSuite)
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

;; : (-> TestingBuild MaybeScenarioSuite)
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

;; : (-> List List)
(def (testing-build-filter values)
  (filter identity values))

;; : (-> TestingBuild TestingProject)
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

;; : (-> String Path MaybePath List List MaybeList Alist Path String List Integer Integer Integer Integer MaybeString MaybeString MaybeString TestingBuild)
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
                    import-prefix: (import-prefix #f)
                    batch-size: (batch-size 2)
                    max-selected-files: (max-selected-files 2)
                    max-selected-sources: (max-selected-sources 4)
                    max-selected-outputs: (max-selected-outputs 4)
                    policy-file: (policy-file #f)
                    scope-env: (scope-env #f)
                    loadpath: (loadpath #f)
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
     (importPrefix . ,import-prefix)
     (batchSize . ,batch-size)
     (maxSelectedFiles . ,max-selected-files)
     (maxSelectedSources . ,max-selected-sources)
     (maxSelectedOutputs . ,max-selected-outputs)
     (policyFile . ,policy-file)
     (scopeEnv . ,scope-env)
     (loadpath . ,loadpath)
     (receiptPrefix . ,(or receipt-prefix name))
     (gxtestRuns . ,(vector []))
     (scenarioRuns . ,(vector [])))))

;; : (-> TestingBuild Unit)
(def (testing-build-reset! build)
  (vector-set! (testing-object-ref build 'gxtestRuns) 0 [])
  (vector-set! (testing-object-ref build 'scenarioRuns) 0 []))

;; : (-> TestingBuild List)
(def (testing-build-gxtest-runs build)
  (reverse (vector-ref (testing-object-ref build 'gxtestRuns) 0)))

;; : (-> TestingBuild List)
(def (testing-build-scenario-runs build)
  (reverse (vector-ref (testing-object-ref build 'scenarioRuns) 0)))

;; : (-> TestingBuild List TestingSelection)
(def (testing-build-select build args)
  (testing-select-project (testing-build-project build) args))

;; : (-> TestingBuild List (OrFalse Procedure) TestingReceipt)
(def (testing-build-main build args (run-files #f))
  (testing-run-selection
   (testing-build-select build args)
   (or run-files
       (testing-build-gxtest-runner build))))
