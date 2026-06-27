;;; -*- Gerbil -*-
;;; agent style scenario control policy.

(import :std/test
        :policy/agent-style-scenario-control-test-branch
        :policy/agent-style-scenario-control-test-gerbil-features
        :policy/agent-style-scenario-control-test-higher-order
        :policy/agent-style-scenario-control-test-runtime)
(export agent-style-scenario-control-policy-test)

;; PolicyTest
(def agent-style-scenario-control-policy-test
  (test-suite "agent style scenario control policy"
    agent-style-scenario-control-branch-policy-test
    agent-style-scenario-control-gerbil-features-policy-test
    agent-style-scenario-control-higher-order-policy-test
    agent-style-scenario-control-runtime-policy-test))
