;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level parser-test only composes smaller test owners.
;;; - Keep parser-visible test complexity below modularity thresholds.

(import :std/test
        :unit/parser/parser-test-part1
        :unit/parser/parser-test-part2
        :unit/parser/parser-test-part3
        :unit/parser/parser-test-part4
        :unit/parser/parser-test-part5
        :unit/parser/parser-test-part6
        :unit/parser/parser-test-part7
        :unit/parser/parser-test-part8)
(export parser-test)
;; TestSuite
(def parser-test
  (test-suite "gerbil scheme harness parser"
    parser-test-part-1
    parser-test-part-2
    parser-test-part-3
    parser-test-part-4
    parser-test-part-5
    parser-test-part-6
    parser-test-part-7
    parser-test-part-8))
