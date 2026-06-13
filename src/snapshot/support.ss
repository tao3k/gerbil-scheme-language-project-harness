;;; -*- Gerbil -*-
;;; Shared helpers for stable snapshot projections.

(import :parser/facade
        :std/srfi/13)

(export snapshot-list
        map-indexed
        snapshot-project-root
        trim-trailing-slash)

(def (map-indexed proc xs)
  (let lp ((rest xs) (rank 1) (out '()))
    (match rest
      ([] (reverse out))
      ([hd . tl] (lp tl (fx1+ rank) (cons (proc hd rank) out))))))

(def (snapshot-project-root index)
  (let* ((root (trim-trailing-slash (project-index-root index)))
         (cwd (current-directory)))
    (if (string-prefix? cwd root)
      (substring root (string-length cwd) (string-length root))
      root)))

(def (trim-trailing-slash path)
  (if (and (> (string-length path) 1) (string-suffix? "/" path))
    (substring path 0 (fx1- (string-length path)))
    path))

(def (snapshot-list xs)
  (map (lambda (x) x) xs))

