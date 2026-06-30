;;; -*- Gerbil -*-
;;; User-friendly Gerbil testing helpers inspired by poo-flow test entrypoints.

(import :gerbil/gambit
        :benchmark/framework
        (only-in :support/time
                 monotonic-micros
                 duration-micros)
        (only-in :std/srfi/1 iota split-at)
        (only-in :std/sugar cut filter filter-map foldl)
        :testing/model)

(export #t)

;; : (-> Datum List Boolean)
(def (testing-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (testing-member? value (cdr values)))))

;; : (-> Path Path)
(def (testing-normalize-path path)
  (if (and (string? path)
           (testing-string-prefix? "./" path))
    (testing-normalize-path
     (substring path 2 (string-length path)))
    path))

;; : (-> Path Path Boolean)
(def (testing-path=? left right)
  (equal? (testing-normalize-path left)
          (testing-normalize-path right)))

;; : (-> Path (List Path) Boolean)
(def (testing-member-path? path values)
  (cond
   ((null? values) #f)
   ((testing-path=? path (car values)) #t)
   (else (testing-member-path? path (cdr values)))))

;; : (-> Datum Symbol Boolean)
(def (testing-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (testing-form-contains-symbol? (car form) symbol)
        (testing-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

;; : (-> Datum Boolean)
(def (testing-native-gxtest-form? form)
  (or (testing-form-contains-symbol? form 'test-suite)
      (testing-form-contains-symbol? form 'run-tests!)))

;; testing-native-gxtest-file?
;;   : (-> Path Boolean)
;;   | doc m%
;;       `testing-native-gxtest-file?` detects whether a manifest entry already
;;       owns an executable gxtest suite, so expansion stops at that file.
;;
;;       # Examples
;;
;;       ```scheme
;;       (testing-native-gxtest-file? "t/testing-framework-test.ss")
;;       ;; => #t
;;       ```
;;     %
(def (testing-native-gxtest-file? file)
  (and (file-exists? file)
       (call-with-input-file file
         (lambda (port)
           (let loop ()
             (let (form (read port))
               (cond
                ((eof-object? form) #f)
                ((testing-native-gxtest-form? form) #t)
                (else (loop)))))))))

;; : (-> Procedure List List)
(def (testing-filter-map proc values)
  (filter-map proc values))

;; : (-> Procedure List List)
(def (testing-filter proc values)
  (filter proc values))

;; : (-> Procedure List Boolean)
(def (testing-andmap proc values)
  (cond
   ((null? values) #t)
   ((proc (car values)) (testing-andmap proc (cdr values)))
   (else #f)))

;; : (-> Procedure List Boolean)
(def (testing-any? proc values)
  (cond
   ((null? values) #f)
   ((proc (car values)) #t)
   (else (testing-any? proc (cdr values)))))

;; : (-> String String Boolean)
(def (testing-string-prefix? prefix value)
  (let ((prefix-length (string-length prefix))
        (value-length (string-length value)))
    (and (>= value-length prefix-length)
         (string=? (substring value 0 prefix-length) prefix))))

;; : (-> String String Boolean)
(def (testing-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (>= value-length suffix-length)
         (string=? (substring value
                              (- value-length suffix-length)
                              value-length)
                   suffix))))

;; : (-> GxTestSuite Path (List Path))
(def (testing-read-test-file-imports suite file)
  (if (file-exists? file)
    (call-with-input-file file
      (lambda (port)
        (let (form (read port))
          (if (and (pair? form)
                   (eq? (car form) 'import))
            (testing-filter-map
             (testing-suite-import->file suite)
             (cdr form))
            []))))
    []))

;; : (-> GxTestSuite Path (List Path))
(def (testing-expand-manifest-file suite file (seen []))
  (if (testing-member? file seen)
    (list file)
    (if (testing-native-gxtest-file? file)
      (list file)
      (let (imported (testing-read-test-file-imports suite file))
        (if (not (null? imported))
          (apply append
                 (map (lambda (imported-file)
                        (testing-expand-manifest-file
                         suite
                         imported-file
                         (cons file seen)))
                      imported))
          (list file))))))

;; : (-> TestingSuite Path Boolean)
(def (testing-suite-root? suite file)
  (testing-member-path? file (testing-suite-roots suite)))

;; : (-> Path Path Boolean)
(def (testing-arg-under-root? root arg)
  (let ((root (testing-normalize-path root))
        (arg (testing-normalize-path arg)))
    (and (string? root)
         (string? arg)
         (or (equal? root arg)
           (testing-string-prefix?
            (string-append root "/")
            arg)))))

;; : (-> TestingSuite Path Boolean)
(def (testing-arg-under-suite-root? suite arg)
  (testing-any?
   (lambda (root)
     (testing-arg-under-root? root arg))
   (testing-suite-roots suite)))

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-file-in-suite? suite arg)
  (and (testing-string-suffix? ".ss" arg)
       (or (testing-arg-under-suite-root? suite arg)
           (testing-member-path? arg (testing-suite-default-files suite)))))

;; : (-> GxTestSuite (List Path))
(def (testing-suite-default-files suite)
  (let (files (testing-suite-files suite))
    (cond
     ((eq? files 'auto)
      (let (root (testing-suite-default-root suite))
        (if root
          (testing-expand-manifest-file suite root)
          [])))
     ((list? files) files)
     (else []))))

;; : (-> GxTestSuite (List Path) (List Path))
(def (testing-expand-suite-args suite args)
  (cond
   ((null? args)
    (testing-suite-default-files suite))
   ((and (null? (cdr args))
         (testing-suite-root? suite (car args)))
    (testing-expand-manifest-file suite (car args)))
   (else args)))

;; : (-> String Path PolicyScenario)
(def (make-policy-scenario id root (metadata []))
  (list id root metadata))

;; : (-> PolicyScenario String)
(def (policy-scenario-id scenario)
  (list-ref scenario 0))

;; : (-> PolicyScenario Path)
(def (policy-scenario-root scenario)
  (list-ref scenario 1))

;; : (-> PolicyScenario Alist)
(def (policy-scenario-metadata scenario)
  (if (and (pair? scenario)
           (pair? (cdr scenario))
           (pair? (cddr scenario)))
    (car (cddr scenario))
    []))

;; : (-> String Path List MaybeList MaybeInteger List MaybeProcedure ScenarioSuite)
(def (policy-scenario-suite name: (name "policy-scenarios")
                            root: (root "t/scenarios/policy")
                            scenario-ids: (scenario-ids [])
                            scenarios: (scenarios #f)
                            batch-size: (batch-size #f)
                            gates: (gates [])
                            runner: (runner #f))
  (let (scenario-list
        (if scenarios
          scenarios
          (map (lambda (id)
                 (make-policy-scenario id (path-expand id root)))
               scenario-ids)))
    (scenario-suite
     name: name
     roots: (list root)
     scenarios: scenario-list
     batch-size: batch-size
     gates: gates
     runner: runner)))

;; : (-> ScenarioSuite Datum MaybePath)
(def (testing-scenario-root suite scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-root scenario))
   ((string? scenario)
    (let (roots (testing-suite-roots suite))
      (if (null? roots)
        scenario
        (path-expand scenario (car roots)))))
   (else #f)))

;; : (-> Datum String)
(def (testing-scenario-id scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-id scenario))
   ((string? scenario) scenario)
   (else "scenario")))

;; : (-> Datum Alist)
(def (testing-scenario-metadata scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-metadata scenario))
   (else [])))

;; : (-> Datum Symbol Datum)
(def (testing-scenario-metadata-ref scenario key (default #f))
  (let (entry (assq key (testing-scenario-metadata scenario)))
    (if entry (cdr entry) default)))

;; : (-> Datum Alist)
(def (testing-scenario-repair-details scenario)
  (testing-filter-map
   (lambda (key)
     (let (value (testing-scenario-metadata-ref scenario key #f))
       (and value (cons key value))))
   '(downstreamRepairTarget idiom expectedRepair benchmarkPhases nextRepairAction)))

;; testing-declared-scenario-by-id
;;   : (-> ScenarioSuite String MaybePolicyScenario)
;;   | doc m%
;;       `testing-declared-scenario-by-id` resolves a scenario identifier from
;;       the suite declaration before falling back to path-shaped arguments.
;;
;;       # Examples
;;
;;       ```scheme
;;       (testing-declared-scenario-by-id suite "marlin-speed-trap")
;;       ;; => declared-scenario-or-#f
;;       ```
;;     %
(def (testing-declared-scenario-by-id suite id)
  (let loop ((rest (testing-scenario-suite-scenarios suite)))
    (cond
     ((null? rest) #f)
     ((equal? id (testing-scenario-id (car rest))) (car rest))
     (else (loop (cdr rest))))))

;; : (-> ScenarioSuite Datum Datum)
(def (testing-scenario-from-arg suite arg)
  (cond
   ((and (pair? arg)
         (pair? (cdr arg)))
    arg)
   ((string? arg)
    (let (declared (testing-declared-scenario-by-id suite arg))
      (if declared
        declared
        (let ((roots (testing-suite-roots suite)))
          (cond
           ((testing-arg-under-suite-root? suite arg)
            (make-policy-scenario arg arg))
           ((null? roots)
            (make-policy-scenario arg arg))
           (else
            (make-policy-scenario arg (path-expand arg (car roots)))))))))
   (else arg)))

;; : (-> ScenarioSuite (List Datum) (List Datum))
(def (testing-expand-scenario-args suite args)
  (cond
   ((null? args)
    (testing-scenario-suite-scenarios suite))
   ((and (null? (cdr args))
         (testing-suite-root? suite (car args)))
    (testing-scenario-suite-scenarios suite))
   (else
    (map (lambda (arg)
           (testing-scenario-from-arg suite arg))
         args))))

;; : (-> GxTestSuite Path Boolean)
(def (testing-gxtest-suite-arg? suite arg)
  (and (string? arg)
       (or (testing-suite-root? suite arg)
           (testing-arg-under-suite-root? suite arg)
           (testing-gxtest-file-in-suite? suite arg))))

;; : (-> ScenarioSuite Path Boolean)
(def (testing-scenario-suite-arg? suite arg)
  (or (testing-suite-root? suite arg)
      (testing-arg-under-suite-root? suite arg)
      (testing-any?
       (lambda (scenario)
         (equal? arg (testing-scenario-id scenario)))
       (testing-scenario-suite-scenarios suite))))

;; : (-> TestingSuite (List Path) Boolean)
(def (testing-suite-selected? suite args)
  (or (null? args)
      (case (testing-object-kind suite)
        ((gxtest-suite)
         (testing-any?
          (lambda (arg)
            (testing-gxtest-suite-arg? suite arg))
          args))
        ((scenario-suite)
         (testing-any?
          (lambda (arg)
            (testing-scenario-suite-arg? suite arg))
          args))
        (else #f))))

;; : (-> TestingProject (List Path) List)
(def (testing-selected-suites project args)
  (testing-filter
   (lambda (suite)
     (testing-suite-selected? suite args))
   (testing-project-suites project)))

;; : (-> TestingProject (List Path) TestingSelection)
(def (testing-select-project project args)
  (let (suites (testing-selected-suites project args))
    (testing-selection
     project: project
     args: args
     suites: suites
     status: (if (or (null? args)
                     (not (null? suites)))
               'ok
               'failed)
     details: (if (or (null? args)
                      (not (null? suites)))
                []
                `((reason . no-selected-suites)
                  (args . ,args))))))

;; : (-> List Integer (Values List List))
(def (testing-split-batch files batch-size)
  (if (or (null? files)
          (<= batch-size 0))
    (values [] [])
    (split-at files (min batch-size (length files)))))

;; : (-> List Integer List)
(def (testing-batch-head files batch-size)
  (let-values (((batch _rest)
                (testing-split-batch files batch-size)))
    batch))

;; : (-> List Integer List)
(def (testing-batch-tail files batch-size)
  (let-values (((_batch rest)
                (testing-split-batch files batch-size)))
    rest))

;; : (-> Integer Integer Integer)
(def (testing-batch-count file-count batch-size)
  (if (or (<= file-count 0) (<= batch-size 0))
    0
    (quotient (+ file-count batch-size -1) batch-size)))

;; : (-> Integer Integer List List)
(def (testing-batches-step batch-size _ state)
  (let-values (((batch rest)
                (testing-split-batch (car state) batch-size)))
    (list rest (cons batch (cadr state)))))

;; : (-> List Integer (List List))
(def (testing-batches files batch-size)
  (reverse
   (cadr
    (foldl (cut testing-batches-step batch-size <> <>)
           (list files [])
           (iota (testing-batch-count (length files) batch-size))))))

;; : (-> TestingProject TestingSuite List Integer)
(def (testing-effective-batch-size project suite files)
  (let ((suite-size (testing-suite-batch-size suite))
        (project-size (testing-project-batch-size project)))
    (cond
     (suite-size suite-size)
     (project-size project-size)
     ((null? files) 1)
     (else (length files)))))

;; : (-> Integer MaybeInteger Boolean)
(def (testing-under-limit? count limit)
  (or (not limit)
      (<= count limit)))

;; : (-> GxTestSuite List Integer Integer (List Symbol))
(def (testing-gxtest-suite-hot-path-diagnostics suite files selected-sources selected-outputs)
  (append
   (if (testing-under-limit? (length files)
                             (testing-suite-max-selected-files suite))
     []
     '(too-many-selected-files))
   (if (testing-under-limit? selected-sources
                             (testing-suite-max-selected-sources suite))
     []
     '(too-many-selected-sources))
   (if (testing-under-limit? selected-outputs
                             (testing-suite-max-selected-outputs suite))
     []
     '(too-many-selected-outputs))))

;; : (-> GxTestSuite List Integer Integer Boolean)
(def (testing-gxtest-suite-hot-path? suite files selected-sources selected-outputs)
  (null? (testing-gxtest-suite-hot-path-diagnostics
          suite
          files
          selected-sources
          selected-outputs)))

;; : (-> GxTestSuite List Integer Integer TestingReceipt)
(def (testing-gxtest-suite-hot-path-receipt suite files selected-sources selected-outputs)
  (let* ((diagnostics
          (testing-gxtest-suite-hot-path-diagnostics
           suite
           files
           selected-sources
           selected-outputs))
         (status (if (null? diagnostics) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-hot-path-gate
     status: status
     suite: (testing-suite-name suite)
     files: files
     details: `((selectedFiles . ,(length files))
                (maxSelectedFiles . ,(testing-suite-max-selected-files suite))
                (selectedSources . ,selected-sources)
                (maxSelectedSources . ,(testing-suite-max-selected-sources suite))
                (selectedOutputs . ,selected-outputs)
                (maxSelectedOutputs . ,(testing-suite-max-selected-outputs suite))
                (diagnostics . ,diagnostics)))))

;; : (-> Symbol Symbol MaybeString List List TestingReceipt)
(def (testing-phase-receipt phase status: (status 'ok)
                            suite: (suite #f)
                            files: (files [])
                            details: (details []))
  (testing-receipt
   kind: 'testing-phase
   status: status
   suite: suite
   files: files
   details: (cons (cons 'phase phase) details)))

;; : (-> TestingSuite List (List TestingReceipt))
(def (testing-gate-phase-receipts suite files)
  (map (lambda (gate)
         (testing-phase-receipt
          'benchmark-assert
          suite: (testing-suite-name suite)
          files: files
          details: `((gate . ,(testing-gate-name gate))
                     (scope . ,(testing-gate-scope gate)))))
       (testing-suite-gates suite)))

;; : (-> TestingSuite List Procedure TestingReceipt)
(def (testing-run-batch suite files run-files)
  (let* ((started-at (monotonic-micros))
         (status (run-files files))
         (elapsed-micros (duration-micros started-at (monotonic-micros)))
         (receipt-status (if (= status 0) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-batch
     status: receipt-status
     suite: (testing-suite-name suite)
     files: files
     elapsed-micros: elapsed-micros)))

;; : (-> TestingProject GxTestSuite List Procedure TestingReceipt)
(def (testing-run-gxtest-suite project suite args run-files)
  (let* ((files (testing-expand-suite-args suite args))
         (batch-size (testing-effective-batch-size project suite files))
         (receipts
          (map (lambda (batch)
                 (testing-run-batch suite batch run-files))
               (testing-batches files batch-size)))
         (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-suite
     status: status
     suite: (testing-suite-name suite)
     files: files
     children: receipts
     details: `((phases
                 .
                 ,(append
                   (list
                    (testing-phase-receipt
                     'expand-manifest
                     suite: (testing-suite-name suite)
                     files: files
                     details: `((args . ,args)))
                    (testing-phase-receipt
                     'delegate-gxtest
                     status: status
                     suite: (testing-suite-name suite)
                     files: files
                     details: `((batches . ,(length receipts)))))
                   (testing-gate-phase-receipts suite files)))))))

;; : (-> ScenarioSuite Datum TestingReceipt)
(def (testing-run-scenario suite scenario)
  (let* ((started-at (monotonic-micros))
         (runner (testing-scenario-suite-runner suite))
         (_ (if runner (runner scenario) scenario))
         (elapsed-micros (duration-micros started-at (monotonic-micros))))
    (testing-receipt
     kind: 'policy-scenario
     status: 'ok
     suite: (testing-suite-name suite)
     files: (list (testing-scenario-root suite scenario))
     elapsed-micros: elapsed-micros
     details: (append
               `((id . ,(testing-scenario-id scenario)))
               (testing-scenario-repair-details scenario)))))

;; : (-> ScenarioSuite List TestingReceipt)
(def (testing-run-scenario-batch suite scenarios)
  (let* ((started-at (monotonic-micros))
         (receipts
          (map (lambda (scenario)
                 (testing-run-scenario suite scenario))
               scenarios))
         (files (testing-filter-map
                 (lambda (scenario)
                   (testing-scenario-root suite scenario))
                 scenarios))
         (elapsed-micros (duration-micros started-at (monotonic-micros)))
         (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
    (testing-receipt
     kind: 'policy-scenario-batch
     status: status
     suite: (testing-suite-name suite)
     files: files
     elapsed-micros: elapsed-micros
     children: receipts)))

;; : (-> TestingProject ScenarioSuite List TestingReceipt)
(def (testing-run-scenario-suite project suite args)
  (let* ((scenarios (testing-expand-scenario-args suite args))
         (files (testing-filter-map
                 (lambda (scenario)
                   (testing-scenario-root suite scenario))
                 scenarios))
         (batch-size (testing-effective-batch-size project suite scenarios))
         (receipts
          (map (lambda (batch)
                 (testing-run-scenario-batch suite batch))
               (testing-batches scenarios batch-size)))
         (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
    (testing-receipt
     kind: 'scenario-suite
     status: status
     suite: (testing-suite-name suite)
     files: files
     children: receipts
     details: `((phases
                 .
                 ,(append
                   (list
                    (testing-phase-receipt
                     'delegate-policy
                     status: status
                     suite: (testing-suite-name suite)
                     files: files
                     details: `((scenarios . ,(map testing-scenario-id scenarios))
                                (repairGuidance
                                 .
                                 ,(testing-filter-map
                                   (lambda (scenario)
                                     (let (details
                                           (testing-scenario-repair-details scenario))
                                       (and (not (null? details))
                                            (cons (cons 'id
                                                        (testing-scenario-id scenario))
                                                  details))))
                                   scenarios)))))
                   (testing-gate-phase-receipts
                    suite
                    files)))))))

;; : (-> TestingProject TestingSuite List Procedure TestingReceipt)
(def (testing-run-suite project suite args run-files)
  (case (testing-object-kind suite)
    ((gxtest-suite)
     (testing-run-gxtest-suite project suite args run-files))
    ((scenario-suite)
     (testing-run-scenario-suite project suite args))
    (else
     (error "unknown testing suite kind" (testing-object-kind suite)))))

;; : (-> TestingSelection Procedure TestingReceipt)
(def (testing-run-selection selection run-files)
  (let ((project (testing-selection-project selection))
        (args (testing-selection-args selection))
        (suites (testing-selection-suites selection)))
    (if (null? suites)
      (testing-receipt
       kind: 'testing-project
       status: (testing-selection-status selection)
       children: []
       details: (cons
                 (cons 'phases
                       (list
                        (testing-phase-receipt
                         'select-scope
                         status: (testing-selection-status selection)
                         details: (testing-selection-details selection))))
                 (testing-selection-details selection)))
      (let* ((receipts
              (map (lambda (suite)
                     (testing-run-suite project suite args run-files))
                   suites))
             (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
        (testing-receipt
         kind: 'testing-project
         status: status
         children: receipts
         details: `((phases
                     .
                     ,(list
                       (testing-phase-receipt
                        'select-scope
                        status: (testing-selection-status selection)
                        details: `((args . ,args)
                                   (suites . ,(map testing-suite-name suites))))))))))))

;; : (-> TestingProject List Procedure TestingReceipt)
(def (testing-run-project project args run-files)
  (testing-run-selection
   (testing-select-project project args)
   run-files))

;; : (-> PerformanceGate Boolean)
(def (testing-performance-gate-valid? gate)
  (let (root (testing-performance-gate-contract-root gate))
    (and root
         (benchmark-contract-valid/root? root))))
