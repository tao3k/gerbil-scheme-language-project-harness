;;; -*- Gerbil -*-
;;; gerbil scheme harness parser part 8 package scope.

(import :std/test
        :gslph/src/extensions/facade
        :gslph/src/parser/facade
        :gslph/src/parser/typed-contract-scheme
        :gslph/src/protocol/json
        :gslph/src/protocol/structural-facts
        :std/srfi/13)
(import :unit/parser/parser-test-part8-support)
(export parser-test-part-8-package-scope)

;; PolicyTest
(def parser-test-part-8-package-scope
  (test-suite "gerbil scheme harness parser part 8 package scope"
(test-case "project package infers runtime roots from build script"
          (let* ((root (path-normalize ".run/parser-build-scope"))
                 (lib-dir (string-append root "/lib"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (build-path (string-append root "/build.ss"))
                 (lib-path (string-append lib-dir "/main.ss"))
                 (flat-path (string-append root "/cli.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir lib-dir)
            (write-text package-path
                        "(package: sample/build-scope)\n")
            (write-text build-path
                        ";;; -*- Gerbil -*-\n(defbuild-script '(\"lib/main\" \"cli\"))\n")
            (write-text lib-path "(package: sample/build-scope/main)\n(def answer 42)\n")
            (write-text flat-path "(package: sample/build-scope/cli)\n(def (main . args) args)\n")
            (let* ((index (collect-project root))
                   (package (project-index-package index))
                   (scope (project-package-source-scope-policy package)))
              (check (map source-file-path (project-index-files index))
                     => ["build.ss" "cli.ss" "gerbil.pkg" "lib/main.ss"])
              (check (source-scope-policy-roots scope) => [])
              (check (source-scope-policy-runtime-roots scope) => ["lib" "."])
              (check (source-scope-policy-explanation scope)
                     => "Inferred from build.ss defbuild-script targets."))))
(test-case "project package dependency activates poo extension"
          (let* ((root (path-normalize ".run/parser-poo-dependency"))
                 (source-dir (string-append root "/src"))
                 (package-path (string-append root "/gerbil.pkg"))
                 (source-path (string-append source-dir "/main.ss")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir source-dir)
            (write-text package-path
                        "(package: sample/app\n depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
            (write-text source-path "(package: sample/app/main)\n(def answer 42)\n")
            (let* ((index (collect-project root))
                   (extensions (project-extension-json index))
                   (extension (car extensions)))
              (check (project-package-name (project-index-package index)) => "sample/app")
              (check (hash-get extension 'name) => "poo")
              (check (hash-get extension 'activation) => "gerbil.pkg")
              (check (hash-get extension 'dependencyMode) => "required")
              (check (hash-get extension 'packageManager) => "gxpkg")
              (check (hash-get extension 'package) => "sample/app"))))
  ))
