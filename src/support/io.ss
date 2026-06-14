;;; -*- Gerbil -*-
;;; Source-range transport helpers.

(import :gerbil/gambit
        :parser/facade
        :std/misc/ports
        :std/srfi/13
        :std/sugar)

(export read-definition-code
        read-definition-with-leading-comments
        read-source-file-purpose-comment
        read-selector
        split-selector
        read-line-range)
;; ParsedData <- String Definition
(def (read-definition-code root defn)
  (read-line-range (path-expand (definition-path defn) root)
                   (definition-start defn)
                   (definition-end defn)))
;; ParsedData <- String Definition
(def (read-definition-with-leading-comments root defn)
  (let* ((path (path-expand (definition-path defn) root))
         (start (definition-leading-comment-start path
                                                  (definition-start defn))))
    (read-line-range path start (definition-end defn))))
;; ParsedData <- String Relpath
(def (read-source-file-purpose-comment root relpath)
  (let (comment (source-file-purpose-comment-line
                 (read-file-lines (path-expand relpath root))))
    (if comment
      (string-append comment "\n")
      "")))
;;; Boundary:
;;; - Stop at the first non-header line so purpose comments remain top-scoped.
;;; - Fold state records whether the scan is closed and the discovered comment.
;; String <- (List SourceFile)
(def (source-file-purpose-comment-line lines)
  (cdr
   (foldl (lambda (line state)
            (cond
             ((car state) state)
             ((or (string-prefix? ";;; -*-" line)
                  (string=? line ""))
              state)
             ((string-prefix? ";;;" line)
              (cons #t line))
             (else
              (cons #t #f))))
          (cons #f #f)
          lines)))
;;; Boundary:
;;; - Walk candidate line numbers backward and stop at the first non-comment.
;;; - Fold state keeps the current earliest adjacent comment line and closed flag.
;; Integer <- String Integer
(def (definition-leading-comment-start path start)
  (let* ((lines (read-file-lines path))
         (line-numbers (reverse (iota (fx1- start) 1)))
         (state
          (foldl (lambda (line state)
                   (if (car state)
                     state
                     (let (text (line-at lines line))
                       (if (definition-leading-comment-line? text)
                         (cons #f line)
                         (cons #t (cdr state))))))
                 (cons #f start)
                 line-numbers)))
    (cdr state)))
;; Boolean <- SourceLine
(def (definition-leading-comment-line? text)
  (and text
       (string-prefix? ";;" text)
       (not (string-prefix? ";;; -*-" text))))
;;; Boundary:
;;; - line-at keeps selector lines one-based at the call boundary.
;;; - Guard before list-ref so malformed selectors return #f instead of raising.
;; LineAt <- (List String) Target
(def (line-at lines target)
  (and (fx>= target 1)
       (fx<= target (length lines))
       (list-ref lines (fx1- target))))
;; Selector <- String String
(def (read-selector root selector)
  (let* ((parts (split-selector selector))
         (path (car parts))
         (start (cadr parts))
         (end (caddr parts)))
    (read-line-range (path-expand path root) start end)))
;; Selector <- String
(def (split-selector selector)
  (let* ((ix (string-index-right selector #\:))
         (path (substring selector 0 ix))
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
          [path end end])))))
;;; Boundary:
;;; - read-line-range composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; ParsedData <- String Integer Integer
(def (read-line-range path start end)
  (let (lines (read-file-lines path))
    (cdr
     (foldl (lambda (text state)
              (let ((line (car state))
                    (out (cdr state)))
                (cons (fx1+ line)
                      (if (and (>= line start) (<= line end))
                        (string-append out text "\n")
                        out))))
            (cons 1 "")
            lines))))
