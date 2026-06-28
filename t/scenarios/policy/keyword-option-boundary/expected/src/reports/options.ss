;;; -*- Gerbil -*-
;;; Gerbil keyword parameters make option shape explicit at the API boundary.
(package: sample/reports)
(export emit-report)

;; emit-report
;;   : (-> List List)
;;   | warning keyword/default parameters own optional report behavior
;;   | doc m%
;;       `emit-report` exposes report options through native Gerbil keyword
;;       arguments, avoiding repeated alist scans and local key spelling.
;;     %
(def (emit-report rows #!key (format 'json) (limit #f) (metadata #f))
  (list format
        limit
        metadata
        rows))
