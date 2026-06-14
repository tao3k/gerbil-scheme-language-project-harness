;;; -*- Gerbil -*-
;;; Shared parser support helpers for Gerbil syntax facts.

(import :gerbil/expander
        :gerbil/gambit
        :support/list)

(export dedupe
        take*
        join-lines
        flatten
        flatten-with-pairs
        tree-contains-symbol?
        datum-list-items
        stx-list-items
        drop*
        list-safe-cadr
        list-safe-caddr
        metadata-head?
        safe-cadr
        safe-caddr
        safe-cdr
        safe-cddr
        safe-cdddr
        datum->string
        source-start-line
        source-end-line
        exception->string)
;;; Invariant:
;;; - join-lines owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List String) <- (List String)
(def (join-lines lines)
  (join lines "\n"))
;; Flatten <- Obj
(def (flatten obj)
  (cond
   ((null? obj) '())
   ((pair? obj) (append (flatten (car obj)) (flatten (cdr obj))))
   (else [obj])))
;; FlattenWithPairs <- Obj
(def (flatten-with-pairs obj)
  (cond
   ((null? obj) '())
   ((pair? obj)
    (cons obj (append (flatten-with-pairs (car obj))
                      (flatten-with-pairs (cdr obj)))))
   (else [obj])))
;; Boolean <- Obj Symbol
(def (tree-contains-symbol? obj symbol)
  (member symbol (flatten obj)))
;;; Invariant:
;;; - datum-list-items owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- Obj
(def (datum-list-items obj)
  (let ((rest obj)
        (out '()))
    (while (pair? rest)
      (set! out (cons (car rest) out))
      (set! rest (cdr rest)))
    (reverse out)))
;; Integer <- Obj
(def (stx-list-items obj)
  (cond
   ((not obj) '())
   ((stx-null? obj) '())
   ((stx-pair? obj)
    (cons (stx-car obj) (stx-list-items (stx-cdr obj))))
   (else '())))
;;; Boundary:
;;; - drop* delegates to Gerbil's sequence helper.
;;; - Keep the project-local name as the parser-facing compatibility contract.
;; Drop <- (List XX) Integer
(def (drop* items count)
  (if (fx<= count (length items))
    (drop items count)
    '()))
;; ListSafeCadr <- (List XX)
(def (list-safe-cadr items)
  (and (pair? items) (pair? (cdr items)) (cadr items)))
;; ListSafeCaddr <- (List XX)
(def (list-safe-caddr items)
  (and (pair? items) (pair? (cdr items)) (pair? (cddr items)) (caddr items)))
;; Boolean <- Head
(def (metadata-head? head)
  (member head '(package package: prelude: namespace: import export include)))
;; SafeCadr <- Obj
(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))
;; SafeCaddr <- Obj
(def (safe-caddr obj)
  (and (pair? obj) (pair? (cdr obj)) (pair? (cddr obj)) (caddr obj)))
;; SafeCdr <- Obj
(def (safe-cdr obj)
  (if (pair? obj) (cdr obj) '()))
;; SafeCddr <- Obj
(def (safe-cddr obj)
  (safe-cdr (safe-cdr obj)))
;; SafeCdddr <- Obj
(def (safe-cdddr obj)
  (safe-cdr (safe-cddr obj)))
;;; Boundary:
;;; - datum->string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Obj
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))
;; Integer <- Loc
(def (source-start-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-start-position loc))))
    1))
;; Integer <- Loc
(def (source-end-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-end-position loc))))
    1))
;;; Boundary:
;;; - exception->string composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Exn
(def (exception->string exn)
  (parameterize ((dump-stack-trace? #f))
    (call-with-output-string "" (cut display-exception exn <>))))
