;;; -*- Gerbil -*-
;;; Parser-owned facts for the Gerbil Scheme project harness.

(import :gerbil/expander
        :gerbil/gambit
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
        call-fact-caller
        call-fact-selector
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
        source-file-parse-error
        project-package-path
        project-package-name
        project-package-dependencies
        project-package-manager
        project-index-root
        project-index-files
        project-index-package)

(def +source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
(def +config-files+ '("gerbil.pkg" "build.ss"))
(def +ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target" "src/gambit" "tree-sitter"))
(def +definition-heads+
  '(def def* define define-values define-syntax
    defstruct defclass defsyntax defrules defalias defmethod defcompile-method))
(def +non-call-heads+
  '(quote quasiquote syntax quote-syntax
    package package: prelude: namespace: import export include
    if begin begin0 lambda case-lambda
    let let* letrec let-values let*-values
    cond case and or when unless match))

(defstruct definition (name kind path start end formals arity))
(defstruct call-fact (callee arity path start end arguments caller))
(defstruct top-form (kind head path start end))
(defstruct source-file (path line-count package prelude namespace imports exports includes definitions calls forms parse-error))
(defstruct project-package (path name dependencies manager))
(defstruct project-index (root files package))

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

(def (read-project-package root)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let* ((path (path-expand "gerbil.pkg" root))
            (read-result (read-syntax-forms path))
            (forms (map syntax->datum (vector-ref read-result 0)))
            (package-form (find package-form? forms)))
       (and package-form
            (make-project-package "gerbil.pkg"
                                  (datum->string (safe-cadr package-form))
                                  (package-dependencies package-form)
                                  "gxpkg"))))))

(def (package-form? datum)
  (and (pair? datum) (eq? (car datum) 'package:)))

(def (package-dependencies datum)
  (let lp ((rest (datum-list-items datum)))
    (match rest
      (['depend: deps . _]
       (dedupe (filter-map datum->string (datum-list-items deps))))
      ([_ . more] (lp more))
      (else '()))))

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
             (top-forms '()))
      (match rest
        ([form . more]
         (let* ((datum (syntax->datum form))
                (head (and (pair? datum) (car datum)))
                (top-form (top-form-from relpath form datum))
                (next-top-forms (cons top-form top-forms))
                (next-calls (append (calls-from-form relpath form datum) calls)))
           (cond
            ((eq? head 'package:)
             (lp more (datum->string (safe-cadr datum)) prelude namespace imports exports includes definitions calls next-top-forms))
            ((eq? head 'prelude:)
             (lp more package (datum->string (safe-cadr datum)) namespace imports exports includes definitions calls next-top-forms))
            ((eq? head 'namespace:)
             (lp more package prelude (datum->string (safe-cadr datum)) imports exports includes definitions calls next-top-forms))
            ((eq? head 'import)
             (lp more package prelude namespace
                 (append (module-refs datum) imports) exports includes definitions calls next-top-forms))
            ((eq? head 'export)
             (lp more package prelude namespace imports
                 (append (export-symbols datum) exports) includes definitions calls next-top-forms))
            ((eq? head 'include)
             (lp more package prelude namespace imports exports
                 (append (string-datums datum) includes) definitions calls next-top-forms))
            ((member head +definition-heads+)
             (lp more package prelude namespace imports exports includes
                 (append (definitions-from-form relpath form datum) definitions)
                 next-calls next-top-forms))
            (else
             (lp more package prelude namespace imports exports includes definitions
                 next-calls next-top-forms)))))
        (else
         (make-source-file relpath line-count package prelude namespace
                           (dedupe imports) (dedupe exports) (dedupe includes)
                           (reverse definitions) (reverse calls)
                           (reverse top-forms) parse-error))))))

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

(def (definitions-from-form relpath form datum)
  (let ((head (car datum))
        (name-datums (definition-name-datums datum)))
    (map (lambda (name)
             (let* ((loc (stx-source form))
                  (start (source-start-line loc))
                  (end (source-end-line loc)))
             (make-definition (datum->string name) (symbol->string head)
                              relpath start end
                              (definition-formal-names datum name)
                              (definition-formal-arity datum name))))
         name-datums)))

(def (calls-from-form relpath form datum)
  (let* ((loc (stx-source form))
         (start (source-start-line loc))
         (end (source-end-line loc))
         (caller (form-caller-name datum)))
    (calls-from-exprs relpath start end (form-body-datums datum) caller)))

(def (calls-from-exprs relpath start end exprs caller)
  (apply append (map (cut calls-from-expr relpath start end <> caller)
                     (datum-list-items exprs))))

(def (calls-from-expr relpath start end expr caller)
  (cond
   ((not (pair? expr)) '())
   ((not (symbol? (car expr)))
    (calls-from-exprs relpath start end expr caller))
   ((member (car expr) '(quote quasiquote syntax quote-syntax))
    '())
   ((member (car expr) +definition-heads+)
    (calls-from-exprs relpath start end
                      (form-body-datums expr)
                      (or (form-caller-name expr) caller)))
   ((let-head? (car expr))
    (append (calls-from-let-bindings relpath start end (safe-cadr expr) caller)
            (calls-from-exprs relpath start end (let-body-datums expr) caller)))
   ((member (car expr) +non-call-heads+)
    (calls-from-exprs relpath start end (cdr expr) caller))
   (else
    (let (args (datum-list-items (cdr expr)))
      (cons (make-call-fact (datum->string (car expr))
                            (length args)
                            relpath start end
                            (map datum->string args)
                            caller)
            (calls-from-exprs relpath start end (cdr expr) caller))))))

(def (form-caller-name datum)
  (and (pair? datum)
       (let (names (definition-name-datums datum))
         (and (pair? names)
              (null? (cdr names))
              (datum->string (car names))))))

(def (form-body-datums datum)
  (let ((head (and (pair? datum) (car datum))))
    (cond
     ((member head +definition-heads+) (safe-cddr datum))
     (else [datum]))))

(def (let-head? head)
  (member head '(let let* letrec let-values let*-values)))

(def (let-body-datums expr)
  (let ((head (car expr))
        (second (safe-cadr expr)))
    (cond
     ((and (eq? head 'let) (symbol? second))
      (safe-cdddr expr))
     (else (safe-cddr expr)))))

(def (calls-from-let-bindings relpath start end bindings caller)
  (cond
   ((not (pair? bindings)) '())
   (else
    (apply append
           (map (lambda (binding)
                  (cond
                   ((and (pair? binding)
                         (pair? (cdr binding))
                         (not (list? (car binding))))
                    (calls-from-expr relpath start end (cadr binding) caller))
                   ((and (pair? binding)
                         (list? (car binding))
                         (pair? (cdr binding)))
                    (calls-from-expr relpath start end (cadr binding) caller))
                   (else '())))
                (datum-list-items bindings))))))

(def (top-form-from relpath form datum)
  (let* ((head (and (pair? datum) (car datum)))
         (loc (stx-source form)))
    (make-top-form (form-kind head) (datum->string head) relpath
                   (source-start-line loc) (source-end-line loc))))

(def (form-kind head)
  (cond
   ((eq? head 'package:) "package")
   ((eq? head 'prelude:) "prelude")
   ((eq? head 'namespace:) "namespace")
   ((eq? head 'import) "import")
   ((eq? head 'export) "export")
   ((eq? head 'include) "include")
   ((member head +definition-heads+) "definition")
   (else "form")))

(def (definition-name-datums datum)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(def def* define))
      (cond
       ((symbol? second) [second])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     ((eq? head 'define-values)
      (if (list? second) (filter symbol? second) '()))
     ((eq? head 'defmethod)
      (cond
       ((symbol? second) [second])
       ((and (pair? second) (symbol? (car second))) [(car second)])
       (else '())))
     ((symbol? second) [second])
     (else '()))))

(def (definition-formal-names datum name)
  (filter-map
   (lambda (formal)
     (and (symbol? formal) (datum->string formal)))
   (definition-formal-datums datum name)))

(def (definition-formal-arity datum name)
  (let (formals (definition-formal-datums datum name))
    (and formals (length formals))))

(def (definition-formal-datums datum name)
  (let ((head (car datum))
        (second (safe-cadr datum)))
    (cond
     ((member head '(def def* define defmethod))
      (cond
       ((and (pair? second) (eq? (car second) name))
        (formal-tail-datums (cdr second)))
       (else '())))
     (else '()))))

(def (formal-tail-datums tail)
  (cond
   ((null? tail) '())
   ((symbol? tail) [tail])
   ((pair? tail)
    (let (head (car tail))
      (if (symbol? head)
        (cons head (formal-tail-datums (cdr tail)))
        (formal-tail-datums (cdr tail)))))
   (else '())))

(def (module-refs datum)
  (dedupe
   (filter-map
    (lambda (item)
      (cond
       ((string? item) item)
       ((and (symbol? item) (string-prefix? ":" (symbol->string item)))
        (symbol->string item))
       (else #f)))
    (flatten datum))))

(def (export-symbols datum)
  (dedupe
   (filter-map
    (lambda (item)
      (and (symbol? item)
           (let (s (symbol->string item))
             (and (not (member s '("export" "import:" "except-out" "rename:" "phi:" "only-in")))
                  (not (string-prefix? ":" s))
                  s))))
    (flatten datum))))

(def (string-datums datum)
  (filter string? (flatten datum)))

(def (dedupe items)
  (let lp ((rest items) (seen '()) (out '()))
    (match rest
      ([item . more]
       (if (member item seen)
         (lp more seen out)
         (lp more (cons item seen) (cons item out))))
      (else (reverse out)))))

(def (take* items count)
  (let lp ((rest items) (remaining count) (out '()))
    (cond
     ((or (null? rest) (fx<= remaining 0)) (reverse out))
       (else (lp (cdr rest) (fx1- remaining) (cons (car rest) out))))))

(def (join-lines lines)
  (let lp ((rest lines) (out ""))
    (match rest
      ([] out)
      ([line] (string-append out line))
      ([line . more] (lp more (string-append out line "\n"))))))

(def (flatten obj)
  (cond
   ((null? obj) '())
   ((pair? obj) (append (flatten (car obj)) (flatten (cdr obj))))
   (else [obj])))

(def (datum-list-items obj)
  (let lp ((rest obj) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((pair? rest) (lp (cdr rest) (cons (car rest) out)))
     (else (reverse out)))))

(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

(def (safe-cdr obj)
  (if (pair? obj) (cdr obj) '()))

(def (safe-cddr obj)
  (safe-cdr (safe-cdr obj)))

(def (safe-cdddr obj)
  (safe-cdr (safe-cddr obj)))

(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   (else (call-with-output-string "" (cut display obj <>)))))

(def (source-start-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-start-position loc))))
    1))

(def (source-end-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-end-position loc))))
    1))

(def (exception->string exn)
  (parameterize ((dump-stack-trace? #f))
    (call-with-output-string "" (cut display-exception exn <>))))

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
