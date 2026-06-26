;;; -*- Gerbil -*-
;;; Full-check cache boundary for the agent-facing check command.

(import :gerbil/gambit
        :constants
        (only-in :parser/facade +ignored-dirs+ collect-source-files)
        (only-in :parser/package read-project-package)
        (only-in :std/misc/list unique)
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar cut foldl with-catch))

(export check-cache-path
        check-cache-state
        read-check-cache
        check-cache-ref
        matching-check-cache
        write-check-cache
        emit-cached-check)

(def +check-cache-format-version+ "check-full-output-cache.v1")
(def +check-cache-version+ +release-version+)

(def +check-cache-provider-artifacts+
  '("src/commands/check.ssi"
    "src/commands/check-cache.ssi"
    "src/constants.ssi"
    "src/parser/facade.ssi"
    "src/parser/model.ssi"
    "src/policy/agent.ssi"
    "src/policy/agent-basic.ssi"
    "src/policy/core.ssi"))

(def +check-cache-fnv64-offset+ 14695981039346656037)
(def +check-cache-fnv64-prime+ 1099511628211)
(def +check-cache-fnv64-modulus+ 18446744073709551616)

;; : (-> String String)
(def (check-cache-dir root)
  (path-expand ".cache/agent-semantic-protocol/gerbil-scheme/check" root))

;; : (-> String String String)
(def (check-cache-path root mode)
  (path-expand (string-append mode ".sexp") (check-cache-dir root)))

;; : (-> String String)
(def (trim-trailing-slashes path)
  (let loop ((end (string-length path)))
    (if (and (> end 1)
             (char=? (string-ref path (- end 1)) #\/))
      (loop (- end 1))
      (substring path 0 end))))

;; : (-> String Void)
(def (ensure-directory* path)
  (when path
    (let (dir (trim-trailing-slashes path))
      (unless (or (string=? dir "")
                  (string=? dir ".")
                  (file-exists? dir))
        (let (parent (path-directory dir))
          (when (and parent
                     (not (string=? parent dir)))
            (ensure-directory* parent)))
        (unless (file-exists? dir)
          (create-directory dir))))))

;; : (-> Integer Integer Integer)
(def (check-cache-fnv64-step hash byte)
  (modulo (* (bitwise-xor hash byte) +check-cache-fnv64-prime+)
          +check-cache-fnv64-modulus+))

;; : (-> String Integer)
(def (check-cache-file-hash path)
  (call-with-input-file path
    (lambda (in)
      (let loop ((hash +check-cache-fnv64-offset+))
        (let (byte (read-u8 in))
          (if (eof-object? byte)
            hash
            (loop (check-cache-fnv64-step hash byte))))))))

;; : (-> String String (List Datum))
(def (check-cache-directory-fingerprint relpath path)
  ['directory
   (filter (lambda (entry)
             (check-cache-visible-directory-entry? relpath entry))
           (sort (directory-files path) string<?))])

;; : (-> String String Boolean)
(def (check-cache-visible-directory-entry? relpath entry)
  (not (or (member entry '("." ".."))
           (check-cache-ignored-directory-entry? relpath entry))))

;; : (-> String String Boolean)
(def (check-cache-ignored-directory-entry? relpath entry)
  (let (child (check-cache-child-relpath relpath entry))
    (or (member entry +ignored-dirs+)
        (member child +ignored-dirs+))))

;; : (-> String String String)
(def (check-cache-child-relpath relpath entry)
  (if (or (string=? relpath "")
          (string=? relpath ".")
          (string=? relpath "./"))
    entry
    (string-append relpath "/" entry)))

;; : (-> String String (List Datum))
(def (check-cache-file-fingerprint root path)
  (with-catch
   (lambda (_) [path 'missing])
   (lambda ()
     (let* ((fullpath (path-expand path root))
            (info (file-info fullpath)))
       (if (eq? (file-type fullpath) 'directory)
         (cons path (check-cache-directory-fingerprint path fullpath))
         [path
          'file
          (file-info-size info)
          (check-cache-file-hash fullpath)])))))

;; : (-> String (U #f String) (U #f Datum) (List Pair))
(def (check-cache-state root whitelist-path existing-cache)
  (let ((inputs (check-cache-ref existing-cache 'inputs))
        (directories (check-cache-ref existing-cache 'directories)))
    (if (and (list? inputs) (list? directories))
      (check-cache-state/from-inputs root inputs directories)
      (check-cache-state/from-source root whitelist-path))))

;; : (-> String (U #f String) (List Pair))
(def (check-cache-state/from-source root whitelist-path)
  (let* ((package (read-project-package root))
         (files (sort (map (cut check-cache-relative-input root <>)
                           (collect-source-files root package))
                      string<?))
         (inputs (sort (if whitelist-path
                         (cons (check-cache-relative-input root whitelist-path)
                               files)
                         files)
                       string<?))
         (directories (check-cache-input-directories inputs)))
    (check-cache-state/from-inputs root inputs directories)))

;; : (-> String)
(def (check-cache-user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to fingerprint Gerbil harness artifacts")))

;; : (-> String String)
(def (check-cache-provider-artifact-path relpath)
  (path-expand (string-append ".gerbil/lib/gslph/" relpath)
               (check-cache-user-home-directory)))

;; : (-> String Datum)
(def (check-cache-provider-artifact-fingerprint relpath)
  (let (path (check-cache-provider-artifact-path relpath))
    (with-catch
     (lambda (_) [relpath 'missing])
     (lambda ()
       (let (info (file-info path))
         [relpath
          'file
          (file-info-size info)
          (time->seconds (file-info-last-modification-time info))])))))

;; : (-> (List Datum))
(def (check-cache-provider-fingerprint)
  (map check-cache-provider-artifact-fingerprint
       +check-cache-provider-artifacts+))

;; : (-> String String String)
(def (check-cache-relative-input root path)
  (let* ((root* (trim-trailing-slashes (path-normalize root)))
         (path* (path-normalize path))
         (prefix (string-append root* "/")))
    (if (string-prefix? prefix path*)
      (substring path* (string-length prefix) (string-length path*))
      path*)))

;; : (-> String (List String) (List String) (List Pair))
(def (check-cache-state/from-inputs root inputs directories)
  (let (fingerprint
    (call-with-output-string ""
      (lambda (out)
        (write [version: +check-cache-version+
                formatVersion: +check-cache-format-version+
                provider: +provider-id+
                releaseVersion: +release-version+
                providerArtifacts: (check-cache-provider-fingerprint)
                mode: "source-inputs"
                inputs: (map (cut check-cache-file-fingerprint root <>) inputs)
                directories: (map (cut check-cache-file-fingerprint root <>) directories)]
               out))))
    (list (cons 'fingerprint fingerprint)
          (cons 'inputs inputs)
          (cons 'directories directories))))

;; : (-> (List String) (List String))
(def (check-cache-input-directories inputs)
  (sort (unique
         (foldl (lambda (path directories)
                  (append (check-cache-path-directories path) directories))
                []
                inputs))
        string<?))

;; : (-> String (List String))
(def (check-cache-path-directories path)
  (check-cache-directory-chain
   (trim-trailing-slashes (or (path-directory path) "."))
   []))

;; : (-> String (List String) (List String))
(def (check-cache-directory-chain dir directories)
  (cond
   ((check-cache-root-directory? dir)
    (cons "." directories))
   (else
    (check-cache-directory-parent-chain
     dir
     (trim-trailing-slashes (or (path-directory dir) "."))
     directories))))

;; : (-> String String (List String) (List String))
(def (check-cache-directory-parent-chain dir parent directories)
  (if (check-cache-root-directory? parent)
    (cons "." (cons dir directories))
    (check-cache-directory-chain parent (cons dir directories))))

;; : (-> String Boolean)
(def (check-cache-root-directory? dir)
  (or (string=? dir "")
      (string=? dir ".")
      (string=? dir "./")))

;; : (-> String (U #f Datum))
(def (read-check-cache cache-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (file-exists? cache-path)
          (call-with-input-file cache-path read)))))

;; : (-> Symbol (List Pair) (U #f Datum))
(def (check-cache-ref cache key)
  (let (entry (and (pair? cache) (assq key cache)))
    (and entry (cdr entry))))

;; : (-> Datum String (U #f Datum))
(def (matching-check-cache cache fingerprint)
  (and cache
       (equal? (check-cache-ref cache 'version) +check-cache-version+)
       (equal? (check-cache-ref cache 'formatVersion)
               +check-cache-format-version+)
       (equal? (check-cache-ref cache 'fingerprint) fingerprint)
       cache))

;; : (-> String (List Pair) Integer String Boolean)
(def (write-check-cache cache-path cache-state status output)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (ensure-directory* (path-directory cache-path))
     (call-with-output-file cache-path
       (lambda (out)
         (write (list (cons 'version +check-cache-version+)
                      (cons 'formatVersion +check-cache-format-version+)
                      (cons 'provider +provider-id+)
                      (cons 'releaseVersion +release-version+)
                      (cons 'fingerprint
                            (check-cache-ref cache-state 'fingerprint))
                      (cons 'inputs (check-cache-ref cache-state 'inputs))
                      (cons 'directories
                            (check-cache-ref cache-state 'directories))
                      (cons 'status status)
                      (cons 'output output))
                out)))
     #t)))

;; : (-> Datum Integer)
(def (emit-cached-check cache)
  (let ((output (check-cache-ref cache 'output))
        (status (check-cache-ref cache 'status)))
    (when output
      (display output))
    (if (integer? status) status 1)))
