;;; -*- Gerbil -*-
(package: sample/indexed)

(export select-indexes)

(def (select-indexes values indexes)
  (let (indexed (list->vector values))
    (let loop ((remaining indexes) (out '()))
      (if (null? remaining)
        (reverse out)
        (loop (cdr remaining)
              (cons (vector-ref indexed (car remaining)) out))))))
