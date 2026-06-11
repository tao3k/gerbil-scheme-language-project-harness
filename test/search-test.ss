;;; -*- Gerbil -*-
(import :std/test
        :support/args)
(export search-test)

(def search-test
  (test-suite "gerbil scheme harness search"
    (test-case "owner item marker is not treated as project root"
      (check (project-root ["src/checker/types.ss"
                            "items"
                            "--query"
                            "type-compatible"
                            "--names-only"])
             => ".")
      (check (drop-project-root ["src/checker/types.ss"
                                 "items"
                                 "--query"
                                 "type-compatible"
                                 "--names-only"
                                 "."])
             => ["src/checker/types.ss"
                 "items"
                 "--query"
                 "type-compatible"
                 "--names-only"]))
    (test-case "project root removal preserves option values"
      (check (project-root ["src/checker/types.ss"
                            "."
                            "--names-only"])
             => ".")
      (check (drop-project-root ["src/checker/types.ss"
                                 "."
                                 "--names-only"])
             => ["src/checker/types.ss" "--names-only"])
      (check (drop-project-root ["src/checker/types.ss"
                                 "items"
                                 "--query"
                                 "."
                                 "."])
             => ["src/checker/types.ss"
                 "items"
                 "--query"
                 "."]))))
