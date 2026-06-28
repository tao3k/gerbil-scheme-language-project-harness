;;; -*- Gerbil -*-
;;; Lightweight package API build surface for downstream dependency installs.

(export gslph-package-api-spec)

;; Keep dependency installs focused on the build-time public API. Full parser,
;; policy, search, and CLI surfaces are built by explicit full/release/test
;; targets instead of every downstream `gxpkg deps --install`.
(def (gslph-package-api-spec)
  '("build-api/source-coverage.ss"
    "build-api/package-receipt.ss"))
