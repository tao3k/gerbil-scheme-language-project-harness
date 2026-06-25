;;; -*- Gerbil -*-
;;; Gerbil scheme harness parser part 8.

(import :std/test
        :unit/parser/parser-test-part8-source-contracts
        :unit/parser/parser-test-part8-comment-quality
        :unit/parser/parser-test-part8-quality-scaffolds
        :unit/parser/parser-test-part8-package-typed-contracts)
(export parser-test-part-8)

;; TestSuite
(def parser-test-part-8
  (test-suite "gerbil scheme harness parser part 8"
    parser-test-part-8-source-contracts
    parser-test-part-8-comment-quality
    parser-test-part-8-quality-scaffolds
    parser-test-part-8-package-typed-contracts))
