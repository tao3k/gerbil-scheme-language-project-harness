;;; -*- Gerbil -*-
;;; Lightweight package API build surface for downstream dependency installs.

(import (only-in :gerbil/gambit
                 directory-files
                 file-exists?)
        (only-in :std/sort sort)
        (only-in :std/srfi/13 string-suffix?))

(export gslph-package-api-spec)

(def +gslph-package-api-core+
  '("build-api/source-coverage.ss"
    "constants.ss"
    "build-api/package-receipt.ss"
    "build-api/worker-count.ss"
    "build-api/build-path-contract.ss"
    "support/time.ss"
    "benchmark/framework.ss"
    "benchmark/gate.ss"
    "testing/model.ss"
    "testing/framework.ss"
    "testing/build.ss"
    "testing/gxtest-smoke.ss"
    "testing/gxtest-context.ss"
    "testing/gxtest-discovery.ss"
    "testing/gxtest-delegate.ss"
    "testing/gxtest-runner.ss"))

(def +gslph-package-api-directories+
  '("checker" "parser" "policy" "types" "extensions"))

(def (gslph-ss-file? file)
  (and (string? file)
       (string-suffix? ".ss" file)))

(def (gslph-package-api-directory-spec dir)
  (let (source-dir (string-append "src/" dir))
    (if (file-exists? source-dir)
      (map (lambda (file) (string-append dir "/" file))
           (sort (filter gslph-ss-file? (directory-files source-dir))
                 string<?))
      [])))

(def (gslph-package-api-spec)
  (append +gslph-package-api-core+
          (apply append
                 (map gslph-package-api-directory-spec
                      +gslph-package-api-directories+))))
