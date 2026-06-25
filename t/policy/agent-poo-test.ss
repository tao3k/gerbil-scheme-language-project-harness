;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent POO policy.

(import :std/test
        :policy/agent-poo-guidance-test
        :policy/agent-poo-hot-loop-core-test
        :policy/agent-poo-hot-loop-type-test
        :policy/agent-poo-hot-loop-runtime-test
        :policy/agent-poo-runtime-protocol-test)
(export agent-poo-policy-test)

;; PolicyTest
(def agent-poo-policy-test
  (test-suite "gerbil scheme harness agent POO policy"
    agent-poo-guidance-policy-test
    agent-poo-hot-loop-core-policy-test
    agent-poo-hot-loop-type-policy-test
    agent-poo-hot-loop-runtime-policy-test
    agent-poo-runtime-protocol-policy-test))
