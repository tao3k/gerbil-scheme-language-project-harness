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
	        form-datum-head
	        form-metadata-value
	        form-next-rest
	        safe-cadr
        safe-caddr
        safe-cdr
        safe-cddr
        safe-cdddr
        datum->string
        source-start-line
        source-end-line
        exception->string)
;; join-lines
;;   : (-> (List String) String)
;;   | doc m%
;;       `join-lines lines` joins source lines with newline separators.
;;
;;       # Examples
;;
;;       ```scheme
;;       (join-lines '("alpha" "beta"))
;;       ;; => "alpha\nbeta"
;;       ```
;;     %
(def (join-lines lines)
  (join lines "\n"))
;; : (-> Obj Flatten )
(def (flatten obj)
  (cond
   ((null? obj) '())
   ((pair? obj) (append (flatten (car obj)) (flatten (cdr obj))))
   (else [obj])))
;; : (-> Obj FlattenWithPairs )
(def (flatten-with-pairs obj)
  (cond
   ((null? obj) '())
   ((pair? obj)
    (cons obj (append (flatten-with-pairs (car obj))
                      (flatten-with-pairs (cdr obj)))))
   (else [obj])))
;; : (-> Obj Symbol Boolean )
(def (tree-contains-symbol? obj symbol)
  (member symbol (flatten obj)))
;; datum-list-items
;;   : (-> Obj (List Obj))
;;   | doc m%
;;       `datum-list-items obj` returns the proper-list prefix of a datum while
;;       preserving item order.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum-list-items '(a b . c))
;;       ;; => (a b)
;;       ```
;;     %
(def (datum-list-items obj)
  (let ((rest obj)
        (out '()))
    (while (pair? rest)
      (set! out (cons (car rest) out))
      (set! rest (cdr rest)))
    (reverse out)))
;; : (-> Obj Integer )
(def (stx-list-items obj)
  (cond
   ((not obj) '())
   ((stx-null? obj) '())
   ((stx-pair? obj)
    (cons (stx-car obj) (stx-list-items (stx-cdr obj))))
   (else '())))
;; drop*
;;   : (forall (a) (-> (List a) Integer (List a)))
;;   | doc m%
;;       `drop* items count` drops `count` elements when enough items exist,
;;       otherwise returns the empty list.
;;
;;       # Examples
;;
;;       ```scheme
;;       (drop* '(a b c) 2)
;;       ;; => (c)
;;       ```
;;     %
(def (drop* items count)
  (if (fx<= count (length items))
    (drop items count)
    '()))
;; list-safe-cadr
;;   : (forall (a) (-> (List a) (U #f a)))
;;   | doc m%
;;       `list-safe-cadr items` returns the second item of a list, or `#f` when
;;       the list is too short.
;;
;;       # Examples
;;
;;       ```scheme
;;       (list-safe-cadr '(a b c))
;;       ;; => b
;;       ```
;;     %
(def (list-safe-cadr items)
  (and (pair? items) (pair? (cdr items)) (cadr items)))
;; list-safe-caddr
;;   : (forall (a) (-> (List a) (U #f a)))
;;   | doc m%
;;       `list-safe-caddr items` returns the third item of a list, or `#f` when
;;       the list is too short.
;;
;;       # Examples
;;
;;       ```scheme
;;       (list-safe-caddr '(a b c))
;;       ;; => c
;;       ```
;;     %
(def (list-safe-caddr items)
  (and (pair? items) (pair? (cdr items)) (pair? (cddr items)) (caddr items)))
;; : (-> Head Boolean )
(def (metadata-head? head)
  (member head '(package package: prelude: namespace: import export include)))
;; : (-> Datum Head )
(def (form-datum-head datum)
  (cond
   ((pair? datum) (car datum))
   ((metadata-atom-datum? datum) datum)
   (else #f)))
;; : (-> Datum Boolean )
(def (metadata-atom-datum? datum)
  (member datum '(package: prelude: namespace:)))
;; : (-> Datum Rest MetadataValue )
(def (form-metadata-value datum rest)
  (cond
   ((pair? datum) (safe-cadr datum))
   ((and (metadata-atom-datum? datum) (pair? rest))
    (syntax->datum (car rest)))
   (else #f)))
;; : (-> Datum Rest Rest )
(def (form-next-rest datum rest)
  (if (and (metadata-atom-datum? datum) (pair? (cdr rest)))
    (cddr rest)
    (cdr rest)))
;; : (-> Obj SafeCadr )
(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))
;; : (-> Obj SafeCaddr )
(def (safe-caddr obj)
  (and (pair? obj) (pair? (cdr obj)) (pair? (cddr obj)) (caddr obj)))
;; : (-> Obj SafeCdr )
(def (safe-cdr obj)
  (if (pair? obj) (cdr obj) '()))
;; : (-> Obj SafeCddr )
(def (safe-cddr obj)
  (safe-cdr (safe-cdr obj)))
;; : (-> Obj SafeCdddr )
(def (safe-cdddr obj)
  (safe-cdr (safe-cddr obj)))
;; datum->string
;;   : (-> Obj (U #f String))
;;   | doc m%
;;       `datum->string obj` converts strings, symbols, keywords, and printable
;;       datums into source-facing string values.
;;
;;       # Examples
;;
;;       ```scheme
;;       (datum->string 'alpha)
;;       ;; => "alpha"
;;       ```
;;     %
(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))
;; : (-> Loc Integer )
(def (source-start-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-start-position loc))))
    1))
;; : (-> Loc Integer )
(def (source-end-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-end-position loc))))
    1))
;; exception->string
;;   : (-> Exn String)
;;   | doc m%
;;       `exception->string exn` renders an exception without dumping a stack
;;       trace into parser diagnostics.
;;
;;       # Examples
;;
;;       ```scheme
;;       (exception->string exn)
;;       ;; => diagnostic text
;;       ```
;;     %
(def (exception->string exn)
  (parameterize ((dump-stack-trace? #f))
    (call-with-output-string "" (cut display-exception exn <>))))
