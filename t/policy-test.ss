;;; -*- Gerbil -*-
;;; Boundary:
;;; - Top-level policy suite only composes smaller policy owners.
;;; - Keep individual policy test files under modularity limits.

(import :std/test
        (only-in :std/misc/path directory-files)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-suffix?)
        :policy/gxtest
        :policy/modularity-test
        :policy/agent-basic-test
        :policy/agent-alist-access-test
        :policy/agent-anonymous-pair-test
        :policy/agent-build-test
        :policy/agent-source-scope-test
        :policy/agent-repair-test
        :policy/agent-style-higher-order-test
        :policy/agent-style-test
        :policy/agent-dependency-adapter-test
        :policy/agent-poo-test
        :policy/scenario-benchmark-test
        :policy/detection-test
        :policy/gerbil-utils-source-test)
(export policy-test)

;;; Policy gate scope:
;;; - The file list follows the same top-level gxtest files as build.ss test.
;;; - Source coverage metadata defines membership; this list defines execution scope.
;; : (-> Path Boolean)
(def (top-level-policy-test-file? entry)
  (and (string-suffix? "-test.ss" entry)
       (not (member entry '("." "..")))))

;; : (-> (List Path))
(def (top-level-policy-test-files)
  (map (lambda (path)
         (string-append "t/" path))
       (filter top-level-policy-test-file?
               (sort (directory-files "t") string<?))))

;; : TestSuite
(def policy-test
  (test-suite "gerbil scheme harness policy"
    (make-policy-test "." (top-level-policy-test-files))
    modularity-policy-test
    agent-basic-policy-test
    agent-alist-access-policy-test
    agent-anonymous-pair-policy-test
    agent-build-policy-test
    agent-source-scope-policy-test
    agent-repair-policy-test
    agent-style-higher-order-policy-test
    agent-style-policy-test
    agent-dependency-adapter-policy-test
    agent-poo-policy-test
    scenario-benchmark-policy-test
    detection-policy-test
    gerbil-utils-source-policy-test))
