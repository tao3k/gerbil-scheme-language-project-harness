(export configure-project-testing-root!
        project-test-target
        project-test-file-target
        project-test-full-target)

(import :gslph/src/testing/gxtest-runner)

(def (configure-project-testing-root! root)
  (configure-build-root! root))

(def (project-test-target)
  (test-target))

(def (project-test-file-target files)
  (test-file-target files))

(def (project-test-full-target)
  (test-full-target))
