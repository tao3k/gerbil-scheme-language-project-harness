;;; -*- Gerbil -*-
(import :gerbil/gambit
        :gslph/src/testing/build)

(export upstream-gxtest-project
        upstream-gxtest-main)

(def +upstream-gxtest-root+
  "t/scenarios/policy/upstream-gxtest-delegation/expected")

(def upstream-gxtest-project
  (testing-build
   name: "upstream-gxtest-delegation"
   root: +upstream-gxtest-root+
   contract-root: "t/scenarios/policy/upstream-gxtest-delegation"
   gxtest: [["upstream" "t/upstream-tests.ss"]]
   roots: ["t"]))

(def (upstream-gxtest-main args)
  (testing-build-main upstream-gxtest-project args))
