(import :gerbil/expander
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 filter-map)
        (only-in :std/srfi/13 string-index string-prefix? string-suffix?)
        (only-in :std/sugar
                 hash
                 hash-get
                 hash-key?
                 hash-put!
                 hash-remove!)
        (only-in :std/text/json write-json)
        (only-in :gslph/src/parser/imports module-import-facts-from-form)
        (only-in :gslph/src/parser/model module-import-fact-module)
        (only-in :gslph/src/build-api/source-coverage
                 gslph-source-coverage-files))

(export gslph-component-names
        gslph-component-entry-files
        gslph-component-source-files
        gslph-component-receipt
        write-gslph-component-receipt)

(def +gslph-package-module-prefix+ ":gslph/")
(def +gslph-component-support-files+ '("build.ss" "gerbil.pkg"))
(def +gslph-component-entry-files+
  '((poo-flow
     "src/build-api/framework.ss"
     "src/build-api/source-coverage.ss"
     "src/building/observability.ss"
     "src/building/std-builder.ss"
     "src/policy/gxtest.ss")))

(def (component-name->symbol name)
  (cond
   ((symbol? name) name)
   ((string? name) (string->symbol name))
   (else (error "invalid GSLPH component name" name))))

(def (gslph-component-names)
  (map car +gslph-component-entry-files+))

(def (gslph-component-entry-files name)
  (let* ((component (component-name->symbol name))
         (entry (assq component +gslph-component-entry-files+)))
    (or (and entry (cdr entry))
        (error "unknown GSLPH component" component))))

(def (module-ref-without-fragment module-ref)
  (let (fragment-index (string-index module-ref #\#))
    (if fragment-index
      (substring module-ref 0 fragment-index)
      module-ref)))

(def (source-path-with-extension path)
  (if (string-suffix? ".ss" path)
    path
    (string-append path ".ss")))

(def (root-relative-path root path)
  (let* ((absolute-root (path-normalize root))
         (absolute-path (path-normalize path))
         (root-prefix (if (string-suffix? "/" absolute-root)
                        absolute-root
                        (string-append absolute-root "/"))))
    (if (string-prefix? root-prefix absolute-path)
      (substring absolute-path
                 (string-length root-prefix)
                 (string-length absolute-path))
      (error "GSLPH component dependency escapes the package root"
             absolute-path absolute-root))))

(def (relative-source-path root importer module-ref
                           add-extension?: (add-extension? #t))
  (let* ((module-path (module-ref-without-fragment module-ref))
         (resolved-path
          (path-expand (if add-extension?
                         (source-path-with-extension module-path)
                         module-path)
                       (path-directory (path-expand importer root)))))
    (root-relative-path root resolved-path)))

(def (gslph-internal-module-source-file root importer module-ref)
  (let (module-path (module-ref-without-fragment module-ref))
    (cond
     ((string-prefix? +gslph-package-module-prefix+ module-path)
      (source-path-with-extension
       (substring module-path
                  (string-length +gslph-package-module-prefix+)
                  (string-length module-path))))
     ((string-prefix? ":" module-path) #f)
     (else (relative-source-path root importer module-path)))))

(def (include-source-files root importer form)
  (let (datum (syntax->datum form))
    (if (and (pair? datum) (eq? (car datum) 'include))
      (map (lambda (path)
             (unless (string? path)
               (error "unsupported non-string Gerbil include" importer path))
             (relative-source-path root importer path add-extension?: #f))
           (cdr datum))
      '())))

(def (source-form-dependencies root source form)
  (cond
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'import))
    (filter-map
     (lambda (fact)
       (gslph-internal-module-source-file
        root source (module-import-fact-module fact)))
     (module-import-facts-from-form source form)))
   ((and (stx-pair? form) (eq? (stx-e (stx-car form)) 'include))
    (include-source-files root source form))
   (else '())))

(def (source-dependencies root source)
  (call-with-input-file
   (path-expand source root)
   (lambda (port)
     (let loop ((dependencies '()))
       (let (form (read-syntax port))
         (if (eof-object? form)
           (reverse dependencies)
           (loop (append (reverse (source-form-dependencies root source form))
                         dependencies))))))))

(def (gslph-component-closure root entries)
  (let ((visited (make-hash-table))
        (visiting (make-hash-table))
        (dependency-cache (make-hash-table))
        (ordered '()))
    (def (cached-source-dependencies source)
      (if (hash-key? dependency-cache source)
        (hash-get dependency-cache source)
        (let (dependencies (source-dependencies root source))
          (hash-put! dependency-cache source dependencies)
          dependencies)))
    (def (visit source stack)
      (cond
       ((hash-key? visited source) (void))
       ((hash-key? visiting source)
        (error "cyclic GSLPH component source dependency"
               (reverse (cons source stack))))
       (else
        (unless (file-exists? (path-expand source root))
          (error "missing GSLPH component source dependency" source stack))
        (hash-put! visiting source #t)
        (for-each (lambda (dependency)
                    (visit dependency (cons source stack)))
                  (cached-source-dependencies source))
        (hash-remove! visiting source)
        (hash-put! visited source #t)
        (set! ordered (cons source ordered)))))
    (for-each (lambda (entry) (visit entry '())) entries)
    (reverse ordered)))

(def (gslph-component-source-files name root: (root (current-directory)))
  (sort (gslph-component-closure root (gslph-component-entry-files name))
        string<?))

(def (gslph-component-receipt name root: (root (current-directory)))
  (let* ((component (component-name->symbol name))
         (entries (gslph-component-entry-files component))
         (sources (gslph-component-source-files component root: root))
         (module-sources
          (filter (lambda (path) (string-suffix? ".ss" path)) sources))
         (full-sources (gslph-source-coverage-files root))
         (strict-subset? (< (length module-sources) (length full-sources))))
    (unless strict-subset?
      (error "GSLPH component closure is not a strict package subset"
             component (length module-sources) (length full-sources)))
    (hash
     (schema "gslph.component-source-closure.v1")
     (outcome "valid")
     (component (symbol->string component))
     (entryFiles entries)
     (sourceFiles sources)
     (sourceCount (length sources))
     (fullSourceCount (length full-sources))
     (strictSubset strict-subset?)
     (supportFiles +gslph-component-support-files+))))

(def (write-gslph-component-receipt name root: (root (current-directory)))
  (write-json (gslph-component-receipt name root: root))
  (newline))
