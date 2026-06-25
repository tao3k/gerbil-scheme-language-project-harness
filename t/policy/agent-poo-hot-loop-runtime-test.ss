;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent POO hot loop runtime policy.

(import :std/test
        :policy/agent-poo-hot-loop-runtime-debug-test
        :policy/agent-poo-hot-loop-runtime-compact-test)
(export agent-poo-hot-loop-runtime-policy-test)

;; PolicyTest
(def agent-poo-hot-loop-runtime-policy-test
  (test-suite "gerbil scheme harness agent POO hot loop runtime policy"
    agent-poo-hot-loop-runtime-debug-policy-test
    agent-poo-hot-loop-runtime-compact-policy-test))
