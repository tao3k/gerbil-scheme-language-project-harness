;;; -*- Gerbil -*-
;;; Generated option bags repeat symbolic lookup and hide the call contract.
(package: sample/reports)
(export report-format
        report-limit
        report-metadata
        emit-report)

;; report-format
;;   : (-> Alist Symbol)
;;   | warning repeated inline option lookup hides the keyword API
(def (report-format opts)
  (cdr (assq 'format opts)))

;; report-limit
;;   : (-> Alist Integer)
(def (report-limit opts)
  (cdr (assq 'limit opts)))

;; report-metadata
;;   : (-> Alist Boolean)
(def (report-metadata opts)
  (cdr (assq 'metadata opts)))

;; emit-report
;;   : (-> List Alist List)
(def (emit-report rows opts)
  (list (report-format opts)
        (report-limit opts)
        (report-metadata opts)
        rows))
