;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :language/facade
        :snapshot/facade
        :std/test)

(export check-runtime-source-snapshot-fields
        check-runtime-source-snapshot-fixtures)
;; String <- String
(def (runtime-source-fact-by-id id)
  (let lp ((rest (runtime-source-facts)))
    (match rest
      ([] (error "runtime source fact not found" id))
      ([fact . tail]
       (if (equal? (hash-get fact 'id) id)
         fact
         (lp tail))))))
;; Snapshot
(def (check-runtime-source-snapshot-fields)
  (let (fact (runtime-source-fact-by-id "gerbil-runtime-writeenv-source"))
    (check (runtime-source-search-snapshot
            "writeenv printer hook"
            [fact]
            (hash-get fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-writeenv-acquisition.ss"))))
;; Snapshot
(def (check-runtime-source-snapshot-fixtures)
  (let ((macro-fact (runtime-source-fact-by-id "gerbil-runtime-source"))
        (writeenv-fact (runtime-source-fact-by-id "gerbil-runtime-writeenv-source")))
    (check (runtime-source-search-snapshot
            "macro"
            [macro-fact]
            (hash-get macro-fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-macro-acquisition.ss"))
    (check (runtime-source-search-snapshot
            "writeenv printer hook"
            [writeenv-fact]
            (hash-get writeenv-fact 'next))
           => (snapshot-load "t/snapshots/runtime-source-writeenv-acquisition.ss"))))
