;;; -*- Gerbil -*-
;;; Parser-owned facts for the Gerbil Scheme project harness.

(import :gerbil/expander
        :gerbil/gambit
        :parser/control-flow
        :parser/higher-order
        :parser/model
        :parser/package
        :parser/poo
        :parser/support
        :parser/syntax
        :std/iter
        :std/misc/ports
        :std/sort
        :std/srfi/13)

(export +source-extensions+
        +config-files+
        +ignored-dirs+
        collect-project
        collect-source-files
        gerbil-source-path?
        parse-source-file
        project-definitions
        project-calls
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
        macro-fact-name
        macro-fact-kind
        macro-fact-path
        macro-fact-start
        macro-fact-end
        macro-fact-transformer
        macro-fact-phase
        macro-fact-pattern-count
        macro-fact-hygienic
        macro-fact-selector
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
        control-flow-fact-selector
        top-form-kind
        top-form-head
        top-form-path
        top-form-start
        top-form-end
        top-form-selector
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
        source-file-macros
        source-file-bindings
        source-file-poo-forms
        source-file-higher-order-forms
        source-file-control-flow-forms
        source-file-parse-error
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-package-test-directory-policy
        test-directory-policy-allowed-directories
        test-directory-policy-explanation
        project-index-root
        project-index-files
        project-index-package)

(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
(def +config-files+ '("gerbil.pkg" "build.ss"))
(def +ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target" "src/gambit" "tree-sitter"))
(def (collect-project root)
  (let* ((root (path-normalize root))
         (files (sort (collect-source-files root) string<?)))
    (make-project-index root
                        (map (cut parse-source-file root <>) files)
                        (read-project-package root))))

(def (collect-source-files root)
  (def (dir? path)
    (with-catch
     (lambda (_) #f)
     (lambda () (eq? (file-type path) 'directory))))
  (def (walk dir acc)
    (for/fold (result acc) (entry (sort (directory-files dir) string<?))
      (if (member entry '("." ".."))
        result
        (let (path (path-expand entry dir))
          (cond
           ((and (dir? path) (not (member entry +ignored-dirs+)))
            (walk path result))
           ((gerbil-source-path? path)
            (cons path result))
           (else result))))))
  (walk root '()))

(def (gerbil-source-path? path)
  (or (member (path-extension path) +source-extensions+)
      (member (path-strip-directory path) +config-files+)))

(def (source-line-count path)
  (with-catch
   (lambda (_) 0)
   (lambda () (length (read-file-lines path)))))

(def (read-native-forms path)
  (with-catch
   (lambda (exn)
     (vector '() (exception->string exn) #f #f #f))
   (lambda ()
     (if (member (path-extension path) +source-extensions+)
       (if (file-starts-with-lang? path)
         (read-lang-syntax-forms path)
         (if (file-has-non-core-prelude? path)
           (read-syntax-forms path)
           (with-catch
            (lambda (_)
              (read-syntax-forms path))
            (lambda ()
              (parameterize ((current-output-port (open-output-string))
                             (current-error-port (open-output-string)))
                (let (((values prelude module-id namespace body) (core-read-module path)))
                  (vector body #f
                          (datum->string module-id)
                          (datum->string prelude)
                          (datum->string namespace))))))))
       (read-syntax-forms path)))))

(def (read-syntax-forms path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file path))
      (vector (if (stx-list? body) (stx-map identity body) [body])
              #f #f #f #f))))

(def (read-lang-syntax-forms path)
  (let* ((lines (read-file-lines path))
         (body-text (join-lines (cdr lines)))
         (forms
          (call-with-input-string body-text
            (lambda (port)
              (let lp ((out '()))
                (let (next (read-syntax port))
                  (if (eof-object? next)
                    (reverse out)
                    (lp (cons next out)))))))))
    (vector forms #f #f #f #f)))

(def (file-starts-with-lang? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines path))
       (and (pair? lines) (string-prefix? "#lang" (car lines)))))))

(def (file-has-non-core-prelude? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap
      (lambda (line)
        (and (string-prefix? "prelude:" (string-trim line))
             (not (string-contains line ":gerbil/core"))))
      (take* (read-file-lines path) 12)))))

(def (project-definitions index)
  (apply append (map source-file-definitions (project-index-files index))))

(def (project-calls index)
  (apply append (map source-file-calls (project-index-files index))))

(def (find-owner index owner)
  (find (lambda (file) (equal? (source-file-path file) (normalize-owner owner)))
        (project-index-files index)))

(def (definition-selector defn)
  (string-append (definition-path defn) ":"
                 (number->string (definition-start defn))
                 "-"
                 (number->string (definition-end defn))))

(def (call-fact-selector call)
  (string-append (call-fact-path call) ":"
                 (number->string (call-fact-start call))
                 "-"
                 (number->string (call-fact-end call))))

(def (module-import-fact-selector fact)
  (string-append (module-import-fact-path fact) ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))

(def (macro-fact-selector fact)
  (string-append (macro-fact-path fact) ":"
                 (number->string (macro-fact-start fact))
                 "-"
                 (number->string (macro-fact-end fact))))

(def (binding-fact-selector fact)
  (string-append (binding-fact-path fact) ":"
                 (number->string (binding-fact-start fact))
                 "-"
                 (number->string (binding-fact-end fact))))

(def (poo-form-fact-selector fact)
  (string-append (poo-form-fact-path fact) ":"
                 (number->string (poo-form-fact-start fact))
                 "-"
                 (number->string (poo-form-fact-end fact))))

(def (higher-order-fact-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

(def (control-flow-fact-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))

(def (top-form-selector form)
  (string-append (top-form-path form) ":"
                 (number->string (top-form-start form))
                 "-"
                 (number->string (top-form-end form))))

(def (relative-path root path)
  (let* ((root* (path-normalize root))
         (path* (path-normalize path))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

(def (source-full-path root path)
  (if (string-prefix? "/" path)
    (path-normalize path)
    (path-expand path root)))

(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))

(def (parse-source-file root path)
  (let* ((fullpath (source-full-path root path))
         (relpath (relative-path root fullpath))
         (line-count (source-line-count fullpath))
         (read-result (read-native-forms fullpath))
         (forms (vector-ref read-result 0))
         (parse-error (vector-ref read-result 1))
         (initial-package (vector-ref read-result 2))
         (initial-prelude (vector-ref read-result 3))
         (initial-namespace (vector-ref read-result 4)))
    (let lp ((rest forms)
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
             (macros '())
             (bindings '())
             (poo-forms '())
             (higher-order-forms '())
             (control-flow-forms '()))
      (match rest
        ([form . more]
         (let* ((datum (syntax->datum form))
                (head (and (pair? datum) (car datum)))
                (top-form (top-form-from relpath form datum))
                (next-top-forms (cons top-form top-forms))
                (next-calls (append (calls-from-form relpath form datum) calls))
                (form-module-imports
                 (if (eq? head 'import)
                   (module-import-facts-from-form relpath form)
                   '()))
                (form-macros (macro-facts-from-form relpath form datum))
                (form-bindings (binding-facts-from-form relpath form datum))
                (form-poo-forms (poo-form-facts-from-form relpath form datum))
                (form-higher-order-forms
                 (higher-order-facts-from-form relpath form datum))
                (form-control-flow-forms
                 (control-flow-facts-from-form relpath form datum))
                (next-control-flow-forms
                 (append form-control-flow-forms control-flow-forms)))
           (cond
            ((eq? head 'package:)
             (lp more (datum->string (safe-cadr datum)) prelude namespace imports exports includes definitions calls next-top-forms module-imports macros bindings poo-forms higher-order-forms next-control-flow-forms))
            ((eq? head 'prelude:)
             (lp more package (datum->string (safe-cadr datum)) namespace imports exports includes definitions calls next-top-forms module-imports macros bindings poo-forms higher-order-forms next-control-flow-forms))
            ((eq? head 'namespace:)
             (lp more package prelude (datum->string (safe-cadr datum)) imports exports includes definitions calls next-top-forms module-imports macros bindings poo-forms higher-order-forms next-control-flow-forms))
            ((eq? head 'import)
             (lp more package prelude namespace
                 (append (module-refs datum) imports) exports includes definitions calls next-top-forms
                 (append form-module-imports module-imports)
                 (append form-macros macros)
                 (append form-bindings bindings)
                 (append form-poo-forms poo-forms)
                 (append form-higher-order-forms higher-order-forms)
                 next-control-flow-forms))
            ((eq? head 'export)
             (lp more package prelude namespace imports
                 (append (export-symbols datum) exports) includes definitions calls next-top-forms
                 module-imports
                 (append form-macros macros)
                 (append form-bindings bindings)
                 (append form-poo-forms poo-forms)
                 (append form-higher-order-forms higher-order-forms)
                 next-control-flow-forms))
            ((eq? head 'include)
             (lp more package prelude namespace imports exports
                 (append (string-datums datum) includes) definitions calls next-top-forms
                 module-imports
                 (append form-macros macros)
                 (append form-bindings bindings)
                 (append form-poo-forms poo-forms)
                 (append form-higher-order-forms higher-order-forms)
                 next-control-flow-forms))
            ((member head +definition-heads+)
             (lp more package prelude namespace imports exports includes
                 (append (definitions-from-form relpath form datum) definitions)
                 next-calls next-top-forms
                 module-imports
                 (append form-macros macros)
                 (append form-bindings bindings)
                 (append form-poo-forms poo-forms)
                 (append form-higher-order-forms higher-order-forms)
                 next-control-flow-forms))
            (else
             (lp more package prelude namespace imports exports includes definitions
                 next-calls next-top-forms
                 module-imports
                 (append form-macros macros)
                 (append form-bindings bindings)
                 (append form-poo-forms poo-forms)
                 (append form-higher-order-forms higher-order-forms)
                 next-control-flow-forms)))))
        (else
         (make-source-file relpath line-count package prelude namespace
                           (dedupe imports) (dedupe exports) (dedupe includes)
                           (reverse definitions) (reverse calls)
                           (reverse top-forms)
                           (reverse module-imports)
                           (reverse macros)
                           (reverse bindings)
                           (reverse poo-forms)
                           (reverse higher-order-forms)
                           (reverse control-flow-forms)
                           parse-error))))))
