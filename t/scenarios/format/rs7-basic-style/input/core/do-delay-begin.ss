;;; -*- Gerbil -*-   
;;; Boundary: begin, do iteration, delay, force, and promise style.   

(import :gerbil/gambit)   

(export delayed-sum)   

(def (sum-with-do values)
  (do ((rest values (cdr rest))
       (total 0 (+ total (car rest))))
      ((null? rest) total)))   

(def (delayed-sum values)
  (let (promise
        (delay
          (begin
            (sum-with-do values))))
    (force promise)))   

