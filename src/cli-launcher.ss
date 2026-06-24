;;; -*- Gerbil -*-
;;; Native launcher for per-command Gerbil Scheme harness executables.

(import :gerbil/gambit
        (only-in :constants +help+)
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/misc/path path-directory path-expand)
        (only-in :std/misc/ports read-all-as-string)
        (only-in :std/misc/process process-status run-process)
        (only-in :std/srfi/13 string-index string-index-right))
(export main
        command-line-args
        provider-command-line-args)

;;; Install boundary:
;;; - The native launcher is the command boundary. It dispatches only
;;;   in-process fast paths or installed sibling binaries.
;;; - Command binaries are discovered only beside the active launcher so an
;;;   installed harness is self-contained under its bin directory.
;; : (List (Pair String String))
(def +command-binaries+
  '(("query" . "gslph-query")
    ("check" . "gslph-check")
    ("bench" . "gslph-bench")
    ("evidence" . "gslph-evidence")
    ("agent" . "gslph-agent")
    ("guide" . "gslph-guide")
    ("info" . "gslph-info")))

;; : (List String)
(def +commands+
  '("search" "query" "check" "bench" "evidence" "agent" "guide" "info"
    "help" "-h" "--help"))

;; : (List String)
(def +launcher-names+
  '("gxi" "gslph"))

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
      (launcher-binary-path? arg)))

;; : (-> String Boolean)
(def (launcher-name? arg)
  (member arg +launcher-names+))

;; : (-> String Boolean)
(def (launcher-binary-path? arg)
  (or (string-suffix? "/gxi" arg)
      (string-suffix? "/gslph" arg)))

;; : (-> String (U String #f))
(def (command-binary-name command)
  (let (entry (assoc command +command-binaries+))
    (and entry (cdr entry))))

;;; Path boundary:
;;; - No PATH probing happens here; PATH remains the caller's concern at the
;;;   install-wrapper level.
;; : (-> String String)
(def (sibling-binary-path binary-name)
  (path-expand binary-name (path-directory (car (command-line)))))

;;; Process boundary:
;;; - Invoke Gerbil directly with argv vectors. Do not construct a shell command;
;;;   command arguments are data all the way to the child process.
;;; - Capture and replay stdout/stderr through Gerbil ports so the launcher can
;;;   return the child status while preserving command output for hooks/tests.
;; : (-> (List String) Integer)
(def (run-process/relay argv)
  (run-process argv
               stdin-redirection: #f
               stdout-redirection: #t
               stderr-redirection: #t
               check-status: #f
               coprocess:
               (lambda (process)
                 (let (output (read-all-as-string process))
                   (display output)
                   (process-status process)))))

;;; Binary dispatch:
;;; - Sibling command binaries receive only the subcommand tail because their
;;;   executable name already identifies the command owner.
;; : (-> String (List String) Integer)
(def (run-command-binary binary args)
  (run-process/relay (cons binary args)))

;;; Public CLI:
;;; - Help stays in-process so `gslph --help` has no startup dependency on the
;;;   command graph.
;;; - Subcommands are handled by native launcher fast paths or sibling native
;;;   binaries. Missing native coverage is a hard install/build error.
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
       (equal? (launcher-option "--from-hook" rest) "direct-source-read")
       (let (selector (launcher-option "--selector" rest))
         (unless selector
           (error "direct-source-read requires --selector"))
         (emit-native-direct-source-query rest selector)
         0)))

;; : (-> String (List String) (U String #f))
(def (launcher-option name args)
  (cond
   ((null? args) #f)
   ((equal? (car args) name)
    (and (pair? (cdr args)) (cadr args)))
   (else
    (launcher-option name (cdr args)))))

;; : (-> String (List String) Boolean)
(def (launcher-flag? name args)
  (and (member name args) #t))

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

;; : (-> String Integer Integer String)
(def (launcher-read-line-range path start end)
  (call-with-input-file path
    (lambda (port)
      (let loop ((line 1)
                 (out ""))
        (if (> line end)
          out
          (let (text (read-line port))
            (if (eof-object? text)
              out
              (loop (fx1+ line)
                    (if (and (>= line start) (<= line end))
                      (string-append out text "\n")
                      out)))))))))

;; : (-> String (List String) Integer)
(def (dispatch-native-command command rest)
  (if (member command +commands+)
    (or (try-sibling-command-binary command rest)
        (emit-missing-command-binary command))
    (emit-help 2)))

;; : (-> String Integer)
(def (emit-missing-command-binary command)
  (let (binary-name (command-binary-name command))
    (if binary-name
      (let (binary (sibling-binary-path binary-name))
        (displayln "gslph native command binary missing: " binary
                   ". Rebuild or install the Gerbil harness native binaries; source execution is disabled."))
      (displayln "gslph native command is not implemented: " command))
    2))

;; : (-> String (List String) (U Integer #f))
(def (try-sibling-command-binary command rest)
  (let (binary-name (command-binary-name command))
    (and binary-name
         (let (binary (sibling-binary-path binary-name))
           (and (file-exists? binary)
                (run-command-binary binary rest))))))

;; : (-> (List String) Integer)
(def (main . args)
  (cond
   ((help-args? args)
    (emit-help 0))
   ((pair? args)
    (dispatch-command (car args) (cdr args)))
   (else
    (emit-help 2))))
