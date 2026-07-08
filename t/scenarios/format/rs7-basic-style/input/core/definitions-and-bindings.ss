;;; -*- Gerbil -*-    
;;; Boundary: definitions, local bindings, mutation, and values.   

(import :gerbil/gambit)    

(export collect-binding-summary)    

(def +default-limit+ 8)    

(defvalues (seed offset)
  (values 3 5))    

(def (collect-binding-summary entries)
  (let* ((limit (+ seed offset))
         (seen []))
    (let loop ((rest entries)
               (count 0))
      (if (or (null? rest) (>= count limit))
        (reverse seen)
        (begin
          (set! seen (cons (car rest) seen))
          (loop (cdr rest) (+ count 1)))))))    

