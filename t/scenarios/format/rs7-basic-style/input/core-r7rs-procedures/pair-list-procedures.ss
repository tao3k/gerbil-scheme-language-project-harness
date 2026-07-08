;;; -*- Gerbil -*-    
;;; Boundary: pair/list constructors, selectors, mutation, membership, assoc.    

(import :gerbil/gambit)    

(export list-procedure-sample)    

(def (list-procedure-sample items alist)
  (let ((pair (cons 'head items)))
    (set-car! pair 'updated)
    (set-cdr! pair (append (cdr pair) '(tail)))
    (list (car pair)
          (cdr pair)
          (cadr pair)
          (length pair)
          (reverse pair)
          (list-tail pair 1)
          (list-ref pair 0)
          (memq 'tail pair)
          (member 'tail pair)
          (assq 'name alist)
          (assoc 'name alist))))    

