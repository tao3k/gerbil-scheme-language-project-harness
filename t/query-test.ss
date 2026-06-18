;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :gerbil/gambit
        :std/test
        (only-in :std/misc/process run-process)
        :commands/query
        :support/time)
(export query-test)

;;; Boundary:
;;; - This budget measures Gerbil test-process spawning and capture overhead.
;;; - It still rejects the old timeout-scale path while tolerating host jitter.
;; : Milliseconds
(def +native-query-fast-path-budget-ms+ 5000)
;; : Milliseconds
(def +native-query-single-owner-budget-ms+ 1000)

;; QueryTest
(def query-test
  (test-suite "gerbil scheme harness query"
    (test-case "selector query is a first-class code read"
      (let (result (query-output ["--selector"
                                  "src/commands/guide.ss:14-61"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (query-result-exit-code result) => 0)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "(def (guide-lines)")))
               => #t)))
    (test-case "selector query accepts graph frontier colon ranges"
      (let (result (query-output ["--selector"
                                  "src/commands/guide.ss:14:61"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (query-result-exit-code result) => 0)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "(def (guide-lines)")))
               => #t)))
    (test-case "native provider selector content returns without Gerbil runtime cold path"
      (if (native-provider-binary-available?)
        (let (result (native-query-output ["--selector"
                                           "src/support/io.ss:145-165"
                                           "--content"]))
          (check (query-result-exit-code result) => 0)
          (check (< (query-result-duration-ms result)
                    +native-query-fast-path-budget-ms+)
                 => #t)
          (check (not
                  (not
                   (string-contains
                    (query-result-output result)
                    "(def (read-line-range path start end)")))
                 => #t))
        (check #t => #t)))
    (test-case "native provider selector json returns without Gerbil runtime cold path"
      (if (native-provider-binary-available?)
        (let (result (native-query-output ["--selector"
                                           "src/support/io.ss:145-165"
                                           "--json"]))
          (check (query-result-exit-code result) => 0)
          (check (< (query-result-duration-ms result)
                    +native-query-fast-path-budget-ms+)
                 => #t)
          (check (not
                  (not
                   (string-contains
                    (query-result-output result)
                    "\"selector\":\"src/support/io.ss:145-165\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    (query-result-output result)
                    "\"code\"")))
                 => #t))
        (check #t => #t)))
    (test-case "native provider owner term query parses only requested owner"
      (if (native-provider-binary-available?)
        (let (result (native-query-output ["src/parser/typed-contract.ss"
                                           "--term"
                                           "typed-comment-structural-invalid-reasons"
                                           "--workspace"
                                           "."]))
          (check (query-result-exit-code result) => 0)
          (check (< (query-result-duration-ms result)
                    +native-query-single-owner-budget-ms+)
                 => #t)
          (check (not
                  (not
                   (string-contains
                    (query-result-output result)
                    "typed-comment-structural-invalid-reasons")))
                 => #t))
        (check #t => #t)))
    (test-case "ownerless gerbil-poo query routes to registered knowledge"
      (let (result (query-output ["--term"
                                  "gerbil-poo"
                                  "--term"
                                  "usage"
                                  "--workspace"
                                  "."
                                  "--names-only"]))
        (check (query-result-exit-code result) => 0)
        (let (message (query-result-output result))
          (check (string-contains message
                                  "[gerbil-query-route] query=gerbil-poo usage")
                 => 0)
          (check (not
                  (not
                   (string-contains
                    message
                    "registeredKnowledge uri=gerbil-poo://")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "notProjectActivation=true")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "asp gerbil-scheme search pattern gerbil-poo usage --view seeds")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "|sourceLookup order=local-source-before-git")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "missingLocalAction=install-package-before-repository-fallback")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "installHint=\"gxpkg install git.cons.io/mighty-gerbils/gerbil-poo\"")))
                 => #t))))
    (test-case "ownerless split gerbil poo query routes canonically"
      (let (result (query-output ["--term"
                                  "gerbil"
                                  "--term"
                                  "poo"
                                  "--term"
                                  "usage"
                                  "--workspace"
                                  "."
                                  "--names-only"]))
        (check (query-result-exit-code result) => 0)
        (let (message (query-result-output result))
          (check (not
                  (not
                   (string-contains
                    message
                    "[gerbil-query-route] query=gerbil poo usage")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "asp gerbil-scheme search pattern gerbil-poo usage --view seeds")))
                 => #t))))
    (test-case "ownerless gerbil-poo query json carries source lookup"
      (let (result (query-output ["--term"
                                  "gerbil-poo"
                                  "--term"
                                  "usage"
                                  "--workspace"
                                  "."
                                  "--names-only"
                                  "--json"]))
        (check (query-result-exit-code result) => 0)
        (let (message (query-result-output result))
          (check (not
                  (not
                   (string-contains message "\"sourceLookup\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains message "\"sourceRef\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains message "\"localRootHint\":\"~/.gerbil\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains message "\"order\":\"local-source-before-git\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains message
                                    "\"missingLocalAction\":\"install-package-before-repository-fallback\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains message
                                    "\"installHint\":\"gxpkg install git.cons.io/mighty-gerbils/gerbil-poo\"")))
                 => #t))))
    (test-case "ownerless names-only term points to fzf route"
      (let (result (query-output ["--term"
                                  "ownerless_names_only_term"
                                  "--workspace"
                                  "."
                                  "--names-only"]))
        (check (query-result-exit-code result) => 2)
        (let (message (query-result-output result))
        (check (string-contains message
                                "query --names-only requires an owner selector")
               => 0)
        (check (not
                (not
                 (string-contains
                  message
                  "search fzf '<term>' owner --workspace <workspace-root> --view seeds")))
               => #t))))
    (test-case "owner query rejects paths outside explicit workspace before indexing"
      (let (result (query-output ["src/types/facade.ss"
                                  "--workspace"
                                  ".."
                                  "--names-only"]))
        (check (query-result-exit-code result) => 2)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "query owner path does not exist under --workspace")))
               => #t)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "workspace=..")))
               => #t)))))

;;; Query result accessor:
;;; - query-output returns one compatibility pair at the process boundary.
;;; - Tests use named accessors so result shape changes stay local.
;; : (-> QueryOutput ExitCode )
(def (query-result-exit-code result)
  (car result))

;;; Query result accessor:
;;; - Captured output is a named field, not an anonymous cdr at call sites.
;;; - This mirrors gerbil-utils style: one bridge helper, composed at use sites.
;; : (-> QueryOutput String )
(def (query-result-output result)
  (let (rest (cdr result))
    (if (pair? rest)
      (car rest)
      rest)))

;; : (-> NativeQueryOutput Milliseconds )
(def (query-result-duration-ms result)
  (let (rest (cdr result))
    (if (pair? rest)
      (cadr rest)
      0)))

;; : (-> (List XX) QueryOutput )
(def (query-output args)
  (let (exit-code #f)
    (let (output
          (call-with-output-string
           (lambda (port)
             (parameterize ((current-output-port port))
               (set! exit-code (query-main args))))))
      (cons exit-code output))))

;; : (-> (List XX) NativeQueryOutput )
(def (native-query-output args)
  (let* ((command (cons (native-provider-binary)
                       (cons "query" args)))
         (start (monotonic-ms))
         (result
          (run-process command
                       stdin-redirection: #f
                       stdout-redirection: #t
                       stderr-redirection: #t
                       check-status: #f
                       coprocess:
                       (lambda (process)
                         (let (output (read-port-as-string process))
                           [(process-status process) output])))))
    [(car result)
     (cadr result)
     (duration-ms start (monotonic-ms))]))

;; : (-> Path )
(def (native-provider-binary)
  (let (override (getenv "ASP_PROVIDER_BIN_DIR" #f))
    (cond
     ((and override (not (equal? override "")))
      (path-expand "gerbil-scheme-harness" override))
     ((file-exists? (path-expand "../../asp.toml" (current-directory)))
      (path-expand "../../.bin/gerbil-scheme-harness" (current-directory)))
     (else
      (path-expand ".bin/gerbil-scheme-harness" (current-directory))))))

;; : (-> Boolean )
(def (native-provider-binary-available?)
  (file-exists? (native-provider-binary)))

;; : (-> Port String )
(def (read-port-as-string port)
  (call-with-output-string ""
    (lambda (out)
      (let loop ()
        (let (char (read-char port))
          (unless (eof-object? char)
            (write-char char out)
            (loop)))))))
