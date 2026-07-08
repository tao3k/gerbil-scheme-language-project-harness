;;; -*- Gerbil -*-
;;; Boundary: call-with-current-continuation and escape style.

(import :gerbil/gambit)

(export find-first)

(def (find-first predicate? items)
  (call-with-current-continuation
    (lambda (return)
      (for-each
       (lambda (item)
         (if (predicate? item)
           (return item)
           #!void))
       items)
      #f)))
