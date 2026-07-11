(export building-gxtest-stage-boundary-test)

(import :std/test
        (only-in :gslph/src/testing/gxtest-context configure-build-root!)
        (only-in :gslph/src/testing/gxtest-build
                 compile-selected-gxtest-if-stale)
        (only-in :gslph/src/testing/gxtest-receipts
                 selected-gxtest-build-receipt-path))

(def (read-selected-gxtest-build-receipt files)
  (call-with-input-file (selected-gxtest-build-receipt-path files) read))

(def (alist-value alist key)
  (let (entry (assq key alist))
    (and entry (cdr entry))))

(def building-gxtest-stage-boundary-test
  (test-suite "gslph selected GxTest Building boundary"
    (test-case "selected target projects Building stages into its receipt"
      (let (files '("t/building-gxtest-stage-boundary-test.ss"))
        (configure-build-root! ".")
        (compile-selected-gxtest-if-stale files 1)
        (let* ((receipt (read-selected-gxtest-build-receipt files))
               (plan (alist-value receipt 'buildPlan))
               (stages (alist-value plan 'stages)))
          (check (and plan #t) => #t)
          (check (alist-value plan 'version) => 1)
          (check (> (length stages) 1) => #t)
          (check (alist-value (car stages) 'kind) => 'std/make))))))
