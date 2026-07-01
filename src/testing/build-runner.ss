;;; -*- Gerbil -*-
;;; Execution layer for downstream testing-build declarations.

(import :gslph/src/testing/build
        :gslph/src/testing/framework
        :gslph/src/testing/build-support
        (only-in :gslph/src/testing/build-runtime
                 testing-build-dry-gxtest-runner
                 testing-build-gxtest-runner))

(export (import: :gslph/src/testing/build)
        testing-build-select
        testing-build-main
        testing-build-dry-gxtest-runner
        testing-build-gxtest-runner
        testing-build-compile-selection-support!)

;; : (-> TestingBuild List TestingSelection)
(def (testing-build-select build args)
  (testing-select-project (testing-build-project build) args))

;; : (-> TestingBuild List (OrFalse Procedure) TestingReceipt)
(def (testing-build-main build args (run-files #f))
  (let (selection (testing-build-select build args))
    (testing-build-compile-selection-support! build selection)
    (testing-run-selection
     selection
     (or run-files
         (testing-build-gxtest-runner build)))))
