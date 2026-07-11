;;; -*- Gerbil -*-
;;; Parser-owned exact-set gate for the standalone CLI release projection.

(import :gerbil/gambit
        :gslph/src/parser/facade
        :std/sort
        :std/test
        (only-in :std/misc/path path-directory path-expand path-normalize)
        (only-in :std/srfi/1 filter-map)
        (only-in :std/srfi/13 string-prefix? string-suffix?)
        (only-in :std/sugar ormap)
        "../src/build-api/release-modules")
(export cli-release-module-closure-test)

;; : String
(def +release-source-root+ (path-normalize (path-expand "src")))

;; : String
(def +release-source-root-prefix+
  (string-append +release-source-root+ "/"))

;; : (List ModulePath)
(def +release-dynamic-command-targets+
  '("commands/agent.ss"
    "commands/bench.ss"
    "commands/evidence.ss"
    "commands/fmt.ss"
    "commands/guide.ss"
    "commands/info.ss"
    "commands/query.ss"
    "commands/search.ss"))

;; : (List String)
(def +release-forbidden-prefixes+
  '("build-api/" "building/" "scenario/" "snapshot/" "testing/"))

;; : (-> String String)
(def (ensure-source-suffix path)
  (if (string-suffix? ".ss" path)
    path
    (string-append path ".ss")))

;; : (-> Path (Or False ModulePath))
(def (release-source-path->module-path source-path)
  (let (normalized (path-normalize source-path))
    (and (string-prefix? +release-source-root-prefix+ normalized)
         (substring normalized
                    (string-length +release-source-root-prefix+)
                    (string-length normalized)))))

;; : (-> ModulePath String (Or False ModulePath))
(def (release-local-module-reference importer-path reference)
  (cond
   ((string-prefix? ":gslph/src/" reference)
    (ensure-source-suffix
     (substring reference
                (string-length ":gslph/src/")
                (string-length reference))))
   ((string-prefix? ":" reference)
    (let* ((candidate
            (ensure-source-suffix
             (substring reference 1 (string-length reference))))
           (source-path (path-expand candidate +release-source-root+)))
      (and (file-exists? source-path) candidate)))
   (else
    (let* ((importer-source
            (path-expand importer-path +release-source-root+))
           (candidate-source
            (path-expand (ensure-source-suffix reference)
                         (path-directory importer-source))))
      (release-source-path->module-path candidate-source)))))

;; : (-> ModulePath (List ModulePath))
(def (release-module-local-imports module-path)
  (let (source-file
        (parse-source-file "."
                           (path-expand module-path
                                        +release-source-root+)))
    (filter-map
     (lambda (import-fact)
       (release-local-module-reference
        module-path
        (module-import-fact-module import-fact)))
     (source-file-module-imports source-file))))

;; : (-> (List ModulePath))
(def (parser-owned-release-module-closure)
  (let loop ((pending '("cli-release-linker.ss"))
             (seen [])
             (result []))
    (match pending
      ([] (sort result string<?))
      ([module-path . rest]
       (if (member module-path seen)
         (loop rest seen result)
         (loop (append (release-module-local-imports module-path) rest)
               (cons module-path seen)
               (cons module-path result)))))))

;; : (-> (List ModulePath) String Boolean)
(def (release-closure-has-prefix? closure prefix)
  (ormap (lambda (module-path) (string-prefix? prefix module-path))
         closure))

;; : TestSuite
(def cli-release-module-closure-test
  (test-suite "standalone CLI release module closure"
    (test-case "declared projection equals parser-owned import closure"
      (let* ((actual (parser-owned-release-module-closure))
             (declared
              (sort (cons "cli-release-linker.ss" cli-release-modules)
                    string<?)))
        (check (length actual) => cli-release-closure-count)
        (check actual => declared)))
    (test-case "dynamic command targets are represented statically"
      (for-each
       (lambda (module-path)
         (check (member module-path cli-release-modules) ? true))
       +release-dynamic-command-targets+))
    (test-case "development module families stay outside the release closure"
      (for-each
       (lambda (prefix)
         (check (release-closure-has-prefix? cli-release-modules prefix)
                => #f))
       +release-forbidden-prefixes+))))
