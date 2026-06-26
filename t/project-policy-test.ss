;;; -*- Gerbil -*-
;;; Explicit full-project policy gate.

(import :policy/gxtest)
(export project-policy-test)

;; : TestSuite
(def project-policy-test
  (make-gxtest-policy-test "."))
