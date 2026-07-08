;;; -*- Gerbil -*-    
;;; Boundary: equivalence, type predicates, and exactness predicates.    

(import :gerbil/gambit)    

(export predicate-report)    

(def (predicate-report value other)
  (list (eq? value other)
        (eqv? value other)
        (equal? value other)
        (boolean? value)
        (symbol? value)
        (char? value)
        (string? value)
        (vector? value)
        (bytevector? value)
        (procedure? value)
        (number? value)
        (exact? value)
        (inexact? value)
        (null? value)
        (pair? value)))    

