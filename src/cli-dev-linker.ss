;;; -*- Gerbil -*-
;;; Development executable root for gslph.

(import :gerbil/gambit
        (only-in :commands/query query-main)
        (only-in :search-light-launcher try-search-light-main)
        (only-in :std/srfi/13 string-prefix?))

(export main)

;;; Dev binary boundary:
;;; - This root is a native fast-path artifact for hook selector reads and
;;;   lightweight search.
;;; - Full check/evidence command graphs belong to the release linker.

;; : String
(def +dev-help+
  "gslph - Gerbil Scheme semantic search and project harness\n\nUsage:\n  gslph query --selector <path:start-end> [--workspace PROJECT_ROOT] [--json]\n  gslph search rg-query <query> [--workspace PROJECT_ROOT] [--view seeds|hits]\n  gslph search fd-query <query> [--workspace PROJECT_ROOT] [--view seeds|hits]\n  gslph --help\n\nFull check/evidence commands are provided by the release linker.\n")

;; : (-> String (List String) (Maybe String))
(def (option name args)
  (cond
    ((null? args) #f)
    ((equal? (car args) name)
     (and (pair? (cdr args)) (cadr args)))
    (else (option name (cdr args)))))

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

;; : (-> SelectorText SelectorParts)
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
  (filter-map
   (lambda (line-number line)
     (and (line-in-range? line-number start end) line))
   (iota (length (string-split text #\newline)) 1)
   (string-split text #\newline)))

;; : (-> (List String) String)
(def (lines->source-projection lines)
  (if (null? lines)
    ""
    (string-append (string-join lines "\n") "\n")))

;; : (-> String Integer Integer String)
(def (read-line-range path start end)
  (lines->source-projection
   (selected-lines (read-file-string path) start end)))

;; : (-> String String String)
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
  (display +dev-help+)
  status)

;; : (-> (List String) Boolean)
(def (help-args? args)
  (or (null? args)
      (and (null? (cdr args))
           (member (car args) '("-h" "--help" "help")))))

;; : (-> (List String) Boolean)
(def (direct-source-query? args)
  (and (pair? args)
       (equal? (car args) "query")
       (or (option "--selector" (cdr args))
           (equal? (option "--from-hook" (cdr args)) "direct-source-read"))))

;; : (-> String Boolean)
(def (structural-selector? selector)
  (string-prefix? "gerbil-scheme://" selector))

;; : (-> String Boolean)
(def (direct-source-selector? selector)
  (and (not (structural-selector? selector))
       (or (string-index selector #\/)
           (string-index selector #\.)
           (string-index selector #\:))))

;; : (-> (List String) Boolean)
(def (direct-source-read-query? args)
  (let (selector (option "--selector" args))
    (and selector (direct-source-selector? selector))))

;; : (-> (List String) Integer)
(def (main . args)
  (cond
    ((help-args? args) (emit-help 0))
    ((and (pair? args) (equal? (car args) "search"))
     (or (try-search-light-main (cdr args))
         (emit-help 2)))
    ((and (direct-source-query? args)
          (direct-source-read-query? (cdr args)))
     (emit-direct-source-query (cdr args)))
    ((and (pair? args) (equal? (car args) "query"))
     (query-main (cdr args)))
    (else (emit-help 2))))
