;;; -*- Gerbil -*-
(import :snapshot/facade
        :std/test)
(export check-empty-self-apply-findings-snapshot)

(def (check-empty-self-apply-findings-snapshot)
  (check (self-apply-findings-snapshot '())
         => '(selfApplyFindings
              (languageId "gerbil-scheme")
              (providerId "gerbil-scheme-harness")
              (status "pass")
              (findingCount 0)
              (findings ()))))
