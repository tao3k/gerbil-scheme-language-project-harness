;;; -*- Gerbil -*-
;;; Gerbil scheme harness parser part 8 package typed contracts.

(import :std/test
        :unit/parser/parser-test-part8-package-scope
        :unit/parser/parser-test-part8-typed-comment-blocks)
(export parser-test-part-8-package-typed-contracts)

;; TestSuite
(def parser-test-part-8-package-typed-contracts
  (test-suite "gerbil scheme harness parser part 8 package typed contracts"
    parser-test-part-8-package-scope
    parser-test-part-8-typed-comment-blocks))
