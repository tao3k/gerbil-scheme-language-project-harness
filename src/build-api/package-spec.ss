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
(def +gslph-package-api-core+
  '("build-api/package-receipt.ss"
    "build-api/worker-count.ss"
    "build-api/build-path-contract.ss"
    "support/time.ss"))

;; : (List Path)
(def +gslph-package-api-benchmark-core+
  '("benchmark/gate.ss"))

;; : (List Path)
(def +gslph-package-api-benchmark-framework+
  '("benchmark/framework.ss"))

;; : (List Path)
(def +gslph-package-api-testing-model+
  '("testing/model.ss"))

;; : (List Path)
(def +gslph-package-api-testing-scope+
  '("testing/scope.ss"))

;; : (List Path)
(def +gslph-package-api-testing-core+
  '("testing/scenario.ss"
    "testing/performance.ss"
    "testing/batch.ss"))

;; : (List Path)
(def +gslph-package-api-testing-selection+
  '("testing/selection.ss"))

;; : (List Path)
(def +gslph-package-api-testing-framework+
  '("testing/framework.ss"))

;; : (List Path)
(def +gslph-package-api-testing-build-core+
  '("testing/build-paths.ss"
    "testing/gxtest-smoke.ss"
    "testing/gxtest-context.ss"
    "testing/gxtest-report.ss"))

;; : (List Path)
(def +gslph-package-api-testing-build-process+
  '("testing/build-process.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-syntax+
  '("testing/gxtest-syntax.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-imports+
  '("testing/gxtest-imports.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-sources+
  '("testing/gxtest-sources.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-discovery+
  '("testing/gxtest-discovery.ss"))

;; : (List Path)
(def +gslph-package-api-testing-build-support+
  '("testing/build-support.ss"
    "testing/build.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-delegate+
  '("testing/gxtest-delegate.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-expression+
  '("testing/gxtest-expression.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-receipts+
  '("testing/gxtest-receipts.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-policy-build+
  '("testing/gxtest-policy.ss"
    "testing/gxtest-build.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-execution+
  '("testing/gxtest-execution.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-run+
  '("testing/gxtest-run.ss"))

;; : (List Path)
(def +gslph-package-api-testing-build-runtime+
  '("testing/build-runtime.ss"))

;; : (List Path)
(def +gslph-package-api-testing-build-runner+
  '("testing/build-runner.ss"))

;; : (List Path)
(def +gslph-package-api-gxtest-runner+
  '("testing/gxtest-runner.ss"))

;; : (List Path)
(def +gslph-package-api-testing+
  (append +gslph-package-api-testing-build-core+
          +gslph-package-api-testing-build-process+
          +gslph-package-api-gxtest-syntax+
          +gslph-package-api-gxtest-imports+
          +gslph-package-api-gxtest-sources+
          +gslph-package-api-gxtest-discovery+
          +gslph-package-api-testing-build-support+
          +gslph-package-api-gxtest-delegate+
          +gslph-package-api-gxtest-expression+
          +gslph-package-api-gxtest-receipts+
          +gslph-package-api-gxtest-policy-build+
          +gslph-package-api-gxtest-execution+
          +gslph-package-api-gxtest-run+
          +gslph-package-api-testing-build-runtime+
          +gslph-package-api-testing-build-runner+
          +gslph-package-api-gxtest-runner+))

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
          +gslph-package-api-core+
          +gslph-package-api-benchmark-core+
          +gslph-package-api-benchmark-framework+
          +gslph-package-api-testing-model+
          +gslph-package-api-testing-scope+
          +gslph-package-api-testing-core+
          +gslph-package-api-testing-selection+
          +gslph-package-api-testing-framework+
          (append-map gslph-package-api-directory-spec
                      +gslph-package-api-directories+)
          +gslph-package-api-testing+))

;; : (-> (List (List Path)))
(def (gslph-package-api-stage-specs)
  (append (list +gslph-package-api-bootstrap+
                +gslph-package-api-core+
                +gslph-package-api-benchmark-core+
                +gslph-package-api-benchmark-framework+
                +gslph-package-api-testing-model+
                +gslph-package-api-testing-scope+
                +gslph-package-api-testing-core+
                +gslph-package-api-testing-selection+
                +gslph-package-api-testing-framework+)
          (map gslph-package-api-directory-spec
               +gslph-package-api-directories+)
          (list +gslph-package-api-testing-build-core+
                +gslph-package-api-testing-build-process+
                +gslph-package-api-gxtest-syntax+
                +gslph-package-api-gxtest-imports+
                +gslph-package-api-gxtest-sources+
                +gslph-package-api-gxtest-discovery+
                +gslph-package-api-testing-build-support+
                +gslph-package-api-gxtest-delegate+
                +gslph-package-api-gxtest-expression+
                +gslph-package-api-gxtest-receipts+
                +gslph-package-api-gxtest-policy-build+
                +gslph-package-api-gxtest-execution+
                +gslph-package-api-gxtest-run+
                +gslph-package-api-testing-build-runtime+
                +gslph-package-api-testing-build-runner+
                +gslph-package-api-gxtest-runner+)))
