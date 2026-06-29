;;; -*- Gerbil -*-
(import :clan/poo/object)

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
  (let (score
        (let loop ((i 0) (score 0))
          (if (= i limit)
            score
            (loop (+ i 1) i))))
    (.cc profile 'score score)))
