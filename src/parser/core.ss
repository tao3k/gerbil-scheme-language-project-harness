;;; -*- Gerbil -*-
;;; Parser-owned facts for the Gerbil Scheme project harness.

(import :gerbil/expander
        :gerbil/gambit
        :parser/comment-quality
        :parser/control-flow
        :parser/dependency-adapter-quality
        :parser/exports
        :parser/function-quality
        :parser/higher-order
        :parser/model
        :parser/package
        :parser/poo
        :parser/quality-shape
        :parser/selectors
        :parser/source-scope
        :parser/support
        :parser/syntax
        :parser/typed-contract
        :support/time
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports open-output-string read-file-lines)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 iota take)
        (only-in :std/srfi/13
                 string-contains
                 string-join
                 string-prefix?
                 string-trim))

(export +source-extensions+
        +config-files+
        +ignored-dirs+
        collect-project
        collect-project/profile
        collect-source-scope
        collect-project-package-only
        collect-source-files
        gerbil-source-path?
        parse-source-file
        project-definitions
        project-calls
        project-macro-family-facts
        project-predicate-family-facts
        project-field-access-pattern-facts
        project-projection-burst-facts
        project-boolean-condition-facts
        project-loop-driver-facts
        project-dependency-adapter-quality-facts
        project-function-quality-profiles
        project-typed-contract-facts
        project-comment-quality-facts
        find-owner
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        definition-selector
        call-fact-callee
        call-fact-arity
        call-fact-path
        call-fact-start
        call-fact-end
        call-fact-arguments
        call-fact-argument-types
        call-fact-caller
        call-fact-selector
        module-import-fact-module
        module-import-fact-phase
        module-import-fact-modifier
        module-import-fact-alias
        module-import-fact-symbols
        module-import-fact-path
        module-import-fact-start
        module-import-fact-end
        module-import-fact-selector
        module-export-fact-name
        module-export-fact-modifier
        module-export-fact-alias
        module-export-fact-module
        module-export-fact-symbols
        module-export-fact-path
        module-export-fact-start
        module-export-fact-end
        module-export-fact-selector
        macro-fact-name
        macro-fact-kind
        macro-fact-path
        macro-fact-start
        macro-fact-end
        macro-fact-transformer
        macro-fact-phase
        macro-fact-pattern-count
        macro-fact-hygienic
        macro-fact-quality-facets
        macro-fact-selector
        macro-family-fact-name
        macro-family-fact-kind
        macro-family-fact-path
        macro-family-fact-start
        macro-family-fact-end
        macro-family-fact-role
        macro-family-fact-prefix
        macro-family-fact-macro-names
        macro-family-fact-macro-count
        macro-family-fact-transformer
        macro-family-fact-quality-facets
        macro-family-fact-advice
        macro-family-fact-selector
        binding-fact-name
        binding-fact-kind
        binding-fact-path
        binding-fact-start
        binding-fact-end
        binding-fact-scope
        binding-fact-value-type
        binding-fact-selector
        poo-form-fact-name
        poo-form-fact-kind
        poo-form-fact-path
        poo-form-fact-start
        poo-form-fact-end
        poo-form-fact-role
        poo-form-fact-generic
        poo-form-fact-receiver
        poo-form-fact-receiver-type
        poo-form-fact-supers
        poo-form-fact-slots
        poo-form-fact-options
        poo-form-fact-specializers
        poo-form-fact-specializer-types
        poo-form-fact-selector
        higher-order-fact-name
        higher-order-fact-kind
        higher-order-fact-path
        higher-order-fact-start
        higher-order-fact-end
        higher-order-fact-role
        higher-order-fact-operand-count
        higher-order-fact-arities
        higher-order-fact-formals
        higher-order-fact-caller
        higher-order-quality-facets
        higher-order-fact-selector
        control-flow-fact-name
        control-flow-fact-kind
        control-flow-fact-path
        control-flow-fact-start
        control-flow-fact-end
        control-flow-fact-role
        control-flow-fact-caller
        control-flow-fact-binding-count
        control-flow-fact-body-form-count
        control-flow-quality-facets
        control-flow-fact-selector
        predicate-family-fact-name
        predicate-family-fact-kind
        predicate-family-fact-path
        predicate-family-fact-start
        predicate-family-fact-end
        predicate-family-fact-role
        predicate-family-fact-subject
        predicate-family-fact-predicate-names
        predicate-family-fact-predicate-count
        predicate-family-fact-field-keys
        predicate-family-fact-repeated-callees
        predicate-family-fact-condition-count
        predicate-family-fact-quality-facets
        predicate-family-fact-advice
        predicate-family-fact-selector
        field-access-pattern-fact-name
        field-access-pattern-fact-kind
        field-access-pattern-fact-path
        field-access-pattern-fact-start
        field-access-pattern-fact-end
        field-access-pattern-fact-role
        field-access-pattern-fact-field-key
        field-access-pattern-fact-callers
        field-access-pattern-fact-access-count
        field-access-pattern-fact-accessors
        field-access-pattern-fact-quality-facets
        field-access-pattern-fact-advice
        field-access-pattern-fact-selector
        projection-burst-fact-name
        projection-burst-fact-kind
        projection-burst-fact-path
        projection-burst-fact-start
        projection-burst-fact-end
        projection-burst-fact-role
        projection-burst-fact-caller
        projection-burst-fact-field-keys
        projection-burst-fact-access-count
        projection-burst-fact-accessor-count
        projection-burst-fact-emitter-count
        projection-burst-fact-accessors
        projection-burst-fact-emitters
        projection-burst-fact-quality-facets
        projection-burst-fact-advice
        projection-burst-fact-selector
        boolean-condition-fact-name
        boolean-condition-fact-kind
        boolean-condition-fact-path
        boolean-condition-fact-start
        boolean-condition-fact-end
        boolean-condition-fact-role
        boolean-condition-fact-caller
        boolean-condition-fact-formals
        boolean-condition-fact-condition-callees
        boolean-condition-fact-field-keys
        boolean-condition-fact-condition-count
        boolean-condition-fact-quality-facets
        boolean-condition-fact-advice
        boolean-condition-fact-selector
        loop-driver-fact-name
        loop-driver-fact-kind
        loop-driver-fact-path
        loop-driver-fact-start
        loop-driver-fact-end
        loop-driver-fact-role
        loop-driver-fact-caller
        loop-driver-fact-driver-kind
        loop-driver-fact-binding-count
        loop-driver-fact-body-form-count
        loop-driver-fact-quality-facets
        loop-driver-fact-advice
        loop-driver-fact-selector
        dependency-adapter-quality-fact-name
        dependency-adapter-quality-fact-kind
        dependency-adapter-quality-fact-path
        dependency-adapter-quality-fact-start
        dependency-adapter-quality-fact-end
        dependency-adapter-quality-fact-role
        dependency-adapter-quality-fact-dependency
        dependency-adapter-quality-fact-imports
        dependency-adapter-quality-fact-imported-symbols
        dependency-adapter-quality-fact-used-symbols
        dependency-adapter-quality-fact-protocol-refs
        dependency-adapter-quality-fact-slots
        dependency-adapter-quality-fact-derived-capabilities
        dependency-adapter-quality-fact-manual-object-encoding-risk
        dependency-adapter-quality-fact-generic-contract-witness-kind
        dependency-adapter-quality-fact-quality
        dependency-adapter-quality-fact-quality-facets
        dependency-adapter-quality-fact-missing-evidence
        dependency-adapter-quality-fact-advice
        dependency-adapter-quality-fact-selector
        function-quality-profile-name
        function-quality-profile-kind
        function-quality-profile-path
        function-quality-profile-start
        function-quality-profile-end
        function-quality-profile-formals
        function-quality-profile-arity
        function-quality-profile-role
        function-quality-profile-exported
        function-quality-profile-typed-contract-quality
        function-quality-profile-comment-quality
        function-quality-profile-control-flow-roles
        function-quality-profile-higher-order-roles
        function-quality-profile-predicate-family-refs
        function-quality-profile-field-access-pattern-refs
        function-quality-profile-loop-driver-refs
        function-quality-profile-macro-refs
        function-quality-profile-poo-protocol-refs
        function-quality-profile-quality-facets
        function-quality-profile-preservation-reasons
        function-quality-profile-suggested-repair-class
        function-quality-profile-parser-confidence
        function-quality-profile-advice
        function-quality-profile-selector
        typed-contract-fact-definition-name
        typed-contract-fact-definition-kind
        typed-contract-fact-definition-formals
        typed-contract-fact-definition-arity
        typed-contract-fact-path
        typed-contract-fact-definition-start
        typed-contract-fact-definition-end
        typed-contract-fact-comment-start
        typed-contract-fact-comment-end
        typed-contract-fact-contract
        typed-contract-fact-contract-output
        typed-contract-fact-contract-inputs
        typed-contract-fact-contract-input-count
        typed-contract-fact-arity-alignment
        typed-contract-fact-tokens
        typed-contract-fact-arrow-count
        typed-contract-fact-group-count
        typed-contract-fact-quality
        typed-contract-fact-reasons
        typed-contract-fact-quality-facets
        typed-contract-fact-repair-evidence
        typed-contract-fact-typed-comment
        typed-contract-fact-selector
        comment-quality-fact-target-kind
        comment-quality-fact-target-name
        comment-quality-fact-path
        comment-quality-fact-target-start
        comment-quality-fact-target-end
        comment-quality-fact-comment-start
        comment-quality-fact-comment-end
        comment-quality-fact-comment-lines
        comment-quality-fact-comment-kind
        comment-quality-fact-quality
        comment-quality-fact-reasons
        comment-quality-fact-required
        comment-quality-fact-context
        comment-quality-fact-evidence
        comment-quality-fact-selector
        top-form-kind
        top-form-head
        top-form-path
        top-form-start
        top-form-end
        top-form-selector
        declarative-top-form?
        source-file-path
        source-file-line-count
        source-file-package
        source-file-prelude
        source-file-namespace
        source-file-imports
        source-file-exports
        source-file-includes
        source-file-definitions
        source-file-calls
        source-file-forms
        source-file-module-imports
        source-file-module-exports
        source-file-macros
        source-file-macro-family-facts
        source-file-bindings
        source-file-poo-forms
        source-file-higher-order-forms
        source-file-control-flow-forms
        source-file-predicate-family-facts
        source-file-field-access-pattern-facts
        source-file-projection-burst-facts
        source-file-boolean-condition-facts
        source-file-loop-driver-facts
        source-file-dependency-adapter-quality-facts
        source-file-function-quality-profiles
        source-file-typed-contract-facts
        source-file-comment-quality-facts
        source-file-parse-error
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        project-package-source-scope-policy
        project-package-agent-policy
        test-directory-policy-allowed-directories
        test-directory-policy-explanation
        source-scope-policy-roots
        source-scope-policy-runtime-roots
        source-scope-policy-exclude-directories
        source-scope-policy-explanation
        agent-policy-disabled-rules
        agent-policy-explanation
        project-index-root
        project-index-files
        project-index-package)
;; profile-row
;;   : (-> String Integer HashTable)
;;   | doc m%
;;       `profile-row name duration-ms` creates one JSON-ready timing row for
;;       a named parser phase.
;;       # Examples
;;       ```scheme
;;       (hash-get (profile-row "parse" 12) 'durationMs)
;;       ;; => 12
;;       ```
;;     %
(def (profile-row name duration-ms)
  (hash (name name)
        (durationMs duration-ms)))

;; timed-profile-value
;;   : (-> String Procedure Vector)
;;   | doc m%
;;       `timed-profile-value name thunk` returns the thunk value together with
;;       a timing row for the named phase.
;;     %
(def (timed-profile-value name thunk)
  (let (start (monotonic-ms))
    (let (value (thunk))
      (vector value
              (profile-row name (duration-ms start (monotonic-ms)))))))

;;; Profile ranking boundary: timing rows are JSON-facing hash packets, so the
;;; comparator uses only `durationMs` and leaves later row fields out of the
;;; ordering contract.
;; slowest-profile-rows
;;   : (-> (List HashTable) Integer (List HashTable))
;;   | doc m%
;;       `slowest-profile-rows rows limit` returns the highest-duration rows
;;       while preserving the row packet shape.
;;     %
(def (slowest-profile-rows rows limit)
  (let* ((ordered (sort rows
                        (lambda (left right)
                          (> (hash-get left 'durationMs)
                             (hash-get right 'durationMs)))))
         (count (min limit (length ordered))))
    (take ordered count)))

;;; Environment boundary: optional tuning variables are configuration hints, so
;;; missing or unreadable environment state collapses to `#f` instead of
;;; turning parser startup into a runtime failure.
;; optional-environment-variable
;;   : (-> String (Or String False))
;;   | doc m%
;;       `optional-environment-variable name` returns an environment value when
;;       available and `#f` when the lookup is unavailable.
;;     %
(def (optional-environment-variable name)
  (with-catch
    (lambda (_) #f)
    (lambda () (getenv name))))

;; collect-project-worker-count
;;   : (-> Integer Integer)
;;   | doc m%
;;       `collect-project-worker-count file-count` caps parser worker count by
;;       file count, configured `GSLPH_COLLECT_CORES`, and host CPU count.
;;     %
(def (collect-project-worker-count file-count)
  (let* ((raw (optional-environment-variable "GSLPH_COLLECT_CORES"))
         (configured (and raw (string->number raw)))
         (cores (if (and configured
                         (integer? configured)
                         (> configured 0))
                  configured
                  (##cpu-count))))
    (max 1 (min file-count cores))))

;;; Parallel parse boundary: the foreground thread owns scheduling and result
;;; vectors. Parser workers are bounded green threads that only parse one file
;;; and report completion through the foreground mailbox.
;; parse-source-files/concurrent
;;   : (-> String (List String) Boolean (Or Vector (List SourceFile)))
;;   | doc m%
;;       `parse-source-files/concurrent root files profile?` parses files
;;       through bounded green-thread workers and optionally returns profile
;;       rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (parse-source-files/concurrent "." ["build.ss"] #f)
;;       ;; => source files in input order
;;       ```
;;     %
(def (parse-source-files/concurrent root files profile?)
  (let* ((file-count (length files))
         (worker-count (collect-project-worker-count file-count))
         (file-vector (list->vector files))
         (source-vector (make-vector file-count #f))
         (row-vector (and profile? (make-vector file-count #f)))
         (foreground-thread (current-thread))
         (next-index 0)
         (active-workers 0)
         (completed 0)
         (start (monotonic-ms)))
    ;; : (-> String Integer SourceFile HashTable)
    (def (parse-profile-row path elapsed-ms source-file stage-rows)
      (let (row
            (hash (path path)
                  (durationMs elapsed-ms)
                  (lineCount
                   (source-file-line-count source-file))
                  (definitions
                   (length
                    (source-file-definitions source-file)))
                  (calls
                   (length
                    (source-file-calls source-file)))))
        (when stage-rows
          (hash-put! row 'phases stage-rows))
        row))
    ;; : (-> Integer Void)
    (def (spawn-parse-worker! index)
      (let (path (vector-ref file-vector index))
        (set! active-workers (+ active-workers 1))
        (spawn/name
         [worker: path]
         (lambda ()
           (with-catch
             (lambda (exn)
               (thread-send foreground-thread
                            (vector 'error
                                    (current-thread)
                                    index
                                    exn)))
             (lambda ()
               (let* ((file-start (monotonic-ms))
                      (parse-result
                       (if profile?
                         (parse-source-file/profile root path)
                         (parse-source-file root path)))
                      (source-file
                       (if profile?
                         (vector-ref parse-result 0)
                         parse-result))
                      (stage-rows
                       (and profile? (vector-ref parse-result 1)))
                      (elapsed-ms
                       (duration-ms file-start (monotonic-ms))))
                 (thread-send foreground-thread
                              (vector 'ok
                                      (current-thread)
                                      index
                                      source-file
                                      elapsed-ms
                                      stage-rows)))))))))
    ;; : (-> Boolean)
    (def (spawn-next-worker!)
      (and (< next-index file-count)
           (let (index next-index)
             (set! next-index (+ next-index 1))
             (spawn-parse-worker! index)
             #t)))
    ;; : (-> Void)
    (def (seed-workers!)
      (let loop ((slot 0))
        (when (and (< slot worker-count)
                   (spawn-next-worker!))
          (loop (+ slot 1)))))
    ;; : (-> Void)
    (def (receive-worker!)
      (let (message (thread-receive))
        (unless (vector? message)
          (error "unexpected parse worker message" message))
        (let ((status (vector-ref message 0))
              (worker-thread (vector-ref message 1))
              (index (vector-ref message 2)))
          (thread-join! worker-thread)
          (set! active-workers (- active-workers 1))
          (case status
            ((ok)
             (let ((source-file (vector-ref message 3))
                   (elapsed-ms (vector-ref message 4))
                   (stage-rows (vector-ref message 5))
                   (path (vector-ref file-vector index)))
               (vector-set! source-vector index source-file)
               (when profile?
                 (vector-set! row-vector
                              index
                              (parse-profile-row path
                                                 elapsed-ms
                                                 source-file
                                                 stage-rows)))
               (set! completed (+ completed 1))))
            ((error)
             (raise (vector-ref message 3)))
            (else
             (error "unexpected parse worker status" status))))))
    (seed-workers!)
    (let loop ()
      (when (> active-workers 0)
        (receive-worker!)
        (spawn-next-worker!)
        (loop)))
    (when (not (= completed file-count))
      (error "parse worker completion mismatch" completed file-count))
    (let* ((source-files (vector->list source-vector))
           (rows (and profile? (vector->list row-vector)))
           (parse-phase
            (profile-row "parse-source-files"
                         (duration-ms start (monotonic-ms)))))
      (hash-put! parse-phase 'workerCount worker-count)
      (hash-put! parse-phase 'parallel (> worker-count 1))
      (hash-put! parse-phase 'scheduler "green-thread-mailbox")
      (hash-put! parse-phase 'sharedState "foreground-owned")
      (hash-put! parse-phase 'backpressure "bounded-active-workers")
      (if profile?
        (vector source-files
                parse-phase
                (slowest-profile-rows rows 10))
        source-files))))

;; parse-source-files
;;   : (-> String (List String) (List SourceFile))
;;   | doc m%
;;       `parse-source-files root files` parses files concurrently without
;;       profile telemetry.
;;     %
(def (parse-source-files root files)
  (parse-source-files/concurrent root files #f))

;; parse-source-files/profile
;;   : (-> String (List String) Vector)
;;   | doc m%
;;       `parse-source-files/profile root files` parses files concurrently and
;;       returns parsed sources plus aggregate and slowest-file profile rows.
;;     %
(def (parse-source-files/profile root files)
  (parse-source-files/concurrent root files #t))

;;; Project collection boundary: source discovery is sorted once before the
;;; `map`, and `cut` threads the normalized root into every file parser call.
;; collect-project
;;   : (-> String ProjectIndex)
;;   | doc m%
;;       `collect-project root` reads package metadata, discovers source files,
;;       and returns a fully parsed project index rooted at `root`.
;;       # Examples
;;       ```scheme
;;       (project-index-root (collect-project "."))
;;       ;; => "."
;;       ```
;;     %
(def (collect-project root)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (sort (collect-source-files root package) string<?)))
    (make-project-index root
                        (parse-source-files root files)
                        package)))

;;; Profile packet boundary: each timed thunk owns exactly one phase, so the
;;; final packet can report phase latency without changing the ProjectIndex
;;; construction path.
;; collect-project/profile
;;   : (-> String HashTable)
;;   | doc m%
;;       `collect-project/profile root` returns a parsed index plus profile
;;       telemetry for package, source-scope, and parse phases.
;;     %
(def (collect-project/profile root)
  (let* ((root (path-normalize root))
         (total-start (monotonic-ms))
         (package-result
          (timed-profile-value
           "read-project-package"
           (lambda () (read-project-package root))))
         (package (vector-ref package-result 0))
         (package-phase (vector-ref package-result 1))
         (files-result
          (timed-profile-value
           "collect-source-files"
           (lambda () (sort (collect-source-files root package) string<?))))
         (files (vector-ref files-result 0))
         (source-scope-phase (vector-ref files-result 1))
         (parse-result (parse-source-files/profile root files))
         (source-files (vector-ref parse-result 0))
         (parse-phase (vector-ref parse-result 1))
         (slowest-files (vector-ref parse-result 2))
         (index (make-project-index root source-files package))
         (total-ms (duration-ms total-start (monotonic-ms)))
         (profile
          (hash (totalMs total-ms)
                (fileCount (length files))
                (definitionCount (length (project-definitions index)))
                (phases [package-phase source-scope-phase parse-phase])
                (slowestFiles slowest-files))))
    (hash (index index)
          (profile profile))))
;; collect-source-scope
;;   : (-> String (List String) ProjectIndex)
;;   | doc m%
;;       `collect-source-scope root paths` reads package metadata and parses only
;;       the existing Gerbil/config files named by `paths`.
;;       # Examples
;;       ```scheme
;;       (project-index-files (collect-source-scope "." '("src/core.ss")))
;;       ;; => changed source-file facts
;;       ```
;;     %
(def (collect-source-scope root paths)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (sort (changed-source-files root package paths) string<?)))
    (make-project-index root
                        (parse-source-files root files)
                        package)))
;; collect-project-package-only
;;   : (-> String ProjectIndex )
;;   | doc m%
;;       `collect-project-package-only root` returns package metadata without
;;       parsing source owners, which keeps package-policy checks lightweight.
;;
;;       # Examples
;;       ```scheme
;;       (project-index-files (collect-project-package-only "."))
;;       ;; => ()
;;       ```
;;     %
;; : (-> String ProjectIndex)
(def (collect-project-package-only root)
  (let* ((root (path-normalize root))
         (package (read-project-package root)))
    (make-project-index root '() package)))
;; read-native-forms
;;   : (-> String NativeFormsRead)
;;   | doc m%
;;       `read-native-forms path` reads a source file into native syntax forms
;;       and returns a vector containing forms plus read diagnostics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (vector-ref (read-native-forms "build.ss") 0)
;;       ;; => syntax forms
;;       ```
;;     %
;; : (-> String NativeFormsRead)
(def (read-native-forms path)
  (read-native-forms/lines path (read-source-lines path)))

;; read-native-forms/lines
;;   : (-> String (List SourceLine) NativeFormsRead)
;;   | doc m%
;;       `read-native-forms/lines path lines` reads native syntax forms while
;;       reusing the source lines already read by `parse-source-file`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (vector? (read-native-forms/lines "build.ss" (read-source-lines "build.ss")))
;;       ;; => #t
;;       ```
;;     %
(def (read-native-forms/lines path lines)
  (with-catch
   (lambda (exn)
     (vector '() (exception->string exn) #f #f #f))
   (lambda ()
     (if (member (path-extension path) +source-extensions+)
       (if (file-starts-with-lang?/lines lines)
         (read-lang-syntax-forms/lines path lines)
         (read-syntax-forms path))
       (read-syntax-forms path)))))

;;; Native reader tuple boundary: public reader helpers preserve the historical
;;; vector result, while parser internals use named accessors instead of slot
;;; indices at every call site.
;; : (-> NativeFormsRead (List Syntax))
(def (native-forms-read-forms read)
  (vector-ref read 0))

;; : (-> NativeFormsRead (Or String False))
(def (native-forms-read-parse-error read)
  (vector-ref read 1))

;; : (-> NativeFormsRead (Or String False))
(def (native-forms-read-package read)
  (vector-ref read 2))

;; : (-> NativeFormsRead (Or String False))
(def (native-forms-read-prelude read)
  (vector-ref read 3))

;; : (-> NativeFormsRead (Or String False))
(def (native-forms-read-namespace read)
  (vector-ref read 4))

;; read-syntax-forms
;;   : (-> String NativeFormsRead)
;;   | doc m%
;;       `read-syntax-forms path` reads standard Gerbil syntax forms while
;;       suppressing incidental reader output.
;;
;;       # Examples
;;
;;       ```scheme
;;       (vector-ref (read-syntax-forms "build.ss") 0)
;;       ;; => syntax forms
;;       ```
;;     %
;; : (-> String NativeFormsRead)
(def (read-syntax-forms path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file path))
      (vector (if (stx-list? body) (stx-map identity body) [body])
              #f #f #f #f))))
;; read-lang-syntax-forms
;;   : (-> String NativeFormsRead)
;;   | doc m%
;;       `read-lang-syntax-forms path` skips the `#lang` line and reads the
;;       remaining file body as syntax forms.
;;
;;       # Examples
;;
;;       ```scheme
;;       (vector-ref (read-lang-syntax-forms "sample.scm") 0)
;;       ;; => syntax forms
;;       ```
;;     %
;; : (-> String NativeFormsRead)
(def (read-lang-syntax-forms path)
  (read-lang-syntax-forms/lines path (read-source-lines path)))

;;; Reader boundary:
;;; - `call-with-input-string` owns the transient port lifetime for #lang body text.
;;; - The loop is intentionally EOF-driven because `read-syntax` is an input
;;;   protocol, not a pure list transform.
;; : (-> String (List SourceLine) NativeFormsRead )
(def (read-lang-syntax-forms/lines path lines)
  (let* ((body-lines (if (pair? lines) (cdr lines) '()))
         (body-text (string-join body-lines "\n"))
         (forms
         (call-with-input-string body-text
           (lambda (port)
              (let ((out '())
                    (done? #f))
                (while (not done?)
                (let (next (read-syntax port))
                  (if (eof-object? next)
                    (set! done? #t)
                    (set! out (cons next out)))))
                (reverse out))))))
    (vector forms #f #f #f #f)))
;; file-starts-with-lang?
;;   : (-> String Boolean)
;;   | doc m%
;;       `file-starts-with-lang? path` returns whether the first source line is
;;       a `#lang` declaration.
;;
;;       # Examples
;;
;;       ```scheme
;;       (file-starts-with-lang? "sample.scm")
;;       ;; => #t
;;       ```
;;     %
;; : (-> String Boolean)
(def (file-starts-with-lang? path)
  (file-starts-with-lang?/lines (read-source-lines path)))

;;; Probe boundary: malformed or unreadable leading text is treated as "not
;;; #lang" so source classification never turns a cheap prelude check into a
;;; parser error.
;; : (-> (List SourceLine) Boolean )
(def (file-starts-with-lang?/lines lines)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (pair? lines) (string-prefix? "#lang" (car lines))))))
;; file-has-non-core-prelude?
;;   : (-> String Boolean)
;;   | doc m%
;;       `file-has-non-core-prelude? path` checks the first lines for a prelude
;;       declaration outside `:gerbil/core`.
;;
;;       # Examples
;;
;;       ```scheme
;;       (file-has-non-core-prelude? "src/parser/core.ss")
;;       ;; => #f
;;       ```
;;     %
(def (file-has-non-core-prelude? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap
      (lambda (line)
        (and (string-prefix? "prelude:" (string-trim line))
             (not (string-contains line ":gerbil/core"))))
      (let (lines (read-file-lines path))
        (take lines (min 12 (length lines))))))))

;; : (-> Datum (List Datum) (Or Datum False))
(def (form-metadata-value/from-datums datum datum-rest)
  (cond
   ((and (pair? datum) (pair? (cdr datum))) (cadr datum))
   ((and (member datum '(package: prelude: namespace:))
         (pair? (cdr datum-rest)))
    (cadr datum-rest))
   (else #f)))

;; parse-source-file
;;   : (-> String String SourceFile)
;;   | doc m%
;;       `parse-source-file root path` materializes one source-file fact packet,
;;       including definitions, calls, imports, POO forms, quality facts, typed
;;       contracts, comments, and parse error evidence.
;;
;;       # Examples
;;
;;       ```scheme
;;       (source-file-path (parse-source-file "." "src/parser/core.ss"))
;;       ;; => "src/parser/core.ss"
;;       ```
;;     %
(def (parse-source-file* root path profile?)
  (let (stage-rows '())
    (def (record-stage name thunk)
      (if profile?
        (let (stage-start (monotonic-ms))
          (let (value (thunk))
            (set! stage-rows
              (cons (profile-row name
                                 (duration-ms stage-start (monotonic-ms)))
                    stage-rows))
            value))
        (thunk)))
    (let* ((fullpath (source-full-path root path))
         (relpath (relative-path root fullpath))
         (source-lines
          (record-stage
           "read-source-lines"
           (lambda () (read-source-lines fullpath))))
         (line-count (length source-lines))
         (read
          (record-stage
           "read-native-forms"
           (lambda () (read-native-forms/lines fullpath source-lines))))
         (forms (native-forms-read-forms read))
         (form-datums
          (record-stage
           "syntax->datum"
           (lambda () (map syntax->datum forms))))
         (parse-error (native-forms-read-parse-error read))
         (initial-package (native-forms-read-package read))
         (initial-prelude (native-forms-read-prelude read))
         (initial-namespace (native-forms-read-namespace read)))
    (let ((rest forms)
          (datum-rest form-datums)
          (package initial-package)
          (prelude initial-prelude)
          (namespace initial-namespace)
          (imports '())
          (exports '())
          (includes '())
          (definitions '())
          (calls '())
          (top-forms '())
          (module-imports '())
          (module-exports '())
          (macros '())
          (bindings '())
          (poo-forms '())
          (higher-order-forms '())
          (control-flow-forms '())
          (dependency-adapter-candidates '()))
      (record-stage
       "top-form-scan"
       (lambda ()
         (while (pair? rest)
           (let* ((form (car rest))
               (datum (car datum-rest))
               (head (form-datum-head datum))
               (metadata-value
                (form-metadata-value/from-datums datum datum-rest))
               (next-rest (form-next-rest datum rest))
               (next-datum-rest (form-next-rest datum datum-rest))
               (top-form (top-form-from relpath form datum))
               (next-calls (append (calls-from-form relpath form datum) calls))
               (form-module-imports
                (if (eq? head 'import)
                  (module-import-facts-from-form relpath form)
                  '()))
               (form-module-exports
                (if (eq? head 'export)
                  (module-export-facts-from-form relpath form)
                  '()))
               (form-macros (macro-facts-from-form relpath form datum))
               (form-bindings (binding-facts-from-form relpath form datum))
               (form-poo-forms (poo-form-facts-from-form relpath form datum))
               (form-higher-order-forms
                (higher-order-facts-from-form relpath form datum))
               (form-control-flow-forms
                (control-flow-facts-from-form relpath form datum))
               (form-dependency-adapter-candidates
                (dependency-adapter-candidates-from-form relpath form datum)))
          (set! top-forms (cons top-form top-forms))
          (set! control-flow-forms
            (append form-control-flow-forms control-flow-forms))
          (set! dependency-adapter-candidates
            (append form-dependency-adapter-candidates
                    dependency-adapter-candidates))
          (cond
           ((eq? head 'package:)
            (set! package (datum->string metadata-value)))
           ((eq? head 'prelude:)
            (set! prelude (datum->string metadata-value)))
           ((eq? head 'namespace:)
            (set! namespace (datum->string metadata-value)))
           ((eq? head 'import)
           (set! imports (append (module-refs datum) imports))
            (set! module-imports (append form-module-imports module-imports))
            (set! macros (append form-macros macros))
            (set! bindings (append form-bindings bindings))
            (set! poo-forms (append form-poo-forms poo-forms))
            (set! higher-order-forms
              (append form-higher-order-forms higher-order-forms)))
           ((eq? head 'export)
            (set! exports (append (export-symbols datum) exports))
            (set! module-exports (append form-module-exports module-exports))
            (set! macros (append form-macros macros))
            (set! bindings (append form-bindings bindings))
            (set! poo-forms (append form-poo-forms poo-forms))
            (set! higher-order-forms
              (append form-higher-order-forms higher-order-forms)))
           ((eq? head 'include)
            (set! includes (append (string-datums datum) includes))
            (set! macros (append form-macros macros))
            (set! bindings (append form-bindings bindings))
            (set! poo-forms (append form-poo-forms poo-forms))
            (set! higher-order-forms
              (append form-higher-order-forms higher-order-forms)))
           ((member head +definition-heads+)
            (set! definitions
              (append (definitions-from-form relpath form datum) definitions))
            (set! calls next-calls)
            (set! macros (append form-macros macros))
            (set! bindings (append form-bindings bindings))
            (set! poo-forms (append form-poo-forms poo-forms))
            (set! higher-order-forms
              (append form-higher-order-forms higher-order-forms)))
           (else
            (set! calls next-calls)
            (set! macros (append form-macros macros))
            (set! bindings (append form-bindings bindings))
            (set! poo-forms (append form-poo-forms poo-forms))
            (set! higher-order-forms
              (append form-higher-order-forms higher-order-forms))))
             (set! rest next-rest)
             (set! datum-rest next-datum-rest)))))
      (let ((ordered-definitions (reverse definitions))
            (ordered-calls (reverse calls))
            (ordered-macros (reverse macros))
            (ordered-poo-forms (reverse poo-forms))
            (ordered-higher-order-forms (reverse higher-order-forms))
            (ordered-control-flow-forms (reverse control-flow-forms))
            (ordered-dependency-adapter-candidates
             (reverse dependency-adapter-candidates)))
        (let* ((ordered-exports
                (record-stage "unique-exports"
                              (lambda () (unique exports))))
               (macro-family-facts
                (record-stage
                 "macro-family-facts"
                 (lambda ()
                   (macro-family-facts-from-macros relpath ordered-macros))))
               (predicate-family-facts
                (record-stage
                 "predicate-family-facts"
                 (lambda ()
                   (predicate-family-facts-from-source
                    relpath ordered-definitions ordered-calls))))
               (field-access-pattern-facts
                (record-stage
                 "field-access-pattern-facts"
                 (lambda ()
                   (field-access-pattern-facts-from-source
                    relpath
                    ordered-calls
                    ordered-definitions
                    form-datums))))
               (projection-burst-facts
                (record-stage
                 "projection-burst-facts"
                 (lambda ()
                   (projection-burst-facts-from-source relpath ordered-calls))))
               (boolean-condition-facts
                (record-stage
                 "boolean-condition-facts"
                 (lambda ()
                   (boolean-condition-facts-from-source
                    relpath
                    ordered-definitions
                    ordered-calls
                    form-datums))))
               (loop-driver-facts
                (record-stage
                 "loop-driver-facts"
                 (lambda ()
                   (loop-driver-facts-from-source
                    relpath
                    ordered-calls
                    ordered-higher-order-forms
                    ordered-control-flow-forms))))
               (dependency-adapter-quality-facts
                (record-stage
                 "dependency-adapter-quality-facts"
                 (lambda ()
                   (dependency-adapter-quality-facts-from-candidates
                    relpath
                    ordered-dependency-adapter-candidates
                    (reverse module-imports)))))
               (typed-contract-facts
                (record-stage
                 "typed-contract-facts"
                 (lambda ()
                   (typed-contract-facts-from-lines
                    source-lines relpath ordered-definitions
                    ordered-calls
                    ordered-higher-order-forms
                    ordered-control-flow-forms))))
               (comment-quality-facts
                (record-stage
                 "comment-quality-facts"
                 (lambda ()
                   (comment-quality-facts-from-lines
                    source-lines relpath ordered-definitions
                    ordered-macros
                    ordered-poo-forms
                    ordered-higher-order-forms
                    ordered-control-flow-forms))))
               (function-quality-profiles
                (record-stage
                 "function-quality-profiles"
                 (lambda ()
                   (function-quality-profiles-from-source
                    relpath
                    ordered-exports
                    ordered-definitions
                    typed-contract-facts
                    comment-quality-facts
                    ordered-control-flow-forms
                    ordered-higher-order-forms
                    predicate-family-facts
                    field-access-pattern-facts
                    loop-driver-facts
                    ordered-macros
                    ordered-poo-forms)))))
          (let (source-file
                (record-stage
                 "make-source-file"
                 (lambda ()
                   (make-source-file
                    relpath line-count package prelude namespace
                    (unique imports) ordered-exports (unique includes)
                    ordered-definitions ordered-calls
                    (reverse top-forms)
                    (reverse module-imports)
                    (reverse module-exports)
                    ordered-macros
                    macro-family-facts
                    (reverse bindings)
                    ordered-poo-forms
                    ordered-higher-order-forms
                    ordered-control-flow-forms
                    predicate-family-facts
                    field-access-pattern-facts
                    projection-burst-facts
                    boolean-condition-facts
                    loop-driver-facts
                    dependency-adapter-quality-facts
                    function-quality-profiles
                    typed-contract-facts
                    comment-quality-facts
                    parse-error))))
            (if profile?
              (vector source-file (reverse stage-rows))
              source-file))))))))

;; : (-> String String SourceFile)
(def (parse-source-file root path)
  (parse-source-file* root path #f))

;; : (-> String String Vector)
(def (parse-source-file/profile root path)
  (parse-source-file* root path #t))
