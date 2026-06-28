;;; -*- Gerbil -*-
;;; Generated merge loop repeatedly copies the accumulated prefix.
(package: sample/reports)
(export merge-chunks)

;; merge-chunks
;;   : (-> (List (List Any)) (List Any))
;;   | warning loop-local append copies accumulated list state on each chunk
(def (merge-chunks chunks)
  (let loop ((remaining chunks) (acc '()))
    (if (null? remaining)
      acc
      (loop (cdr remaining)
            (append acc (car remaining))))))
