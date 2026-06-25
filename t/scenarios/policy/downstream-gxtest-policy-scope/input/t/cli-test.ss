;;; -*- Gerbil -*-
(import :std/test
        :sample/downstream-gxtest-policy-scope/src/cli)

(export cli-test)

(def cli-test
  (test-suite "cli"
    (test-case "total"
      (check (total [1 2 3]) => 6))))
