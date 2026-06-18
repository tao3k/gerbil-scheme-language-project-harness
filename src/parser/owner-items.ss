;;; -*- Gerbil -*-
;;; Lightweight parser surface for owner-items.

(import :gerbil/expander
        :gerbil/gambit
        :parser/exports
        :parser/model
        :parser/selectors
        :parser/support
        :parser/syntax
        (only-in :std/misc/list unique)
        (only-in :std/misc/ports open-output-string read-file-lines)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-join
                 string-prefix?
                 string-trim)
        (only-in :std/sugar cut filter hash))

(export owner-items-source-path?
        parse-owner-items-source-file
        owner-items-syntax-fact-json
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
        source-file-parse-error
        definition-name
        definition-kind
        definition-path
        definition-start
        definition-end
        definition-formals
        definition-arity
        definition-selector)

;; (List FileExtension)
(def +owner-items-source-extensions+ '(".ss" ".ssi" ".scm" ".sld"))
;; (List ConfigFileName)
(def +owner-items-config-files+ '("gerbil.pkg" "build.ss"))

;; : (-> Path Boolean )
(def (owner-items-source-path? path)
  (or (member (path-extension path) +owner-items-source-extensions+)
      (member (path-strip-directory path) +owner-items-config-files+)))

;;; Parse boundary:
;;; - Owner-items needs a lightweight SourceFile without the full project walk.
;;; - Native forms, definitions, calls, imports, and top-forms are collected in
;;;   one pass so CLI owner browsing stays cheap and parser-owned.
;; : (-> ProjectRoot OwnerPath SourceFile )
(def (parse-owner-items-source-file root path)
  (let* ((fullpath (source-full-path root path))
         (relpath (relative-path root fullpath))
         (line-count (owner-source-line-count fullpath))
         (read-result (owner-read-native-forms fullpath))
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
          (module-exports '()))
      (while (pair? rest)
        (let* ((form (car rest))
               (datum (syntax->datum form))
               (head (form-datum-head datum))
               (metadata-value (form-metadata-value datum (cdr rest)))
               (next-rest (form-next-rest datum rest))
               (top-form (top-form-from relpath form datum))
               (next-calls (append (calls-from-form relpath form datum) calls)))
          (set! top-forms (cons top-form top-forms))
          (cond
           ((eq? head 'package:)
            (set! package (datum->string metadata-value)))
           ((eq? head 'prelude:)
            (set! prelude (datum->string metadata-value)))
           ((eq? head 'namespace:)
            (set! namespace (datum->string metadata-value)))
           ((eq? head 'import)
            (set! imports (append (module-refs datum) imports))
            (set! module-imports
              (append (module-import-facts-from-form relpath form)
                      module-imports)))
           ((eq? head 'export)
            (set! exports (append (export-symbols datum) exports))
            (set! module-exports
              (append (module-export-facts-from-form relpath form)
                      module-exports)))
           ((eq? head 'include)
            (set! includes (append (string-datums datum) includes)))
           ((member head +definition-heads+)
            (set! definitions
              (append (definitions-from-form relpath form datum) definitions))
            (set! calls next-calls))
           (else
            (set! calls next-calls)))
          (set! rest next-rest)))
      (make-source-file relpath line-count package prelude namespace
                        (unique imports)
                        (unique exports)
                        (unique includes)
                        (reverse definitions)
                        (reverse calls)
                        (reverse top-forms)
                        (reverse module-imports)
                        (reverse module-exports)
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        '()
                        parse-error))))

;;; Syntax projection:
;;; - Owner-items exposes imports, exports, calls, and top forms in one stream.
;;; - Stable sorting below keeps agent-visible output deterministic.
;; : (-> SourceFile (List SyntaxFactJson) )
(def (owner-items-syntax-fact-json file)
  (stable-owner-items-syntax-facts
   (append
    (map owner-module-import-fact-json (source-file-module-imports file))
    (map owner-module-export-fact-json (source-file-module-exports file))
    (map owner-call-fact-json (source-file-calls file))
    (map owner-top-form-fact-json (source-file-forms file)))))

;;; Stability boundary:
;;; - Syntax facts may be gathered from several parser surfaces.
;;; - Sorting by synthetic id prevents output churn when collection order moves.
;; : (-> (List SyntaxFactJson) (List SyntaxFactJson) )
(def (stable-owner-items-syntax-facts facts)
  (sort facts
        (lambda (a b)
          (string<? (hash-get a 'id) (hash-get b 'id)))))

;; : (-> ModuleImportFact SyntaxFactJson )
(def (owner-module-import-fact-json fact)
  (hash (id (owner-syntax-fact-id "import"
                                   (module-import-fact-path fact)
                                   (module-import-fact-module fact)
                                   (module-import-fact-start fact)))
        (kind "import")
        (source "native-parser")
        (languageKind "module-import")
        (name (module-import-fact-module fact))
        (ownerPath (module-import-fact-path fact))
        (location (owner-fact-location-json (module-import-fact-path fact)
                                            (module-import-fact-start fact)
                                            (module-import-fact-end fact)))
        (queryKeys (unique [(module-import-fact-module fact)
                            (module-import-fact-modifier fact)
                            (module-import-fact-phase fact)
                            (module-import-fact-path fact)]))
        (fields (hash (role "")
                      (phase (module-import-fact-phase fact))
                      (modifier (module-import-fact-modifier fact))
                      (symbols (module-import-fact-symbols fact))
                      (alias (or (module-import-fact-alias fact) ""))))))

;; : (-> ModuleExportFact SyntaxFactJson )
(def (owner-module-export-fact-json fact)
  (hash (id (owner-syntax-fact-id "export"
                                  (module-export-fact-path fact)
                                  (module-export-fact-name fact)
                                  (module-export-fact-start fact)))
        (kind "export")
        (source "native-parser")
        (languageKind "module-export")
        (name (module-export-fact-name fact))
        (ownerPath (module-export-fact-path fact))
        (location (owner-fact-location-json (module-export-fact-path fact)
                                            (module-export-fact-start fact)
                                            (module-export-fact-end fact)))
        (queryKeys (unique [(module-export-fact-name fact)
                            (module-export-fact-modifier fact)
                            (or (module-export-fact-alias fact) "")
                            (or (module-export-fact-module fact) "")
                            (module-export-fact-path fact)]))
        (fields (hash (role "")
                      (modifier (module-export-fact-modifier fact))
                      (symbols (module-export-fact-symbols fact))
                      (alias (or (module-export-fact-alias fact) ""))
                      (module (or (module-export-fact-module fact) ""))))))

;; : (-> CallFact SyntaxFactJson )
(def (owner-call-fact-json fact)
  (hash (id (owner-syntax-fact-id "call"
                                  (call-fact-path fact)
                                  (call-fact-callee fact)
                                  (call-fact-start fact)))
        (kind "call")
        (source "native-parser")
        (languageKind "call")
        (name (call-fact-callee fact))
        (ownerPath (call-fact-path fact))
        (location (owner-fact-location-json (call-fact-path fact)
                                            (call-fact-start fact)
                                            (call-fact-end fact)))
        (queryKeys (unique [(call-fact-callee fact)
                            (or (call-fact-caller fact) "")
                            (call-fact-path fact)]))
        (fields (hash (role "")
                      (caller (or (call-fact-caller fact) ""))
                      (arity (call-fact-arity fact))
                      (arguments (call-fact-arguments fact))))))

;; : (-> TopForm SyntaxFactJson )
(def (owner-top-form-fact-json fact)
  (hash (id (owner-syntax-fact-id "top-form"
                                  (top-form-path fact)
                                  (top-form-head fact)
                                  (top-form-start fact)))
        (kind "top-form")
        (source "native-parser")
        (languageKind (top-form-kind fact))
        (name (top-form-head fact))
        (ownerPath (top-form-path fact))
        (location (owner-fact-location-json (top-form-path fact)
                                            (top-form-start fact)
                                            (top-form-end fact)))
        (queryKeys (unique [(top-form-head fact)
                            (top-form-kind fact)
                            (top-form-path fact)]))
        (fields (hash (role (top-form-kind fact))))))

;; : (-> Kind Path Name Start String )
(def (owner-syntax-fact-id kind path name start)
  (string-append kind ":" path ":" name ":" (number->string start)))

;; : (-> Path Start End Json )
(def (owner-fact-location-json path start end)
  (hash (path path)
        (lineRange (string-append (number->string start)
                                  "-"
                                  (number->string end)))))

;;; Size boundary:
;;; - Line count is advisory owner metadata.
;;; - Read failures become zero so owner browsing can still show parse errors.
;; : (-> SourcePath Integer )
(def (owner-source-line-count path)
  (with-catch
   (lambda (_) 0)
   (lambda () (length (read-file-lines path)))))

;;; Read strategy:
;;; - Prefer core-read-module for ordinary Gerbil modules.
;;; - Fall back to syntax reading for #lang, custom preludes, config, and errors.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-native-forms path)
  (with-catch
   (lambda (exn)
     (vector '() (exception->string exn) #f #f #f))
   (lambda ()
     (if (member (path-extension path) +owner-items-source-extensions+)
       (if (owner-file-starts-with-lang? path)
         (owner-read-lang-syntax-forms path)
         (if (owner-file-has-non-core-prelude? path)
           (owner-read-syntax-forms path)
           (with-catch
            (lambda (_)
              (owner-read-syntax-forms path))
            (lambda ()
              (parameterize ((current-output-port (open-output-string))
                             (current-error-port (open-output-string)))
                (let (((values prelude module-id namespace body)
                       (core-read-module path)))
                  (vector body #f
                          (datum->string module-id)
                          (datum->string prelude)
                          (datum->string namespace))))))))
       (owner-read-syntax-forms path)))))

;;; Syntax fallback:
;;; - Suppress reader chatter so owner-items output remains protocol text.
;;; - Wrap single forms as a list to match core-read-module body shape.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-syntax-forms path)
  (parameterize ((current-output-port (open-output-string))
                 (current-error-port (open-output-string)))
    (let (body (read-syntax-from-file path))
      (vector (if (stx-list? body) (stx-map identity body) [body])
              #f #f #f #f))))

;;; #lang fallback:
;;; - Gerbil's module reader does not own non-Gerbil #lang headers.
;;; - Drop the language line and read the remaining body forms directly.
;; : (-> SourcePath OwnerReadResult )
(def (owner-read-lang-syntax-forms path)
  (let* ((lines (read-file-lines path))
         (body-text (string-join (cdr lines) "\n"))
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

;;; Header probe:
;;; - A failed file read should not block owner browsing.
;;; - The result only selects the lightweight read strategy above.
;; : (-> SourcePath Boolean )
(def (owner-file-starts-with-lang? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (let (lines (read-file-lines path))
       (and (pair? lines) (string-prefix? "#lang" (car lines)))))))

;;; Prelude probe:
;;; - Non-core preludes can break core-read-module in this standalone path.
;;; - The first lines are enough because package metadata lives at the top.
;; : (-> SourcePath Boolean )
(def (owner-file-has-non-core-prelude? path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ormap
      (lambda (line)
        (and (string-prefix? "prelude:" (string-trim line))
             (not (string-contains line ":gerbil/core"))))
      (let (lines (read-file-lines path))
        (take lines (min 12 (length lines))))))))
