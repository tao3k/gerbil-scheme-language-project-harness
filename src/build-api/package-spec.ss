;;; -*- Gerbil -*-
;;; Lightweight package API build surface for downstream dependency installs.

(export gslph-package-api-spec)

;; Keep dependency installs focused on the build-time public API. Full parser,
;; policy, search, and CLI surfaces are built by explicit full/release/test
;; targets instead of every downstream `gxpkg deps --install`.
(def (gslph-package-api-spec)
  '("build-api/source-coverage.ss"
    "build-api/package-receipt.ss"
    "build-api/worker-count.ss"
    "build-api/build-path-contract.ss"
    "benchmark/framework.ss"
    "benchmark/gate.ss"
    "testing/model.ss"
    "testing/framework.ss"
    "testing/gxtest-smoke.ss"
    "testing/gxtest-runner.ss"
    "types/model.ss"
    "types/subtyping.ss"
    "types/validation.ss"
    "extensions/poo-source-ref-validation.ss"
    "extensions/poo-object-validation.ss"))
