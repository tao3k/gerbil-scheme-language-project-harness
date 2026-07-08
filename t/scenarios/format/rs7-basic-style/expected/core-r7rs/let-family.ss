;;; -*- Gerbil -*-
;;; Boundary: let, let*, letrec, letrec*, let-values, and let*-values.

(import :gerbil/gambit)

(export let-family-sample)

(def (let-family-sample seed)
  (let ((base seed)
        (step 1))
    (let* ((next (+ base step))
           (label (number->string next)))
      (letrec ((even?
                (lambda (n)
                  (if (= n 0) #t (odd? (- n 1)))))
               (odd?
                (lambda (n)
                  (if (= n 0) #f (even? (- n 1))))))
        (letrec* ((prefix "value:")
                  (render (lambda (x) (string-append prefix x))))
          (let-values (((left right) (values next label)))
            (let*-values (((rendered) (values (render right)))
                          ((pair) (values [left rendered])))
              (and (even? left) pair))))))))
