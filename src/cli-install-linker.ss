;;; -*- Gerbil -*-
;;; Installed executable root for gslph.

(import :gerbil/gambit
        (only-in :commands/check check-main))
(export main)

;;; Install binary boundary:
;;; - `check` is static so class-heavy checker modules are initialized inside
;;;   the executable instead of loaded dynamically at runtime.
;;; - Hook selector reads stay as a tiny local fast path.
;;; - Other commands intentionally fail fast until they have a measured native
;;;   install need.

;; : String
(def +install-help+
  "gslph - Gerbil Scheme semantic search and project harness\n\nUsage:\n  gslph check [--changed|--full] [PROJECT_ROOT]\n  gslph query --from-hook direct-source-read --selector <path:start-end> [--workspace PROJECT_ROOT] [--json]\n  gslph --help\n\nThis installed binary keeps only measured native paths. Use source CLI for unsupported development commands.\n")

;; : (-> String (List String) (U String #f))
(def (option name args)
  (cond
   ((null? args) #f)
   ((equal? (car args) name)
    (and (pair? (cdr args)) (cadr args)))
   (else
    (option name (cdr args)))))

;; : (-> String (List String) Boolean)
(def (flag? name args)
  (and (member name args) #t))

;; : (-> String Boolean)
(def (absolute-path? path)
  (and (> (string-length path) 0)
       (char=? (string-ref path 0) #\/)))

;; : (-> String String String)
(def (join-path root path)
  (cond
   ((absolute-path? path) path)
   ((or (equal? root ".") (equal? root "")) path)
   (else (string-append root "/" path))))

;; : (-> Selector SelectorParts)
(def (split-selector selector)
  (let (ix (string-rindex selector #\:))
    (if ix
      (let* ((path (substring selector 0 ix))
             (range (substring selector (fx1+ ix) (string-length selector)))
             (dash (string-index range #\-)))
        (if dash
          [path
           (string->number (substring range 0 dash))
           (string->number (substring range (fx1+ dash) (string-length range)))]
          (let* ((prev (string-rindex path #\:))
                 (start-text (and prev (substring path (fx1+ prev) (string-length path))))
                 (start (and start-text (string->number start-text)))
                 (end (string->number range)))
            (if (and prev start end)
              [(substring path 0 prev) start end]
              [path end end]))))
      [selector #f #f])))

;; : (-> Integer Integer Integer Boolean)
(def (line-in-range? line start end)
  (and (>= line start) (<= line end)))

;; : (-> String Integer Integer (List String))
(def (selected-lines text start end)
  (let (lines (string-split text #\newline))
    (filter-map (lambda (line-number line)
                  (and (line-in-range? line-number start end)
                       line))
                (iota (length lines) 1)
                lines)))

;; : (-> (List String) String)
(def (lines->source-projection lines)
  (if (null? lines)
    ""
    (string-append (string-join lines "\n") "\n")))

;; : (-> Path Integer Integer String)
(def (read-line-range path start end)
  (lines->source-projection
   (selected-lines (read-file-string path) start end)))

;; : (-> ProjectRoot Selector String)
(def (read-selector root selector)
  (let* ((parts (split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts))
         (source-path (join-path root path)))
    (if (and start end)
      (read-line-range source-path start end)
      (read-file-string source-path))))

;; : (-> (List String) Integer)
(def (emit-direct-source-query args)
  (let ((selector (option "--selector" args))
        (workspace (or (option "--workspace" args) ".")))
    (unless selector
      (error "direct-source-read requires --selector"))
    (let (code (read-selector workspace selector))
      (if (flag? "--json" args)
        (begin
          (display "{\"selector\":")
          (write selector)
          (display ",\"code\":")
          (write code)
          (displayln "}"))
        (display code))))
  0)

;; : (-> Integer Integer)
(def (emit-help status)
  (display +install-help+)
  status)

;; : (-> (List String) Boolean)
(def (help-args? args)
  (or (null? args)
      (and (null? (cdr args))
           (member (car args) '("-h" "--help" "help")))))

;; : (-> Args Integer)
(def (main . args)
  (cond
   ((help-args? args)
    (emit-help 0))
   ((and (pair? args)
         (equal? (car args) "query")
         (equal? (option "--from-hook" (cdr args)) "direct-source-read"))
    (emit-direct-source-query (cdr args)))
   ((and (pair? args)
         (equal? (car args) "check"))
    (check-main (cdr args)))
   (else
    (emit-help 2))))
