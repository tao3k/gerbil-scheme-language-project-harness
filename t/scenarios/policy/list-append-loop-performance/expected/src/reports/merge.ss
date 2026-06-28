;;; -*- Gerbil -*-
;;; Accumulator merge keeps list growth linear and reverses once at the boundary.
(package: sample/reports)
(export merge-chunks)

;; merge-chunks
;;   : (-> (List (List Any)) (List Any))
;;   | warning cons/reverse owns the hot list-growth boundary
;;   | doc m%
;;       `merge-chunks` avoids loop-local `append` by accumulating elements in
;;       reverse order and restoring order once after traversal completes.
;;     %
(def (merge-chunks chunks)
  (let outer ((remaining chunks) (rev '()))
    (if (null? remaining)
      (reverse rev)
      (let inner ((items (car remaining)) (next-rev rev))
        (if (null? items)
          (outer (cdr remaining) next-rev)
          (inner (cdr items)
                 (cons (car items) next-rev)))))))
