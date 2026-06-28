;;; -*- Gerbil -*-
(package: sample/indexed)

(export select-indexes)

(def (select-indexes values indexes)
  (let loop ((remaining indexes) (out '()))
    (if (null? remaining)
      (reverse out)
      (loop (cdr remaining)
            (cons (list-ref values (car remaining)) out)))))
