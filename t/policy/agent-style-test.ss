;;; -*- Gerbil -*-
;;; Gerbil scheme harness agent style policy.

(import :std/test
        :policy/agent-style-benchmark-test
        :policy/agent-style-scenario-composition-test
        :policy/agent-style-scenario-control-test
        :policy/agent-style-typed-core-test
        :policy/agent-style-typed-evidence-test
        :policy/agent-style-comment-core-test
        :policy/agent-style-comment-doc-test
        :policy/agent-style-functional-core-test
        :policy/agent-style-functional-branch-test
        :policy/agent-style-predicate-test)
(export agent-style-policy-test)

;; PolicyTest
(def agent-style-policy-test
  (test-suite "gerbil scheme harness agent style policy"
    agent-style-benchmark-policy-test
    agent-style-scenario-composition-policy-test
    agent-style-scenario-control-policy-test
    agent-style-typed-core-policy-test
    agent-style-typed-evidence-policy-test
    agent-style-comment-core-policy-test
    agent-style-comment-doc-policy-test
    agent-style-functional-core-policy-test
    agent-style-functional-branch-policy-test
    agent-style-predicate-policy-test))
