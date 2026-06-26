;;; -*- Gerbil -*-
;;; Single source-file parsing and reader helpers.

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
        :parser/profile
        :parser/quality-shape
        :parser/selectors
        :parser/source-scope
        :parser/support
        :parser/syntax
        :parser/typed-contract
        :support/time
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports open-output-string read-file-lines)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-join
                 string-prefix?
                 string-trim))

(export read-native-forms
        read-native-forms/lines
        native-forms-read-forms
        native-forms-read-parse-error
        native-forms-read-package
        native-forms-read-prelude
        native-forms-read-namespace
        read-syntax-forms
        read-lang-syntax-forms
        read-lang-syntax-forms/lines
        file-starts-with-lang?
        file-starts-with-lang?/lines
        file-has-non-core-prelude?
        form-metadata-value/from-datums
        parse-source-file*
        parse-source-file
        parse-source-file/profile)

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
              (values source-file (reverse stage-rows))
              source-file))))))))

;; : (-> String String SourceFile)
(def (parse-source-file root path)
  (parse-source-file* root path #f))

;; : (-> String String (Values SourceFile (List HashTable)))
(def (parse-source-file/profile root path)
  (parse-source-file* root path #t))
