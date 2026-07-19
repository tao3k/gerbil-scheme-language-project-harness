(import :std/test
        (only-in :std/sugar hash-get with-catch)
        :gslph/src/build-api/component-closure)

(export component-closure-test)

(def component-closure-test
  (test-suite
   "GSLPH component source closure"

   (test-case "poo-flow closure is deterministic and strict"
     (let* ((entries (gslph-component-entry-files 'poo-flow))
            (sources (gslph-component-source-files 'poo-flow))
            (receipt (gslph-component-receipt 'poo-flow)))
       (check (gslph-component-source-files "poo-flow") => sources)
       (check (andmap (lambda (entry) (member entry sources)) entries) => #t)
       (check (hash-get receipt 'schema)
              => "gslph.component-source-closure.v1")
       (check (hash-get receipt 'outcome) => "valid")
       (check (hash-get receipt 'strictSubset) => #t)
       (check (hash-get receipt 'sourceCount) => (length sources))
       (check (< (hash-get receipt 'sourceCount)
                 (hash-get receipt 'fullSourceCount))
              => #t)))

   (test-case "unknown components are rejected"
     (check (with-catch
             (lambda (_) #t)
             (lambda ()
               (gslph-component-entry-files 'missing-component)
               #f))
            => #t))))
