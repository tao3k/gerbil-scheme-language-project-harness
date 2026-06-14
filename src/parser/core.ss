;;; -*- Gerbil -*-
;;; Parser-owned facts for the Gerbil Scheme project harness.

(import :gerbil/expander
        :gerbil/gambit
        :parser/comment-quality
        :parser/control-flow
        :parser/higher-order
        :parser/model
        :parser/package
        :parser/poo
        :parser/support
        :parser/syntax
        :parser/typed-contract
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
        agent-policy-enabled-rules
        agent-policy-disabled-rules
        project-index-root
        project-index-files
        project-index-package)
;; ConfigConstant
(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; ConfigConstant
(def +config-files+ '("gerbil.pkg" "build.ss"))
;; Boolean
(def +ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target" "src/gambit" "tree-sitter"))
;;; Boundary:
;;; - collect-project composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ProjectIndex <- String
(def (collect-project root)
  (let* ((root (path-normalize root))
         (package (read-project-package root))
         (files (sort (collect-source-files root package) string<?)))
    (make-project-index root
                        (map (cut parse-source-file root <>) files)
                        package)))
;;; Boundary:
;;; - collect-source-files composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; CollectSourceFiles <- String MaybePackage
(def (collect-source-files root . maybe-package)
  (let* ((package (and (pair? maybe-package) (car maybe-package)))
         (scope-policy (and package
                            (project-package-source-scope-policy package)))
         (source-roots (configured-source-roots scope-policy))
         (ignored-dirs (append +ignored-dirs+
                               (if scope-policy
                                 (source-scope-policy-exclude-directories scope-policy)
                                 '()))))
    (dedupe
     (map path-normalize
          (append (root-config-files root)
                  (apply append
                         (map (lambda (source-root)
                                (let (path (path-expand source-root root))
                                  (if (source-directory? path)
                                    (walk-source-directory root path ignored-dirs)
                                    '())))
                              source-roots)))))))
;; (List String) <- Policy
(def (configured-source-roots policy)
  (let (roots (and policy (source-scope-policy-roots policy)))
    (if (and roots (pair? roots)) roots ["."])))
;;; Boundary:
;;; - root-config-files composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; RootConfigFiles <- String
(def (root-config-files root)
  (filter file-exists?
          (map (cut path-expand <> root) +config-files+)))
;;; Boundary:
;;; - source-directory? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (source-directory? path)
  (with-catch
   (lambda (_) #f)
   (lambda () (eq? (file-type path) 'directory))))
;; WalkSourceDirectory <- String Dir IgnoredDirs
(def (walk-source-directory root dir ignored-dirs)
  (def (walk dir acc)
    (for/fold (result acc) (entry (sort (directory-files dir) string<?))
      (if (member entry '("." ".."))
        result
        (let (path (path-expand entry dir))
          (cond
           ((and (source-directory? path)
                 (not (ignored-source-directory? root path entry ignored-dirs)))
            (walk path result))
           ((gerbil-source-path? path)
            (cons path result))
           (else result))))))
  (walk dir '()))
;; Boolean <- String String Entry IgnoredDirs
(def (ignored-source-directory? root path entry ignored-dirs)
  (let (relpath (relative-path root path))
    (or (member entry ignored-dirs)
        (member relpath ignored-dirs))))
;; Boolean <- String
(def (gerbil-source-path? path)
  (or (member (path-extension path) +source-extensions+)
      (member (path-strip-directory path) +config-files+)))
;;; Boundary:
;;; - source-line-count composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- String
(def (source-line-count path)
  (with-catch
   (lambda (_) 0)
   (lambda () (length (read-file-lines path)))))
;;; Boundary:
;;; - read-native-forms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- String
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
;;; Invariant:
;;; - read-syntax-forms owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- String
(def (read-syntax-forms path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file path))
      (vector (if (stx-list? body) (stx-map identity body) [body])
              #f #f #f #f))))
;;; Boundary:
;;; - read-lang-syntax-forms composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- String
(def (read-lang-syntax-forms path)
  (let* ((lines (read-file-lines path))
         (body-text (join-lines (cdr lines)))
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
;;; Boundary:
;;; - file-starts-with-lang? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (file-starts-with-lang? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines path))
       (and (pair? lines) (string-prefix? "#lang" (car lines)))))))
;;; Boundary:
;;; - file-has-non-core-prelude? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- String
(def (file-has-non-core-prelude? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap
      (lambda (line)
        (and (string-prefix? "prelude:" (string-trim line))
             (not (string-contains line ":gerbil/core"))))
      (take* (read-file-lines path) 12)))))
;;; Boundary:
;;; - project-definitions composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Definition) <- ProjectIndex
(def (project-definitions index)
  (apply append (map source-file-definitions (project-index-files index))))
;;; Boundary:
;;; - project-calls composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List CallFact) <- ProjectIndex
(def (project-calls index)
  (apply append (map source-file-calls (project-index-files index))))
;;; Boundary:
;;; - project-typed-contract-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypedContractFact) <- ProjectIndex
(def (project-typed-contract-facts index)
  (apply append
         (map source-file-typed-contract-facts
              (project-index-files index))))
;;; Boundary:
;;; - project-comment-quality-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List CommentQualityFact) <- ProjectIndex
(def (project-comment-quality-facts index)
  (apply append
         (map source-file-comment-quality-facts
              (project-index-files index))))
;;; Boundary:
;;; - find-owner composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; FindOwner <- ProjectIndex String
(def (find-owner index owner)
  (find (lambda (file) (equal? (source-file-path file) (normalize-owner owner)))
        (project-index-files index)))
;; Selector <- Definition
(def (definition-selector defn)
  (string-append (definition-path defn) ":"
                 (number->string (definition-start defn))
                 "-"
                 (number->string (definition-end defn))))
;; Selector <- CallFact
(def (call-fact-selector call)
  (string-append (call-fact-path call) ":"
                 (number->string (call-fact-start call))
                 "-"
                 (number->string (call-fact-end call))))
;; Selector <- Fact
(def (module-import-fact-selector fact)
  (string-append (module-import-fact-path fact) ":"
                 (number->string (module-import-fact-start fact))
                 "-"
                 (number->string (module-import-fact-end fact))))
;; Selector <- Fact
(def (macro-fact-selector fact)
  (string-append (macro-fact-path fact) ":"
                 (number->string (macro-fact-start fact))
                 "-"
                 (number->string (macro-fact-end fact))))
;; Selector <- Fact
(def (binding-fact-selector fact)
  (string-append (binding-fact-path fact) ":"
                 (number->string (binding-fact-start fact))
                 "-"
                 (number->string (binding-fact-end fact))))
;; Selector <- Fact
(def (poo-form-fact-selector fact)
  (string-append (poo-form-fact-path fact) ":"
                 (number->string (poo-form-fact-start fact))
                 "-"
                 (number->string (poo-form-fact-end fact))))
;; Selector <- Fact
(def (higher-order-fact-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))
;; Selector <- ControlFlowFact
(def (control-flow-fact-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))
;; Selector <- TypedContractFact
(def (typed-contract-fact-selector fact)
  (string-append (typed-contract-fact-path fact) ":"
                 (number->string (typed-contract-fact-comment-start fact))
                 "-"
                 (number->string (typed-contract-fact-comment-end fact))))
;; Selector <- CommentQualityFact
(def (comment-quality-fact-selector fact)
  (string-append (comment-quality-fact-path fact) ":"
                 (number->string (comment-quality-fact-comment-start fact))
                 "-"
                 (number->string (comment-quality-fact-comment-end fact))))
;; Selector <- Form
(def (top-form-selector form)
  (string-append (top-form-path form) ":"
                 (number->string (top-form-start form))
                 "-"
                 (number->string (top-form-end form))))
;; String <- String String
(def (relative-path root path)
  (let* ((root* (path-normalize root))
         (path* (path-normalize path))
         (prefix (if (string-suffix? "/" root*) root* (string-append root* "/"))))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))
;; String <- String String
(def (source-full-path root path)
  (if (string-prefix? "/" path)
    (path-normalize path)
    (path-expand path root)))
;; NormalizeOwner <- String
(def (normalize-owner owner)
  (if (string-prefix? "./" owner)
    (substring owner 2 (string-length owner))
    owner))
;;; Invariant:
;;; - parse-source-file owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SourceFile <- String String
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
    (let ((rest forms)
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
      (while (pair? rest)
        (let* ((form (car rest))
               (datum (syntax->datum form))
               (head (and (pair? datum) (car datum)))
               (top-form (top-form-from relpath form datum))
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
                (control-flow-facts-from-form relpath form datum)))
          (set! top-forms (cons top-form top-forms))
          (set! control-flow-forms
            (append form-control-flow-forms control-flow-forms))
          (cond
           ((eq? head 'package:)
            (set! package (datum->string (safe-cadr datum))))
           ((eq? head 'prelude:)
            (set! prelude (datum->string (safe-cadr datum))))
           ((eq? head 'namespace:)
            (set! namespace (datum->string (safe-cadr datum))))
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
          (set! rest (cdr rest))))
      (let ((ordered-definitions (reverse definitions))
            (ordered-calls (reverse calls))
            (ordered-macros (reverse macros))
            (ordered-poo-forms (reverse poo-forms))
            (ordered-higher-order-forms (reverse higher-order-forms))
            (ordered-control-flow-forms (reverse control-flow-forms)))
        (make-source-file relpath line-count package prelude namespace
                          (dedupe imports) (dedupe exports) (dedupe includes)
                          ordered-definitions ordered-calls
                          (reverse top-forms)
                          (reverse module-imports)
                          ordered-macros
                          (reverse bindings)
                          ordered-poo-forms
                          ordered-higher-order-forms
                          ordered-control-flow-forms
                          (typed-contract-facts-from-definitions
                           fullpath relpath ordered-definitions
                           ordered-calls
                           ordered-higher-order-forms
                           ordered-control-flow-forms)
                          (comment-quality-facts-from-source
                           fullpath relpath ordered-definitions
                           ordered-macros
                           ordered-poo-forms
                           ordered-higher-order-forms
                           ordered-control-flow-forms)
                          parse-error)))))
