;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
        (only-in :commands/bench-light bench-light-main)
        (only-in :constants +help+ +provider-id+ +release-version+)
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/misc/path directory-files path-expand path-normalize)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process run-process)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-contains string-index string-index-right string-prefix?)
        (only-in :std/sugar filter foldl ormap))
(export main
        command-line-args
        provider-command-line-args
        register-static-command-dispatch!)

;;; Install boundary:
;;; - The native launcher is the command boundary. It dispatches subcommands
;;;   in-process so an installed harness is one native executable.

;; : (List String)
(def +commands+
  '("search" "query" "check" "fmt" "bench" "evidence" "agent" "guide" "info"
    "help" "-h" "--help"))

;; : (List String)
(def +launcher-names+
  '("gxi" "gslph"))

;; : (List CommandDispatch)
(def +dynamic-command-dispatch+
  '(("search" "gslph/src/commands/search" gslph/src/commands/search#search-main)
    ("query" "gslph/src/commands/query" gslph/src/commands/query#query-main)
    ("check" "gslph/src/commands/check" gslph/src/commands/check#check-main)
    ("fmt" "gslph/src/commands/fmt" gslph/src/commands/fmt#fmt-main)
    ("evidence" "gslph/src/commands/evidence" gslph/src/commands/evidence#evidence-main)
    ("agent" "gslph/src/commands/agent" gslph/src/commands/agent#agent-main)
    ("guide" "gslph/src/commands/guide" gslph/src/commands/guide#guide-main)
    ("info" "gslph/src/commands/info" gslph/src/commands/info#info-main)))

(def static-command-dispatch [])

;; : (-> (List StaticCommandDispatch) Void)
(def (register-static-command-dispatch! entries)
  (set! static-command-dispatch entries))

(def +check-cache-format-version+ "check-full-output-cache.v3")
(def +check-cache-version+ +release-version+)

(def +launcher-check-cache-provider-artifacts+
  '("src/commands/check.ssi"
    "src/commands/check-cache.ssi"
    "src/constants.ssi"
    "src/parser/facade.ssi"
     "src/parser/model.ssi"
     "src/policy/agent.ssi"
     "src/policy/agent-basic.ssi"
     "src/policy/core.ssi"))

(def +launcher-check-cache-fnv64-offset+ 14695981039346656037)
(def +launcher-check-cache-fnv64-prime+ 1099511628211)
(def +launcher-check-cache-fnv64-modulus+ 18446744073709551616)

(def +launcher-check-cache-ignored-dirs+
  '(".devenv" ".git" ".cache" ".run" ".gerbil" "build" "dist" "target" "src/gambit" "tree-sitter"))

;;; Launcher argv boundary:
;;; - Keep this tiny normalization local so the release launcher does not
;;;   statically link the full command graph.
;; : (-> (List String) (List String))
(def (command-line-args argv)
  (or (command-line-command-tail argv)
      (strip-launcher-frames argv)))

;; : (-> (List String) (List String))
(def provider-command-line-args command-line-args)

;;; Argv search boundary:
;;; - Walk over wrapper frames until the first known command appears.
;;; - Returning the remaining tail preserves subcommand flags verbatim.
;; : (-> (List String) (Maybe (List String)))
(def (command-line-command-tail argv)
  (match argv
    ([] #f)
    ([arg . rest]
     (if (member arg +commands+)
       argv
       (command-line-command-tail rest)))))

;;; Launcher-frame boundary:
;;; - Strip only known interpreter and launcher frames from the front.
;;; - Stop at the first non-frame argument so user paths are not rewritten.
;; : (-> (List String) (List String))
(def (strip-launcher-frames argv)
  (match argv
    ([] [])
    ([arg . rest]
     (if (launcher-frame? arg)
       (strip-launcher-frames rest)
       argv))))

;; : (-> String Boolean)
(def (launcher-frame? arg)
  (or (launcher-name? arg)
      (launcher-binary-path? arg)
      (launcher-script-path? arg)))

;; : (-> String Boolean)
(def (launcher-name? arg)
  (member arg +launcher-names+))

;; : (-> String Boolean)
(def (launcher-binary-path? arg)
  (or (string-suffix? "/gxi" arg)
      (string-suffix? "/gslph" arg)))

;; : (-> String Boolean)
(def (launcher-script-path? arg)
  (or (equal? arg "src/cli.ss")
      (equal? arg "src/cli-launcher.ss")
      (string-suffix? "/src/cli.ss" arg)
      (string-suffix? "/src/cli-launcher.ss" arg)))

;;; Public CLI:
;;; - Help stays in-process so `gslph --help` has no startup dependency on the
;;;   command graph.
;;; - Subcommands are handled by native launcher fast paths or direct in-process
;;;   dispatch. Missing native coverage is a hard implementation error.
;; : (-> (List String) Boolean)
(def (help-args? args)
  (or (null? args)
      (and (null? (cdr args))
           (member (car args) '("-h" "--help" "help")))))

;; : (-> Integer Integer)
(def (emit-help status)
  (display +help+)
  status)

;; : (-> String (List String) Integer)
(def (dispatch-command command rest)
  (or (try-native-search-command command rest)
      (try-native-direct-source-query command rest)
      (try-native-check-cache-command command rest)
      (dispatch-native-command command rest)))

;; : (-> String (List String) (U Integer #f))
(def (try-native-search-command command rest)
  (and (equal? command "search")
       (try-search-light-main rest)))

;;; Direct query boundary:
;;; - Hook selector reads must be a native launcher fast path.
;;; - Do not import `:cli`; that pulls in parser/checker
;;;   modules before reading a small line range.
;; : (-> String (List String) (U Integer #f))
(def (try-native-direct-source-query command rest)
  (and (equal? command "query")
       (let ((from-hook (launcher-option "--from-hook" rest))
             (selector (launcher-option "--selector" rest)))
         (cond
          ((and from-hook
                (equal? from-hook "direct-source-read")
                (not selector))
           (error "direct-source-read requires --selector"))
          ((and selector (launcher-direct-source-selector? selector))
           (emit-native-direct-source-query rest selector)
           0)
          (else #f)))))

;; : (-> String (List String) (U String #f))
(def (launcher-option name args)
  (cond
   ((null? args) #f)
   ((equal? (car args) name)
    (and (pair? (cdr args)) (cadr args)))
   (else
    (launcher-option name (cdr args)))))

;; : (-> String Boolean)
(def (launcher-direct-source-selector? selector)
  (and (not (launcher-structural-selector? selector))
       (or (string-contains selector "/")
           (string-contains selector ".")
           (string-contains selector ":"))))

;; : (-> String Boolean)
(def (launcher-structural-selector? selector)
  (string-prefix? "gerbil-scheme://" selector))

;; : (-> String (List String) Boolean)
(def (launcher-flag? name args)
  (and (member name args) #t))

;;; Check cache fast path:
;;; - Full-check cache hits must not load the parser/checker command graph.
;;; - Cache misses fall through to dynamic `commands/check` dispatch.
;; : (-> String (List String) (U Integer #f))
(def (try-native-check-cache-command command rest)
  (and (equal? command "check")
       (or (try-native-removed-full-check rest)
           (try-native-empty-changed-check rest)
           (and (launcher-check-cache-eligible? rest)
                (let* ((root (path-normalize (path-expand (launcher-check-root rest))))
                       (mode (launcher-check-output-mode rest))
                       (cache-path (launcher-check-cache-path root mode))
                       (cache (launcher-read-check-cache cache-path)))
                  (and cache
                       (let* ((state (launcher-check-cache-state root cache))
                              (fingerprint (launcher-check-cache-ref state 'fingerprint))
                              (hit (launcher-matching-check-cache cache fingerprint)))
                         (and hit
                              (launcher-emit-cached-check hit)))))))))

;; : (-> (List String) (U Integer #f))
(def (try-native-removed-full-check args)
  (and (launcher-flag? "--full" args)
       (begin
         (displayln "[gerbil-check] status=error scope=full reason=removed-cli-full message=\"gslph check --full has been removed; use gxtest/library policy integration\"")
         2)))

;; : (-> (List String) (U Integer #f))
(def (try-native-empty-changed-check args)
  (and (launcher-empty-changed-check-eligible? args)
       (let (root (path-normalize (path-expand (launcher-check-root args))))
         (and (not (launcher-has-gerbil-changed-paths? root))
              (begin
                (displayln "[gerbil-check] status=pass scope=changed files=0 definitions=0 findings=0")
                0)))))

;; : (-> (List String) Boolean)
(def (launcher-empty-changed-check-eligible? args)
  (and (not (launcher-flag? "--full" args))
       (not (launcher-check-output-requested? args))
       (not (launcher-option "--whitelist" args))))

;; : (-> (List String) Boolean)
(def (launcher-changed-check-scope? args)
  (or (launcher-flag? "--changed" args)
      (launcher-flag? "changed" args)))

;; : (-> (List String) Boolean)
(def (launcher-check-output-requested? args)
  (ormap (lambda (flag) (launcher-flag? flag args))
         '("--json" "--profile-json" "--receipt-json")))

;; : (-> String Boolean)
(def (launcher-has-gerbil-changed-paths? root)
  (and (launcher-root-has-gerbil-source? root)
       (file-exists? (path-expand ".git" root))
       (not (string=? (launcher-git-output
                       root
                       ["git" "status" "--porcelain" "--untracked-files=all" "--"
                        ":(glob)**/*.ss"
                        ":(glob)**/*.scm"
                        ":(glob)**/gerbil.pkg"
                        "gerbil.pkg"])
                      ""))))

;; : (-> String Boolean)
(def (launcher-root-has-gerbil-source? root)
  (let loop ((relpath ".") (path root))
    (with-catch
     (lambda (_) #f)
     (lambda ()
       (ormap
        (lambda (entry)
          (and (launcher-check-cache-visible-directory-entry? relpath entry)
               (let* ((child-relpath (launcher-check-cache-child-relpath relpath entry))
                      (child-path (path-expand entry path)))
                 (or (launcher-gerbil-source-entry? entry)
                     (and (eq? (file-type child-path) 'directory)
                          (loop child-relpath child-path))))))
        (directory-files path))))))

;; : (-> String Boolean)
(def (launcher-gerbil-source-entry? entry)
  (or (string=? entry "gerbil.pkg")
      (launcher-string-suffix? entry ".ss")
      (launcher-string-suffix? entry ".scm")))

;; : (-> String String Boolean)
(def (launcher-string-suffix? text suffix)
  (let ((text-length (string-length text))
        (suffix-length (string-length suffix)))
    (and (>= text-length suffix-length)
         (string=? (substring text (- text-length suffix-length) text-length)
                   suffix))))

;; : (-> String (List String) String)
(def (launcher-git-output root command)
  (let (status 0)
    (with-catch
     (lambda (_) "")
     (lambda ()
       (let (output
             (run-process command
                          directory: root
                          stderr-redirection: #t
                          check-status:
                          (lambda (exit-status _settings)
                            (set! status exit-status))))
         (if (zero? status) output ""))))))

;; : (-> (List String) Boolean)
(def (launcher-check-cache-eligible? args)
  (and #f
       (not (launcher-flag? "--profile-json" args))
       (not (launcher-flag? "--changed" args))))

;; : (-> (List String) String)
(def (launcher-check-output-mode args)
  (if (launcher-flag? "--json" args) "json" "text"))

;; : (-> (List String) String)
(def (launcher-check-root args)
  (or (launcher-option "--workspace" args)
      (let (positionals (launcher-positionals args))
        (if (pair? positionals)
          (car (reverse positionals))
          "."))))

;; launcher-positionals
;;   : (-> (List String) (List String))
;;   | doc m%
;;       Return positional launcher arguments while skipping option values that
;;       belong to launcher-owned flags.
;;
;;       The fold state is `(skip-next? . reversed-positionals)` so option
;;       value skipping stays explicit without a handwritten accumulator loop.
;;
;;       # Examples
;;
;;       ```scheme
;;       (launcher-positionals '("--workspace" "." "src"))
;;       ;; => ("src")
;;       ```
;;     %
(def (launcher-positionals args)
  (reverse
   (cdr (foldl launcher-positionals-step (cons #f []) args))))

;; : (-> String PositionalsState PositionalsState)
(def (launcher-positionals-step arg state)
  (let ((skip-next? (car state))
        (out (cdr state)))
    (cond
     (skip-next?
      (cons #f out))
     ((member arg '("--workspace" "--whitelist"))
      (cons #t out))
     ((string-prefix? "-" arg)
      (cons #f out))
     (else
      (cons #f (cons arg out))))))

;; : (-> String String String)
(def (launcher-check-cache-path root mode)
  (path-expand (string-append mode ".sexp")
               (path-expand ".cache/agent-semantic-protocol/gerbil-scheme/check" root)))

;; : (-> Integer Integer Integer)
(def (launcher-check-cache-fnv64-step hash byte)
  (modulo (* (bitwise-xor hash byte) +launcher-check-cache-fnv64-prime+)
          +launcher-check-cache-fnv64-modulus+))

;; : (-> String Integer)
(def (launcher-check-cache-file-hash path)
  (call-with-input-file path
    (lambda (in)
      (let loop ((hash +launcher-check-cache-fnv64-offset+))
        (let (byte (read-u8 in))
          (if (eof-object? byte)
            hash
            (loop (launcher-check-cache-fnv64-step hash byte))))))))

;; : (-> String String (List Datum))
(def (launcher-check-cache-directory-fingerprint relpath path)
  ['directory
   (filter (lambda (entry)
             (launcher-check-cache-visible-directory-entry? relpath entry))
           (sort (directory-files path) string<?))])

;; : (-> String String Boolean)
(def (launcher-check-cache-visible-directory-entry? relpath entry)
  (not (or (member entry '("." ".."))
           (launcher-check-cache-ignored-directory-entry? relpath entry))))

;; : (-> String String Boolean)
(def (launcher-check-cache-ignored-directory-entry? relpath entry)
  (let (child (launcher-check-cache-child-relpath relpath entry))
    (or (member entry +launcher-check-cache-ignored-dirs+)
        (member child +launcher-check-cache-ignored-dirs+))))

;; : (-> String String String)
(def (launcher-check-cache-child-relpath relpath entry)
  (if (or (string=? relpath "")
          (string=? relpath ".")
          (string=? relpath "./"))
    entry
    (string-append relpath "/" entry)))

;; : (-> String String (List Datum))
(def (launcher-check-cache-file-fingerprint root path)
  (with-catch
   (lambda (_) [path 'missing])
   (lambda ()
     (let* ((fullpath (path-expand path root))
            (info (file-info fullpath)))
       (if (eq? (file-type fullpath) 'directory)
         (cons path (launcher-check-cache-directory-fingerprint path fullpath))
         [path
          'file
          (file-info-size info)
          (launcher-check-cache-file-hash fullpath)])))))

;; : (-> String)
(def (launcher-user-home-directory)
  (or (getenv "HOME" #f)
      (error "HOME is required to fingerprint Gerbil harness artifacts")))

;; : (-> String String)
(def (launcher-provider-artifact-path relpath)
  (path-expand (string-append ".gerbil/lib/gslph/" relpath)
               (launcher-user-home-directory)))

;; : (-> String Datum)
(def (launcher-provider-artifact-fingerprint relpath)
  (let (path (launcher-provider-artifact-path relpath))
    (with-catch
     (lambda (_) [relpath 'missing])
     (lambda ()
       (let (info (file-info path))
         [relpath
          'file
          (file-info-size info)
          (time->seconds (file-info-last-modification-time info))])))))

;; : (-> (List Datum))
(def (launcher-provider-fingerprint)
  (map launcher-provider-artifact-fingerprint
       +launcher-check-cache-provider-artifacts+))

;; : (-> String Datum (U #f (List Pair)))
(def (launcher-check-cache-state root cache)
  (let ((inputs (launcher-check-cache-ref cache 'inputs))
        (directories (launcher-check-cache-ref cache 'directories)))
    (and (list? inputs)
         (list? directories)
         (let (fingerprint
           (call-with-output-string ""
             (lambda (out)
               (write [version: +check-cache-version+
                       formatVersion: +check-cache-format-version+
                       provider: +provider-id+
                       releaseVersion: +release-version+
                       providerArtifacts: (launcher-provider-fingerprint)
                       mode: "source-inputs"
                       inputs: (map (lambda (path)
                                      (launcher-check-cache-file-fingerprint root path))
                                    inputs)
                       directories: (map (lambda (path)
                                           (launcher-check-cache-file-fingerprint root path))
                                         directories)]
                      out))))
           (list (cons 'fingerprint fingerprint))))))

;; : (-> String (U #f Datum))
(def (launcher-read-check-cache cache-path)
  (with-catch
   (lambda (_) #f)
   (lambda ()
     (and (file-exists? cache-path)
          (call-with-input-file cache-path read)))))

;; : (-> Datum Symbol (U #f Datum))
(def (launcher-check-cache-ref cache key)
  (let (entry (and (pair? cache) (assq key cache)))
    (and entry (cdr entry))))

;; : (-> Datum String (U #f Datum))
(def (launcher-matching-check-cache cache fingerprint)
  (and cache
       (equal? (launcher-check-cache-ref cache 'version) +check-cache-version+)
       (equal? (launcher-check-cache-ref cache 'formatVersion)
               +check-cache-format-version+)
       (equal? (launcher-check-cache-ref cache 'fingerprint) fingerprint)
       cache))

;; : (-> Datum Integer)
(def (launcher-emit-cached-check cache)
  (let ((output (launcher-check-cache-ref cache 'output))
        (status (launcher-check-cache-ref cache 'status)))
    (when output
      (display output))
    (if (integer? status) status 1)))

;; : (-> (List String) Selector Integer)
(def (emit-native-direct-source-query rest selector)
  (let* ((workspace (or (launcher-option "--workspace" rest) "."))
         (code (launcher-read-selector workspace selector)))
    (if (launcher-flag? "--json" rest)
      (begin
        (display "{\"selector\":")
        (write selector)
        (display ",\"code\":")
        (write code)
        (displayln "}"))
      (display code))))

;; : (-> String String String)
(def (launcher-read-selector root selector)
  (let* ((parts (launcher-split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts))
         (source-path (path-expand path root)))
    (if (and start end)
      (launcher-read-line-range source-path start end)
      (call-with-input-file source-path read-all-as-string))))

;; : (-> String SelectorParts)
(def (launcher-split-selector selector)
  (let (ix (string-index-right selector #\:))
    (if ix
      (let* ((path (substring selector 0 ix))
             (range (substring selector (fx1+ ix) (string-length selector)))
             (dash (string-index range #\-)))
        (if dash
          [path
           (string->number (substring range 0 dash))
           (string->number (substring range (fx1+ dash) (string-length range)))]
          (let* ((prev (string-index-right path #\:))
                 (start-text (and prev (substring path (fx1+ prev) (string-length path))))
                 (start (and start-text (string->number start-text)))
                 (end (string->number range)))
            (if (and prev start end)
              [(substring path 0 prev) start end]
              [path end end]))))
      [selector #f #f])))

;; launcher-read-line-range
;;   : (-> String Integer Integer String)
;;   | doc m%
;;       Read the inclusive one-based line range from `path`.
;;
;;       This is intentionally local to the launcher fast path so hook source
;;       reads do not import the full parser/check command graph.
;;
;;       # Examples
;;
;;       ```scheme
;;       (launcher-read-line-range "src/cli.ss" 1 2)
;;       ;; => first two source lines
;;       ```
;;     %
(def (launcher-read-line-range path start end)
  (call-with-input-file path
    (lambda (port)
      (call-with-output-string
       []
       (lambda (out)
         (let loop ((line 1))
           (unless (> line end)
             (let (text (read-line port))
               (unless (eof-object? text)
                 (when (and (>= line start) (<= line end))
                   (display text out)
                   (newline out))
                 (loop (fx1+ line)))))))))))

;; : (-> String (List String) Integer)
(def (dispatch-native-command command rest)
  (match command
    ("bench" (bench-light-main rest))
    (else (dispatch-dynamic-command command rest))))

;;; Dynamic dispatch boundary:
;;; - Hot commands stay in the launcher.
;;; - Cold/full commands load only after argv selects them, so `bench` and
;;;   native search cannot accidentally pay parser/checker startup cost.
;; : (-> String (List String) Integer)
(def (dispatch-dynamic-command command rest)
  (let (static-entry (find-dynamic-command command static-command-dispatch))
    (if static-entry
      ((cadr static-entry) rest)
      (let (entry (find-dynamic-command command +dynamic-command-dispatch+))
        (if entry
          (let (command-main
                (begin
                  (ensure-runtime-loader!)
                  (dynamic-command-main (cadr entry) (caddr entry))))
            (command-main rest))
          (emit-help 2))))))

;; : (-> String (List CommandDispatch) MaybeCommandDispatch)
(def (find-dynamic-command command entries)
  (match entries
    ([] #f)
    ([entry . more]
     (if (equal? command (car entry))
       entry
       (find-dynamic-command command more)))))

;; : (-> Unit)
(def (ensure-runtime-loader!)
  (##global-var-set! (##make-global-var 'load-module) load-module)
  (launcher-add-runtime-load-paths!))

;; : (-> Unit)
(def (launcher-add-runtime-load-paths!)
  (launcher-add-load-path! (path-expand ".gerbil/lib" (current-directory)))
  (launcher-add-load-path! (path-expand "lib" (gerbil-home)))
  (launcher-add-load-path! (path-expand "lib" (gerbil-path))))

;; : (-> Path Unit)
(def (launcher-add-load-path! path)
  (when (file-exists? path)
    (add-load-path! path)))

;; : (-> String Symbol Procedure)
(def (dynamic-command-main module-id binding-id)
  (load-module module-id)
  (eval binding-id))

;; : (-> (List String) Integer)
(def (main . args)
  (cond
   ((help-args? args)
    (emit-help 0))
   ((pair? args)
    (dispatch-command (car args) (cdr args)))
   (else
    (emit-help 2))))
