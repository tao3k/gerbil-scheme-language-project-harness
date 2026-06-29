;;; -*- Gerbil -*-
(import :std/test)

(export beta-test)

(def beta-test
  (test-suite "upstream beta"
    (test-case "ordinary gxtest suite export"
      (check (+ 1 1) => 2))))
