;;; -*- Gerbil -*-

(import :std/test
        :gslph/src/testing/project-build)

(def testing-project-build-interface-test
  (test-suite "testing project-build public interface"
    (test-case "exports project test execution procedures"
      (check (procedure? testing-configure-project-testing-root!) => #t)
      (check (procedure? testing-project-test-target) => #t)
      (check (procedure? testing-project-test-file-target) => #t)
      (check (procedure? testing-project-test-full-target) => #t))))

(run-tests! testing-project-build-interface-test)
