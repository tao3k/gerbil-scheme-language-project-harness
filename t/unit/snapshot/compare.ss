;;; -*- Gerbil -*-
(import :language/facade
        :snapshot/facade
        :std/test)

(export check-compare-snapshot-fields
        check-compare-snapshot-fixtures)

(def (compare-fact-by-id id)
  (let lp ((rest (compare-facts)))
    (match rest
      ([] (error "compare fact not found" id))
      ([fact . tail]
       (if (equal? (hash-get fact 'id) id)
         fact
         (lp tail))))))

(def (check-compare-snapshot-fields)
  (let (fact (compare-fact-by-id "env-active-documented"))
    (check (compare-search-snapshot
            "env active documented"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/compare-env-active-documented.ss"))))

(def (check-compare-snapshot-fixtures)
  (let (fact (compare-fact-by-id "env-active-documented"))
    (check (compare-search-snapshot
            "env active documented"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/compare-env-active-documented.ss"))))
