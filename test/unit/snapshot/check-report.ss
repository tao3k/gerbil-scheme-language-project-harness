;;; -*- Gerbil -*-
(import :snapshot/facade
        :std/test)
(export check-empty-check-report-snapshot)

(def (check-empty-check-report-snapshot)
  (check (check-report-snapshot #f '())
         => '(checkReport
              (languageId "gerbil-scheme")
              (providerId "gerbil-scheme-harness")
              (status "pass")
              (findings ()))))
