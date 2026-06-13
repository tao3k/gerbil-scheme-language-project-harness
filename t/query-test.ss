;;; -*- Gerbil -*-
(import :gerbil/gambit
        :std/test
        :commands/query)
(export query-test)

(def query-test
  (test-suite "gerbil scheme harness query"
    (test-case "selector query is a first-class code read"
      (let (result (query-output ["--selector"
                                  "src/commands/guide.ss:1-13"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (car result) => 0)
        (check (not
                (not
                 (string-contains
                  (cdr result)
                  "(def (guide-lines)")))
               => #t)))
    (test-case "selector query accepts graph frontier colon ranges"
      (let (result (query-output ["--selector"
                                  "src/commands/guide.ss:1:13"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (car result) => 0)
        (check (not
                (not
                 (string-contains
                  (cdr result)
                  "(def (guide-lines)")))
               => #t)))
    (test-case "ownerless names-only term points to fzf route"
      (let (result (query-output ["--term"
                                  "ownerless_names_only_term"
                                  "--workspace"
                                  "."
                                  "--names-only"]))
        (check (car result) => 2)
        (let (message (cdr result))
        (check (string-contains message
                                "query --names-only requires an owner selector")
               => 0)
        (check (not
                (not
                 (string-contains
                  message
                  "search fzf '<term>' owner --view seeds --workspace <workspace-root>")))
               => #t))))))

(def (query-output args)
  (let (exit-code #f)
    (let (output
          (call-with-output-string
           (lambda (port)
             (parameterize ((current-output-port port))
               (set! exit-code (query-main args))))))
      (cons exit-code output))))
