;;; -*- Gerbil -*-
(import :gslph/src/policy/gxtest)

(export project-policy-test)

(def project-policy-test
  (make-current-file-policy-test "."))
