;;; -*- Gerbil -*-
;;; agent style scenario composition policy.

(import :std/test
        :policy/agent-style-scenario-composition-test-core
        :policy/agent-style-scenario-composition-test-protocol)
(export agent-style-scenario-composition-policy-test)

;; PolicyTest
(def agent-style-scenario-composition-policy-test
  (test-suite "agent style scenario composition policy"
    agent-style-scenario-composition-core-policy-test
    agent-style-scenario-composition-protocol-policy-test))
