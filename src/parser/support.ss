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

(def (join-lines lines)
  (let lp ((rest lines) (out ""))
    (match rest
      ([] out)
      ([line] (string-append out line))
      ([line . more] (lp more (string-append out line "\n"))))))

(def (flatten obj)
  (cond
   ((null? obj) '())
   ((pair? obj) (append (flatten (car obj)) (flatten (cdr obj))))
   (else [obj])))

(def (flatten-with-pairs obj)
  (cond
   ((null? obj) '())
   ((pair? obj)
    (cons obj (append (flatten-with-pairs (car obj))
                      (flatten-with-pairs (cdr obj)))))
   (else [obj])))

(def (tree-contains-symbol? obj symbol)
  (member symbol (flatten obj)))

(def (datum-list-items obj)
  (let lp ((rest obj) (out '()))
    (cond
     ((null? rest) (reverse out))
     ((pair? rest) (lp (cdr rest) (cons (car rest) out)))
     (else (reverse out)))))

(def (stx-list-items obj)
  (cond
   ((not obj) '())
   ((stx-null? obj) '())
   ((stx-pair? obj)
    (cons (stx-car obj) (stx-list-items (stx-cdr obj))))
   (else '())))

(def (drop* items count)
  (let lp ((rest items) (remaining count))
    (cond
     ((null? rest) '())
     ((fx<= remaining 0) rest)
     (else (lp (cdr rest) (fx1- remaining))))))

(def (list-safe-cadr items)
  (and (pair? items) (pair? (cdr items)) (cadr items)))

(def (list-safe-caddr items)
  (and (pair? items) (pair? (cdr items)) (pair? (cddr items)) (caddr items)))

(def (metadata-head? head)
  (member head '(package package: prelude: namespace: import export include)))

(def (safe-cadr obj)
  (and (pair? obj) (pair? (cdr obj)) (cadr obj)))

(def (safe-caddr obj)
  (and (pair? obj) (pair? (cdr obj)) (pair? (cddr obj)) (caddr obj)))

(def (safe-cdr obj)
  (if (pair? obj) (cdr obj) '()))

(def (safe-cddr obj)
  (safe-cdr (safe-cdr obj)))

(def (safe-cdddr obj)
  (safe-cdr (safe-cddr obj)))

(def (datum->string obj)
  (cond
   ((not obj) #f)
   ((string? obj) obj)
   ((symbol? obj) (symbol->string obj))
   ((keyword? obj) (string-append (keyword->string obj) ":"))
   (else (call-with-output-string "" (cut display obj <>)))))

(def (source-start-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-start-position loc))))
    1))

(def (source-end-line loc)
  (if (##locat? loc)
    (fx1+ (##filepos-line (##position->filepos (##locat-end-position loc))))
    1))

(def (exception->string exn)
  (parameterize ((dump-stack-trace? #f))
    (call-with-output-string "" (cut display-exception exn <>))))
