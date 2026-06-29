;;; -*- Gerbil -*-
;;; User-friendly Gerbil testing helpers inspired by poo-flow test entrypoints.

(import :gerbil/gambit
        :benchmark/framework
        :testing/model)

(export #t)

(def (testing-member? value values)
  (cond
   ((null? values) #f)
   ((equal? value (car values)) #t)
   (else (testing-member? value (cdr values)))))

(def (testing-form-contains-symbol? form symbol)
  (cond
   ((eq? form symbol) #t)
   ((pair? form)
    (or (testing-form-contains-symbol? (car form) symbol)
        (testing-form-contains-symbol? (cdr form) symbol)))
   (else #f)))

(def (testing-native-gxtest-form? form)
  (or (testing-form-contains-symbol? form 'test-suite)
      (testing-form-contains-symbol? form 'run-tests!)))

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

(def (testing-filter-map proc values)
  (let loop ((rest values) (out []))
    (cond
     ((null? rest) (reverse out))
     (else
      (let (value (proc (car rest)))
        (loop (cdr rest)
              (if value (cons value out) out)))))))

(def (testing-filter proc values)
  (let loop ((rest values) (out []))
    (cond
     ((null? rest) (reverse out))
     ((proc (car rest)) (loop (cdr rest) (cons (car rest) out)))
     (else (loop (cdr rest) out)))))

(def (testing-andmap proc values)
  (cond
   ((null? values) #t)
   ((proc (car values)) (testing-andmap proc (cdr values)))
   (else #f)))

(def (testing-any? proc values)
  (cond
   ((null? values) #f)
   ((proc (car values)) #t)
   (else (testing-any? proc (cdr values)))))

(def (testing-string-prefix? prefix value)
  (let ((prefix-length (string-length prefix))
        (value-length (string-length value)))
    (and (>= value-length prefix-length)
         (string=? (substring value 0 prefix-length) prefix))))

(def (testing-string-suffix? suffix value)
  (let ((suffix-length (string-length suffix))
        (value-length (string-length value)))
    (and (>= value-length suffix-length)
         (string=? (substring value
                              (- value-length suffix-length)
                              value-length)
                   suffix))))

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

(def (testing-suite-root? suite file)
  (testing-member? file (testing-suite-roots suite)))

(def (testing-arg-under-root? root arg)
  (and (string? root)
       (string? arg)
       (or (equal? root arg)
           (testing-string-prefix?
            (string-append root "/")
            arg))))

(def (testing-arg-under-suite-root? suite arg)
  (testing-any?
   (lambda (root)
     (testing-arg-under-root? root arg))
   (testing-suite-roots suite)))

(def (testing-gxtest-file-in-suite? suite arg)
  (and (testing-string-suffix? ".ss" arg)
       (or (testing-arg-under-suite-root? suite arg)
           (testing-member? arg (testing-suite-default-files suite)))))

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

(def (testing-expand-suite-args suite args)
  (cond
   ((null? args)
    (testing-suite-default-files suite))
   ((and (null? (cdr args))
         (testing-suite-root? suite (car args)))
    (testing-expand-manifest-file suite (car args)))
   (else args)))

(def (make-policy-scenario id root)
  (list id root))

(def (policy-scenario-id scenario)
  (list-ref scenario 0))

(def (policy-scenario-root scenario)
  (list-ref scenario 1))

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

(def (testing-scenario-id scenario)
  (cond
   ((and (pair? scenario)
         (pair? (cdr scenario)))
    (policy-scenario-id scenario))
   ((string? scenario) scenario)
   (else "scenario")))

(def (testing-scenario-from-arg suite arg)
  (cond
   ((and (pair? arg)
         (pair? (cdr arg)))
    arg)
   ((string? arg)
    (let ((roots (testing-suite-roots suite)))
      (cond
       ((testing-arg-under-suite-root? suite arg)
        (make-policy-scenario arg arg))
       ((null? roots)
        (make-policy-scenario arg arg))
       (else
        (make-policy-scenario arg (path-expand arg (car roots)))))))
   (else arg)))

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

(def (testing-gxtest-suite-arg? suite arg)
  (and (string? arg)
       (or (testing-suite-root? suite arg)
           (testing-arg-under-suite-root? suite arg)
           (testing-gxtest-file-in-suite? suite arg))))

(def (testing-scenario-suite-arg? suite arg)
  (or (testing-suite-root? suite arg)
      (testing-arg-under-suite-root? suite arg)
      (testing-any?
       (lambda (scenario)
         (equal? arg (testing-scenario-id scenario)))
       (testing-scenario-suite-scenarios suite))))

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

(def (testing-selected-suites project args)
  (testing-filter
   (lambda (suite)
     (testing-suite-selected? suite args))
   (testing-project-suites project)))

(def (testing-batch-head files batch-size)
  (if (or (null? files)
          (<= batch-size 0))
    []
    (let loop ((rest files) (remaining batch-size) (out []))
      (cond
       ((or (null? rest) (= remaining 0))
        (reverse out))
       (else
        (loop (cdr rest)
              (- remaining 1)
              (cons (car rest) out)))))))

(def (testing-batch-tail files batch-size)
  (if (or (null? files)
          (<= batch-size 0))
    []
    (let loop ((rest files) (remaining batch-size))
      (cond
       ((null? rest) [])
       ((= remaining 0) rest)
       (else (loop (cdr rest) (- remaining 1)))))))

(def (testing-batches files batch-size)
  (let loop ((rest files) (out []))
    (if (null? rest)
      (reverse out)
      (let (batch (testing-batch-head rest batch-size))
        (loop (testing-batch-tail rest batch-size)
              (cons batch out))))))

(def (testing-effective-batch-size project suite files)
  (let ((suite-size (testing-suite-batch-size suite))
        (project-size (testing-project-batch-size project)))
    (cond
     (suite-size suite-size)
     (project-size project-size)
     ((null? files) 1)
     (else (length files)))))

(def (testing-under-limit? count limit)
  (or (not limit)
      (<= count limit)))

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

(def (testing-gxtest-suite-hot-path? suite files selected-sources selected-outputs)
  (null? (testing-gxtest-suite-hot-path-diagnostics
          suite
          files
          selected-sources
          selected-outputs)))

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

(def (testing-run-batch suite files run-files)
  (let* ((started-at (time->seconds (current-time)))
         (status (run-files files))
         (elapsed (- (time->seconds (current-time)) started-at))
         (receipt-status (if (= status 0) 'ok 'failed)))
    (testing-receipt
     kind: 'gxtest-batch
     status: receipt-status
     suite: (testing-suite-name suite)
     files: files
     elapsed-seconds: elapsed)))

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
     children: receipts)))

(def (testing-run-scenario suite scenario)
  (let* ((started-at (time->seconds (current-time)))
         (runner (testing-scenario-suite-runner suite))
         (_ (if runner (runner scenario) scenario))
         (elapsed (- (time->seconds (current-time)) started-at)))
    (testing-receipt
     kind: 'policy-scenario
     status: 'ok
     suite: (testing-suite-name suite)
     files: (list (testing-scenario-root suite scenario))
     elapsed-seconds: elapsed
     details: `((id . ,(testing-scenario-id scenario))))))

(def (testing-run-scenario-batch suite scenarios)
  (let* ((started-at (time->seconds (current-time)))
         (receipts
          (map (lambda (scenario)
                 (testing-run-scenario suite scenario))
               scenarios))
         (elapsed (- (time->seconds (current-time)) started-at))
         (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
    (testing-receipt
     kind: 'policy-scenario-batch
     status: status
     suite: (testing-suite-name suite)
     files: (testing-filter-map
             (lambda (scenario)
               (testing-scenario-root suite scenario))
             scenarios)
     elapsed-seconds: elapsed
     children: receipts)))

(def (testing-run-scenario-suite project suite args)
  (let* ((scenarios (testing-expand-scenario-args suite args))
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
     files: (testing-filter-map
             (lambda (scenario)
               (testing-scenario-root suite scenario))
             scenarios)
     children: receipts)))

(def (testing-run-suite project suite args run-files)
  (case (testing-object-kind suite)
    ((gxtest-suite)
     (testing-run-gxtest-suite project suite args run-files))
    ((scenario-suite)
     (testing-run-scenario-suite project suite args))
    (else
     (error "unknown testing suite kind" (testing-object-kind suite)))))

(def (testing-run-project project args run-files)
  (let ((suites (testing-selected-suites project args)))
    (if (null? suites)
      (testing-receipt
       kind: 'testing-project
       status: (if (null? args) 'ok 'failed)
       children: []
       details: (if (null? args)
                  []
                  `((reason . no-selected-suites)
                    (args . ,args))))
      (let* ((receipts
              (map (lambda (suite)
                     (testing-run-suite project suite args run-files))
                   suites))
             (status (if (testing-andmap testing-receipt-ok? receipts) 'ok 'failed)))
        (testing-receipt
         kind: 'testing-project
         status: status
         children: receipts)))))

(def (testing-performance-gate-valid? gate)
  (let (root (testing-performance-gate-contract-root gate))
    (and root
         (benchmark-contract-valid/root? root))))
