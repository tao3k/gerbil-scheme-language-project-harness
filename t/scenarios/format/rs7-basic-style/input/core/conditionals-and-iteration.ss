;;; -*- Gerbil -*-	
;;; Boundary: conditionals, cases, boolean forms, and simple iteration.  

(import :gerbil/gambit)  

(export classify-token
        count-selected)  

(def (classify-token token)
  (cond
   ((not token) 'missing)
   ((string? token)
    (case (string-length token)
      ((0) 'empty)
      ((1 2 3) 'short)
      (else 'long)))
   (else 'unknown)))  

(def (count-selected items predicate?)
  (let loop ((rest items)
             (total 0))
    (cond
     ((null? rest) total)
     ((and (pair? rest) (predicate? (car rest)))
      (loop (cdr rest) (+ total 1)))
     (else
      (loop (cdr rest) total)))))  

