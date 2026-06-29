;;; -*- Gerbil -*-
(import :clan/poo/object)

(def +report-profile+
  (.o score: 1
      rows: 8
      columns: 5
      sections: 3
      charts: 2
      filters: 4
      exports: 2
      alerts: 6
      retries: 3
      priority: 7))

(def (build-report-profile)
  +report-profile+)

(def (sum-report-profile entries)
  (let loop ((entries entries) (total 0))
    (if (null? entries)
      total
      (loop (cdr entries) (+ total (cdar entries))))))

(def (score-report profile limit)
  (let* ((snapshot (.alist profile))
         (sum (sum-report-profile snapshot)))
    (let loop ((i 0) (total 0))
      (if (= i limit)
        total
        (loop (+ i 1) (+ total sum))))))
