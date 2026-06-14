;;; -*- Gerbil -*-
;;; Shared helpers for stable snapshot projections.

(import :parser/facade
        :support/list
        :std/srfi/13)

(export snapshot-list
        map-indexed
        snapshot-project-root
        trim-trailing-slash)
;; Snapshot <- ProjectIndex
(def (snapshot-project-root index)
  (let* ((root (trim-trailing-slash (project-index-root index)))
         (cwd (current-directory)))
    (if (string-prefix? cwd root)
      (substring root (string-length cwd) (string-length root))
      root)))
;; TrimTrailingSlash <- String
(def (trim-trailing-slash path)
  (if (and (> (string-length path) 1) (string-suffix? "/" path))
    (substring path 0 (fx1- (string-length path)))
    path))
;;; Boundary:
;;; - snapshot-list composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Snapshot <- (List XX)
(def (snapshot-list xs)
  (map (lambda (x) x) xs))
