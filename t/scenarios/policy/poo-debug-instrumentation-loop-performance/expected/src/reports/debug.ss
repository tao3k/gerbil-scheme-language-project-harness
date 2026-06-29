;;; -*- Gerbil -*-
(import :clan/poo/debug
        :clan/poo/object)

(def +report-profile+
  (.o id: "orders"
      status: "hot"
      score: 0
      rows: 8
      columns: 5
      sections: 3
      charts: 2
      filters: 4
      exports: 2
      alerts: 6
      retries: 3
      priority: "high"))

(def (build-report-profile)
  +report-profile+)

(def (score-report profile limit)
  (let (traced (trace-poo profile 'report))
    (let loop ((i 0) (total 0))
      (if (= i limit)
        total
        (loop (+ i 1) (+ total (.ref traced 'score)))))))
