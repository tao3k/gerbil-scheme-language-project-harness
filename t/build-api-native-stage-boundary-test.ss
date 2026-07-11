(export build-api-native-stage-boundary-test)

(import :std/test
        :gslph/src/build-api/native-build)

(def package-api-build-receipt-path ".gerbil/build/package-api.receipt")

(def (read-package-api-build-receipt)
  (call-with-input-file package-api-build-receipt-path read))

(def (alist-value alist key)
  (let (entry (assq key alist))
    (and entry (cdr entry))))

(def build-api-native-stage-boundary-test
  (test-suite "gslph build api native stage boundary"
    (test-case "ordinary target projects a package build plan"
      (configure-build-root! ".")
      (compile-target #f #f #t #f #f #f #f #f)
      (compile-target #f #f #t #f #f #f #f #f)
      (let* ((receipt (read-package-api-build-receipt))
             (plan (alist-value receipt 'buildPlan))
             (stages (alist-value plan 'stages))
             (first-stage (car stages))
             (status (alist-value first-stage 'status)))
        (check (alist-value receipt 'version)
               => 'gslph-package-build-receipt.v1)
        (check (and plan #t) => #t)
        (check (alist-value plan 'version) => 1)
        (check (> (length stages) 0) => #t)
        (check (and (alist-value first-stage 'label) #t) => #t)
        (check status => 'skipped)))))
