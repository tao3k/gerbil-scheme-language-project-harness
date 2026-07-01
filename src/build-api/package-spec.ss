;;; -*- Gerbil -*-
;;; Lightweight package API build surface for downstream dependency installs.

(import (only-in :gerbil/gambit
                 directory-files
                 file-exists?)
        (only-in :std/sort sort)
        (only-in :std/srfi/1 append-map)
        (only-in :std/srfi/13 string-suffix?))

(export gslph-package-api-spec
        gslph-package-api-stage-specs)

;; : (List Path)
(def +gslph-package-api-bootstrap+
  '("build-api/source-coverage.ss"
    "constants.ss"))

;; : (List Path)
(def +gslph-package-api-foundation+
  '("build-api/package-receipt.ss"
    "build-api/worker-count.ss"
    "build-api/build-path-contract.ss"
    "support/time.ss"
    "benchmark/framework.ss"
    "benchmark/gate.ss"
    "testing/model.ss"
    "testing/scope.ss"
    "testing/scenario.ss"
    "testing/performance.ss"
    "testing/selection.ss"
    "testing/batch.ss"
    "testing/framework.ss"))

;; : (List Path)
(def +gslph-package-api-testing+
  '("testing/build-paths.ss"
    "testing/build-process.ss"
    "testing/build-support.ss"
    "testing/build-runtime.ss"
    "testing/build.ss"
    "testing/build-runner.ss"
    "testing/gxtest-smoke.ss"
    "testing/gxtest-context.ss"
    "testing/gxtest-syntax.ss"
    "testing/gxtest-imports.ss"
    "testing/gxtest-sources.ss"
    "testing/gxtest-discovery.ss"
    "testing/gxtest-delegate.ss"
    "testing/gxtest-expression.ss"
    "testing/gxtest-report.ss"
    "testing/gxtest-execution.ss"
    "testing/gxtest-receipts.ss"
    "testing/gxtest-policy.ss"
    "testing/gxtest-build.ss"
    "testing/gxtest-run.ss"
    "testing/gxtest-runner.ss"))

;; : (List String)
(def +gslph-package-api-directories+
  '("types" "parser" "checker" "policy" "extensions"))

;; : (-> String Boolean)
(def (gslph-ss-file? file)
  (and (string? file)
       (string-suffix? ".ss" file)))

;; : (-> String (List Path))
(def (gslph-package-api-directory-spec dir)
  (let (source-dir (string-append "src/" dir))
    (if (file-exists? source-dir)
      (map (lambda (file) (string-append dir "/" file))
           (sort (filter gslph-ss-file? (directory-files source-dir))
                 string<?))
      [])))

;; : (-> (List Path))
(def (gslph-package-api-spec)
  (append +gslph-package-api-bootstrap+
          +gslph-package-api-foundation+
          (append-map gslph-package-api-directory-spec
                      +gslph-package-api-directories+)
          +gslph-package-api-testing+))

;; : (-> (List (List Path)))
(def (gslph-package-api-stage-specs)
  (append (list +gslph-package-api-bootstrap+
                +gslph-package-api-foundation+)
          (map gslph-package-api-directory-spec
               +gslph-package-api-directories+)
          (list +gslph-package-api-testing+)))
