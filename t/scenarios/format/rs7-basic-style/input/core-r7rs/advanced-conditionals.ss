;;; -*- Gerbil -*-    
;;; Boundary: cond =>, case =>, when, unless, and sequencing bodies.    

(import :gerbil/gambit)    

(export conditional-sample)    

(def (conditional-sample value)
  (cond
   ((assq value '((a . 1) (b . 2)))
    => cdr)
   ((number? value)
    (case value
      ((0) 'zero)
      ((1 2 3) => (lambda (group) ['small group]))
      (else 'number)))
   (else
    (when value
      (display value))
    (unless value
      (display "missing"))
    'fallback)))    

