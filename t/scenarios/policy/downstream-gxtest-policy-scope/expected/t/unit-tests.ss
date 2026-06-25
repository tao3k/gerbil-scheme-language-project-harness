;;; -*- Gerbil -*-
(import :std/test
        :sample/downstream-gxtest-policy-scope/t/cli-test
        :sample/downstream-gxtest-policy-scope/t/project-policy-test)

(export unit-tests)

(def unit-tests
  (test-suite "unit"
    cli-test
    project-policy-test))
