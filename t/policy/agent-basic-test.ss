;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent basic policy.

(import :std/test
        :policy/agent-basic-core-test
        :policy/agent-basic-declarative-test
        :policy/agent-basic-control-test
        :policy/agent-basic-functional-test)
(export agent-basic-policy-test)

;; PolicyTest
(def agent-basic-policy-test
  (test-suite "gerbil scheme harness agent basic policy"
    agent-basic-core-policy-test
    agent-basic-declarative-policy-test
    agent-basic-control-policy-test
    agent-basic-functional-policy-test))
