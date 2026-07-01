;;; -*- Gerbil -*-
;;; Import-form resolution for selected gxtest source closure.

;;; Boundary:
;;; - This module translates Gerbil import syntax into package-relative source
;;;   files.
;;; - It does not walk transitive closure, build selected files, or decide
;;;   runner scheduling.

(import (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar filter-map hash-get hash-key? hash-put!)
        (only-in "./gxtest-context"
                 package-root
                 gxtest-normalize-module-path)
        (only-in "./gxtest-syntax"
                 gxtest-file-forms
                 gxtest-file-exported-suite?
                 gxtest-file-self-running?)
        :gerbil/gambit)

(export compiled-in-process-gxtest-file?
        gxtest-import-files
        gxtest-source-file-import-list)

;; CompileSafetyCache
(def +gxtest-import-closure-relative-import-cache+
  (make-hash-table))

;; : (-> (-> Value Boolean) (List Value) Boolean)
(def (gxtest-any? proc values)
  (if (find proc values) #t #f))

;; : (-> Datum Procedure List List)
(def (gxtest-datum-leaves/fold datum keep? out)
  (match datum
    ([head . rest]
     (gxtest-datum-leaves/fold
      head
      keep?
      (gxtest-datum-leaves/fold rest keep? out)))
    (else
     (if (keep? datum)
       (cons datum out)
       out))))

;; : (-> Datum Procedure List)
(def (gxtest-datum-leaves datum keep?)
  (gxtest-datum-leaves/fold datum keep? []))

;; : (-> Datum (List Symbol))
(def (gxtest-import-symbols datum)
  (gxtest-datum-leaves datum symbol?))

;; : (-> Datum (List String))
(def (gxtest-import-strings datum)
  (gxtest-datum-leaves datum string?))

;; : (-> String Path)
(def (gxtest-module-relpath module-path)
  (string-append module-path ".ss"))

;; : (-> Path Path Path)
(def (gxtest-module-candidate-path prefix relpath)
  (if (string-prefix? prefix relpath)
    relpath
    (path-expand relpath prefix)))

;; : (-> Path Path MaybePath)
(def (gxtest-existing-module-path test-path source-path)
  (or (and (file-exists? test-path) test-path)
      (and (file-exists? source-path) source-path)))

;; : (-> String MaybePath)
(def (gxtest-module-path-file module-path)
  (let* ((relpath (gxtest-module-relpath module-path))
         (test-path (gxtest-module-candidate-path "t/" relpath))
         (source-path (gxtest-module-candidate-path "src/" relpath)))
    (gxtest-existing-module-path test-path source-path)))

;; : (-> Symbol MaybePath)
(def (gxtest-module-symbol-file symbol)
  (let (name (symbol->string symbol))
    (and (string-prefix? ":" name)
         (gxtest-module-path-file
          (gxtest-normalize-module-path
           (substring name 1 (string-length name)))))))

;; : (-> Datum (List Path))
(def (gxtest-import-files form)
  (if (and (pair? form)
           (eq? (car form) 'import))
    (filter-map gxtest-module-symbol-file
                (gxtest-import-symbols (cdr form)))
    []))

;; : (-> Datum Boolean)
(def (gxtest-relative-import-string? value)
  (and (string? value)
       (or (string-prefix? "./" value)
           (string-prefix? "../" value))))

;; : (-> Path Path)
(def (gxtest-ss-path path)
  (if (string-suffix? ".ss" path)
    path
    (string-append path ".ss")))

;; : (-> Path Path)
(def (gxtest-package-relative-path path)
  (let* ((root (path-normalize (path-expand package-root)))
         (prefix (if (string-suffix? "/" root)
                   root
                   (string-append root "/"))))
    (if (string-prefix? prefix path)
      (substring path (string-length prefix) (string-length path))
      path)))

;; : (-> Path String Path)
(def (gxtest-relative-import-path owner import-path)
  (let* ((owner-path (path-expand owner package-root))
         (base (or (path-directory owner-path) package-root))
         (path (path-normalize (path-expand import-path base))))
    (gxtest-package-relative-path (gxtest-ss-path path))))

;; : (-> Path String MaybePath)
(def (gxtest-relative-import-file owner import-path)
  (and (gxtest-relative-import-string? import-path)
       (let (path (gxtest-relative-import-path owner import-path))
         (and (file-exists? (path-expand path package-root))
              path))))

;; : (-> Path Boolean)
(def (gxtest-compilable-relative-import-file? path)
  (or (string-prefix? "src/" path)
      (and (string-prefix? "t/" path)
           (not (string-prefix? "t/scenarios/" path)))))

;; : (-> Path String Boolean)
(def (gxtest-relative-import-compilable? owner import-path)
  (let (path (gxtest-relative-import-file owner import-path))
    (and path
         (gxtest-compilable-relative-import-file? path))))

;; : (-> Path Datum (List Path))
(def (gxtest-relative-import-files owner form)
  (if (and (pair? form)
           (eq? (car form) 'import))
    (filter-map (lambda (import-path)
                  (and (gxtest-relative-import-compilable? owner import-path)
                       (gxtest-relative-import-file owner import-path)))
                (gxtest-import-strings (cdr form)))
    []))

;; : (-> Path Datum Boolean)
(def (gxtest-unsafe-relative-import-form? owner form)
  (and (pair? form)
       (eq? (car form) 'import)
       (gxtest-any?
        (lambda (import-path)
          (and (gxtest-relative-import-string? import-path)
               (not (gxtest-relative-import-compilable? owner import-path))))
        (gxtest-import-strings (cdr form)))))

;; : (-> Path Boolean)
(def (gxtest-file-relative-import? file)
  (gxtest-any? (lambda (form)
                 (gxtest-unsafe-relative-import-form? file form))
               (gxtest-file-forms file)))

;; : (-> Path Boolean)
(def (compiled-in-process-gxtest-file? file)
  (and (gxtest-file-exported-suite? file)
       (not (gxtest-file-self-running? file))
       (not (gxtest-import-closure-relative-import? file []))))

;; : (-> Path (List Path) Boolean)
(def (gxtest-import-closure-relative-import? file seen)
  (and (not (member file seen))
       (if (hash-key? +gxtest-import-closure-relative-import-cache+ file)
         (hash-get +gxtest-import-closure-relative-import-cache+ file)
         (let (result
               (or (gxtest-file-relative-import? file)
                   (gxtest-any?
                    (lambda (import-file)
                      (gxtest-import-closure-relative-import?
                       import-file
                       (cons file seen)))
                    (gxtest-source-file-import-list file))))
           (hash-put! +gxtest-import-closure-relative-import-cache+
                      file
                      result)
           result))))

;; : (-> Path (List Path))
(def (gxtest-source-file-import-list file)
  (with-catch
   (lambda (_) [])
   (lambda ()
     (if (file-exists? (path-expand file package-root))
       (append-map (lambda (form)
                     (append (gxtest-import-files form)
                             (gxtest-relative-import-files file form)))
                   (gxtest-file-forms file))
       []))))
