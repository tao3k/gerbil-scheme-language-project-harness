;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level policy suite only composes smaller policy owners.
;;; - Keep individual policy test files under modularity limits.

(import :std/test
        :policy/modularity-test
        :policy/agent-basic-test
        :policy/agent-build-test
        :policy/agent-repair-test
        :policy/agent-style-test
        :policy/agent-dependency-adapter-test
        :policy/agent-poo-test
        :policy/detection-test
        :policy/gerbil-utils-source-test)
(export policy-test)
;; PolicyTest
(def policy-test
  (test-suite "gerbil scheme harness policy"
    modularity-policy-test
    agent-basic-policy-test
    agent-build-policy-test
    agent-repair-policy-test
    agent-style-policy-test
     agent-dependency-adapter-policy-test
     agent-poo-policy-test
     detection-policy-test
     gerbil-utils-source-policy-test))
