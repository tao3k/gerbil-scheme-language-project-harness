;;; -*- Gerbil -*-
(import :clan/poo/object)

(def (build-report-profile)
  (.o score: 0
      rows: 8
      columns: 5
      sections: 3
      charts: 2
      filters: 4
      exports: 2
      alerts: 6
      retries: 3
      priority: 1))

(def (score-report profile limit)
  (let loop ((i 0))
    (if (= i limit)
      (.ref profile 'score)
      (begin
        (.put! profile 'score i)
        (loop (+ i 1))))))
