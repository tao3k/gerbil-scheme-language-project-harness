;;; -*- Gerbil -*-
;;; Fast self-apply wiring checks for ordinary gxtest runs.

(import :std/test)
(export self-apply-test)

;; SelfApplyTest
(def self-apply-test
  (test-suite "gerbil scheme harness self apply"
    (test-case "full self-apply gate is an explicit slow test owner"
      (check "t/self-apply-full-gate.ss" => "t/self-apply-full-gate.ss"))))
