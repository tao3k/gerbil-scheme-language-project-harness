(import :gerbil/gambit
        :std/test
        :gslph/src/testing/memory-profile)

(export testing-memory-profile-test)

(def (gxtest-memory-exception-raised? thunk)
  (with-catch (lambda (_exception) #t)
              (lambda ()
                (thunk)
                #f)))

(def testing-memory-profile-test
  (test-suite "gxtest memory profile"
    (test-case "parses a bounded managed-heap declaration"
      (let* ((fixture "t/fixtures/testing-memory-profile/profile.ss")
             (max-heap-mib (gxtest-file-memory-max-heap-mib fixture))
                 (exception? (gxtest-file-memory-exception? fixture))
             (runtime-options (gxtest-file-memory-runtime-options fixture)))
          (check max-heap-mib => 96)
          (check exception? => #t)
          (check runtime-options => ["-:max-heap=96M"])))
    (test-case "rejects a malformed memory exception declaration"
      (let (fixture "t/fixtures/testing-memory-profile/invalid-profile.ss")
        (check
         (gxtest-memory-exception-raised?
          (lambda ()
            (gxtest-file-memory-max-heap-mib fixture)))
         => #t)))
    (test-case "rejects a nonliteral memory exception declaration"
      (let (fixture "t/fixtures/testing-memory-profile/nonliteral-profile.ss")
        (check
         (gxtest-memory-exception-raised?
          (lambda ()
            (gxtest-file-memory-max-heap-mib fixture)))
         => #t)))))
