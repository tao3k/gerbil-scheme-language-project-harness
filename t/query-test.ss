;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(import :gerbil/gambit
        :std/test
        (only-in :std/misc/process run-process)
        :gslph/src/commands/query
        (only-in :gslph/src/testing/execution-profile
                 declare-gxtest-serial)
        :gslph/src/support/time)
(export query-test)

(declare-gxtest-serial shared-native-provider)

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
    (test-case "selector query accepts structural parser item selectors"
      (let (result (query-output ["--selector"
                                  "gerbil-scheme://src/parser/selectors.ss#item/function/selector-from"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (query-result-exit-code result) => 0)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "(def (selector-from path-accessor start-accessor end-accessor fact)")))
               => #t)))
    (test-case "selector query round-trips structural export selectors"
      (let (result (query-output ["--selector"
                                  "gerbil-scheme://src/parser/selectors.ss#item/export/definition-selector"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (query-result-exit-code result) => 0)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "(def (definition-selector defn)")))
               => #t)))
    (test-case "selector query emits a v1 no-hit receipt for absent structural items"
      (let (result (query-output ["--selector"
                                  "gerbil-scheme://src/build-api/framework.ss#item/export/package-source-stage-parallelize"
                                  "--workspace"
                                  "."
                                  "--json"]))
        (check (query-result-exit-code result) => 0)
        (let (message (query-result-output result))
          (check (not
                  (not
                   (string-contains message "\"resolution\":\"not-found\"")))
                 => #t)
          (check (not
                  (not
                   (string-contains
                    message
                    "\"selector\":\"gerbil-scheme://src/build-api/framework.ss#item/export/package-source-stage-parallelize\"")))
                 => #t)
          (check (not
                  (not (string-contains message "\"matches\":[]")))
                 => #t)
          (check (not
                  (not (string-contains message "\"selectorAliases\":[]")))
                 => #t)
          (check (string-contains message "\"code\"") => #f))))
    (test-case "selector query accepts parser item symbol selectors"
      (let (result (query-output ["--selector"
                                  "selector-from"
                                  "--workspace"
                                  "."
                                  "--code"]))
        (check (query-result-exit-code result) => 0)
        (check (not
                (not
                 (string-contains
                  (query-result-output result)
                  "(def (selector-from path-accessor start-accessor end-accessor fact)")))
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
    (test-case "ownerless names-only term points to lexical route"
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
                  "search lexical '<term>' owner --workspace <workspace-root> --view seeds")))
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
;; : (-> QueryOutput ExitCode)
(def (query-result-exit-code result)
  (car result))

;;; Query result accessor:
;;; - Captured output is a named field, not an anonymous cdr at call sites.
;;; - This mirrors gerbil-utils style: one bridge helper, composed at use sites.
;; : (-> QueryOutput String)
(def (query-result-output result)
  (match (cdr result)
    ([output . _] output)
    (output output)))

;; : (-> NativeQueryOutput Milliseconds)
(def (query-result-duration-ms result)
  (match (cdr result)
    ([_ duration . _] duration)
    (_ 0)))

;; : (-> (List String) QueryOutput)
(def (query-output args)
  (let (exit-code #f)
    (let (output
          (call-with-output-string
           (lambda (port)
             (parameterize ((current-output-port port))
               (set! exit-code (query-main args))))))
      (cons exit-code output))))

;; : (-> (List String) NativeQueryOutput)
(def (native-query-output args)
  (let* ((command (cons (native-query-binary) args))
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

;;; Native binary fixture boundary:
;;; - Tests default to the package-local `.bin` produced by build-native.ss.
;;; - ASP_PROVIDER_BIN_DIR remains an explicit override for installed-provider
;;;   smoke tests, but root workspace wrappers are not implicit fallbacks here.
;; : (-> Path)
(def (native-provider-bin-dir)
  (let (override (getenv "ASP_PROVIDER_BIN_DIR" #f))
    (if (and override (not (equal? override "")))
      override
      (path-expand ".bin" (current-directory)))))

;;; Provider launcher path:
;;; - `gslph` is still required so tests verify the public installed command
;;;   exists beside any fast-path sibling.
;; : (-> Path)
(def (native-provider-binary)
  (path-expand "gslph" (native-provider-bin-dir)))

;;; Query fast-path path:
;;; - Performance assertions run only when the dedicated query sibling exists.
;;; - This prevents a source fallback from satisfying availability while still
;;;   measuring as native fast path.
;; : (-> Path)
(def (native-query-binary)
  (path-expand "gslph-query" (native-provider-bin-dir)))

;; : (-> Boolean)
(def (native-provider-binary-available?)
  (and (file-exists? (native-provider-binary))
       (file-exists? (native-query-binary))))

;; read-port-as-string
;;   : (-> Port String)
;;   | doc m%
;;       `read-port-as-string port` drains a process output port into one
;;       string so native-query timing assertions can inspect stdout/stderr.
;;
;;       # Examples
;;       ```scheme
;;       (call-with-input-string "ok" read-port-as-string) ; => "ok"
;;       ```
;;     %
(def (read-port-as-string port)
  (call-with-output-string ""
    (lambda (out)
      (let loop ()
        (let (char (read-char port))
          (unless (eof-object? char)
            (write-char char out)
            (loop)))))))
