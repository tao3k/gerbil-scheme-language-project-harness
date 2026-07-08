;;; -*- Gerbil -*-
;;; Boundary: lambdas, higher-order calls, apply, map, and call-with-values.

(import :gerbil/gambit)

(export summarize-values)

(def (split-values items)
  (values (length items)
          (map symbol->string items)))

(def (summarize-values items)
  (call-with-values
    (lambda ()
      (split-values items))
    (lambda (count names)
      (apply string-append
             (cons (number->string count)
                   (map (lambda (name) (string-append ":" name)) names))))))
