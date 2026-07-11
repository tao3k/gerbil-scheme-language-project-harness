(export project-clean-target
        project-compile-target
        project-compile-spec
        configure-project-build-root!
        project-configure-testing-root!
        project-install-target
        project-test-target
        project-test-file-target
        project-test-full-target)

(import :gslph/src/build-api/native-build
        :gslph/src/testing/project-build)

(def testing-configure-project-testing-root!
  configure-project-testing-root!)

(def testing-project-test-target
  project-test-target)

(def testing-project-test-file-target
  project-test-file-target)

(def testing-project-test-full-target
  project-test-full-target)

(def (project-clean-target)
  (clean-target))

(def (project-compile-target verbose debug no-optimize optimized release full binary)
  (compile-target verbose debug no-optimize optimized release full binary))

(def (project-compile-spec full? release? binary?)
  (compile-spec full? release? binary?))

(def (configure-project-build-root! root)
  (configure-build-root! root))

(def (project-install-target verbose debug no-optimize optimized release full)
  (install-target verbose debug no-optimize optimized release full))

(def (project-configure-testing-root! root)
  (testing-configure-project-testing-root! root))

(def (project-test-target)
  (testing-project-test-target))

(def (project-test-file-target files)
  (testing-project-test-file-target files))

(def (project-test-full-target)
  (testing-project-test-full-target))
