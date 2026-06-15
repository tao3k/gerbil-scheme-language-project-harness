;;; -*- Gerbil -*-
;;; Shared fixtures for policy test suites.

(import :gerbil/gambit
        :std/misc/process
        :commands/check
        :types/facade)
(export filter-rule
        json-finding-by-rule
        policy-check-output
        write-policy-project
        write-owner-entry-policy-project
        write-facade-policy-project
        write-bin-entrypoint-project
        write-test-directory-layout-project
        write-vague-definition-project
        write-top-level-executable-project
        write-search-fast-entrypoint-project
        write-ffi-declare-project
        write-poo-declarative-project
        write-functional-idiom-project
        write-functional-idiom-positive-project
        write-functional-idiom-caller-scope-project
        write-functional-idiom-reader-project
        write-controlled-branch-shape-project
        write-controlled-branch-loop-shape-project
        write-predicate-family-combinator-project
        write-dependency-protocol-adapter-project
        write-dependency-manual-object-adapter-project
        write-check-changed-project
        initialize-git-fixture
        run-git
        reset-fixture-root
        write-functional-idiom-control-context-project
        write-macro-runtime-source-project
        write-protocol-evidence-project
        ensure-dir
        write-text
        delete-file-if-exists
        write-large-policy-source
        write-large-policy-test
        write-padded-policy-test
        write-complex-policy-test)
;; FilterRule <- RuleId (List XX)
(def (filter-rule rule-id findings)
  (filter (lambda (finding)
            (equal? (type-finding-rule-id finding) rule-id))
          findings))
;; Json <- (List TypeFinding) RuleId
(def (json-finding-by-rule findings rule-id)
  (cond
   ((null? findings) #f)
   ((equal? (hash-get (car findings) "ruleId") rule-id) (car findings))
   (else (json-finding-by-rule (cdr findings) rule-id))))
;; CheckOutput <- (List TypeFinding)
(def (policy-check-output args)
  (let* ((status #f)
         (output
          (call-with-output-string
            (lambda (out)
              (parameterize ((current-output-port out))
                (set! status (check-main args)))))))
    (cons status output)))
;; Unit <- String FacadeName FacadeSource CoreSource
(def (write-policy-project root facade-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" facade-name))
         (facade-path (string-append src "/" facade-name ".ss"))
         (owner-entry-path (string-append owner "/" facade-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists owner-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; Unit <- String OwnerName FacadeSource CoreSource
(def (write-owner-entry-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (facade-entry-path (string-append owner "/facade.ss"))
         (facade-path (string-append owner "/" owner-name ".ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists facade-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; Unit <- String OwnerName FacadeSource CoreSource
(def (write-facade-policy-project root owner-name facade-source core-source)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (sibling-path (string-append src "/" owner-name ".ss"))
         (repeated-entry-path (string-append owner "/" owner-name ".ss"))
         (facade-path (string-append owner "/facade.ss"))
         (core-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (delete-file-if-exists sibling-path)
    (delete-file-if-exists repeated-entry-path)
    (write-text facade-path facade-source)
    (write-text core-path core-source)))
;; Unit <- String Source
(def (write-bin-entrypoint-project root source)
  (let* ((bin (string-append root "/bin"))
         (entrypoint-path (string-append bin "/run.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir bin)
    (write-text entrypoint-path source)))
;; Unit <- String MaybePackageSource
(def (write-test-directory-layout-project root . maybe-package-source)
  (let ((legacy-test (string-append root "/test"))
        (legacy-tests (string-append root "/tests"))
        (native-test (string-append root "/t"))
        (package-path (string-append root "/gerbil.pkg")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir legacy-test)
    (ensure-dir legacy-tests)
    (ensure-dir native-test)
    (if (pair? maybe-package-source)
      (write-text package-path (car maybe-package-source))
      (delete-file-if-exists package-path))
    (write-text (string-append legacy-test "/bad-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def bad-test (test-suite \"bad\"))\n")
    (write-text (string-append legacy-tests "/bad-tests-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def bad-tests-test (test-suite \"bad tests\"))\n")
    (write-text (string-append native-test "/good-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test)\n(def good-test (test-suite \"good\"))\n")))
;; Unit <- String
(def (write-vague-definition-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n(def (order-total order) order)\n")))
;; Unit <- String
(def (write-top-level-executable-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(import :std/misc/ports)\n(displayln \"bad\")\n(def (named) #t)\n")))
;; Unit <- String
(def (write-search-fast-entrypoint-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/search-fast")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text
     (string-append owner "/gerbil-scheme-search-example.ss")
     ";;; -*- Gerbil -*-\n(import :gerbil/gambit)\n(export main)\n(def (main . args) 0)\n(exit (apply main (cdr (command-line))))\n")))
;; Unit <- String
(def (write-ffi-declare-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/ffi")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(declare\n  (block)\n  (standard-bindings))\n(def (named) #t)\n")))
;; Unit <- String
(def (write-poo-declarative-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/poo")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text
     (string-append owner "/core.ss")
     ";;; -*- Gerbil -*-\n(import :clan/poo/object)\n(.def +sample-pattern+\n  selectors:\n      [(hash (role \"selector\")\n             (symbol \"defclass\"))]\n  qualitySignals: [\"source-backed\"])\n(def (named) #t)\n")))
;; String <- String
(def (write-functional-idiom-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export total)\n(def (total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")))
;; String <- String
(def (write-functional-idiom-positive-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export total)\n(def (total xs)\n  (for/fold ((acc 0)) ((x xs)) (+ acc x)))\n")))
;; String <- String
(def (write-functional-idiom-caller-scope-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export total manual-total)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export total manual-total)\n(def (total xs)\n  (for/fold ((acc 0)) ((x xs)) (+ acc x)))\n(def (manual-total xs)\n  (let loop ((rest xs) (acc 0))\n    (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))\n")))
;; String <- String
(def (write-functional-idiom-reader-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export read-values)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :std/misc/ports)\n(export read-values)\n(def (read-values port)\n  (let loop ((out '()))\n    (let (line (read-line port))\n      (if (eof-object? line) (reverse out) (loop (cons line out))))))\n")))
;; Unit <- String
(def (write-controlled-branch-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export decode-order)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export decode-order)\n(def (decode-order event)\n  (match event\n    (['created id] id)\n    (else #f))\n  (match event\n    (['cancelled id] id)\n    (else #f)))\n")))
;; Unit <- String
(def (write-controlled-branch-loop-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export select-orders)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export select-orders)\n(def (select-orders facts state)\n  (match state\n    ([seen out remaining]\n     (let lp ((rest facts) (seen seen) (out out) (remaining remaining))\n       (cond\n        ((or (null? rest) (<= remaining 0))\n         [seen out remaining])\n        (else\n         (lp (cdr rest) seen out remaining)))))))\n")))
;; Unit <- String
(def (write-predicate-family-combinator-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n;;; Predicate boundary:\n;;; - Keep duplicated role extraction visible for predicate-family policy tests.\n;; Boolean <- CreatedEventFact\n(def (created-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"created\"))))\n;;; Predicate boundary:\n;;; - Keep the accepted role set inline so repeated field access remains detectable.\n;; Boolean <- PaymentEventFact\n(def (paid-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (member (field-string fields 'role) '(\"paid\" \"settled\")))))\n;;; Predicate boundary:\n;;; - Keep cancellation as a single-purpose predicate for family grouping evidence.\n;; Boolean <- CancelledEventFact\n(def (cancelled-event? fact)\n  (let (fields (hash-get fact 'fields))\n    (and fields (equal? (field-string fields 'role) \"cancelled\"))))\n")))
;; Unit <- String Complete Witness
(def (write-dependency-protocol-adapter-project root complete? witness?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders"))
         (test-dir (string-append root "/t")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir test-dir)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/orders\n  depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
    (write-text (string-append owner "/dict.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n"
                 "  (only-in :clan/pure/dict/orderdict\n"
                 "           orderdict-empty? orderdict-ref orderdict-put orderdict->list\n"
                 "           list->orderdict orderdict=?)\n"
                 "  (only-in :clan/poo/mop define-type Any raise-type-error)\n"
                 "  (only-in ./table methods.table))\n"
                 "(define-type (OrderDict. @ [methods.table] Value)\n"
                 "  Key: String\n"
                 "  Value: Any\n"
                 (if complete?
                   "  .validate: => (lambda (super) (lambda (x) (super x)))\n  .empty: orderdict-empty?\n  .ref: orderdict-ref\n  .acons: (lambda (k v d) (orderdict-put d k v))\n  .foldl: (lambda (f seed d) seed)\n  .<-list: list->orderdict\n  .list<-: orderdict->list\n  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))\n  .=?: (lambda (a b) (orderdict=? a b)))\n"
                   "  .empty: orderdict-empty?\n  .ref: orderdict-ref\n  .acons: (lambda (k v d) (orderdict-put d k v)))\n")))
    (if witness?
      (write-text (string-append test-dir "/dict-test.ss")
                  ";;; -*- Gerbil -*-\n(import :std/test ../src/orders/dict)\n(def (table-contract-tests adapter) adapter)\n(def order-dict-test\n  (test-suite \"order dict\"\n    (test-case \"adapter contract witness\"\n      (check (table-contract-tests (OrderDict. String)) => (OrderDict. String)))))\n")
      (delete-file-if-exists (string-append test-dir "/dict-test.ss")))))
;; Unit <- String
(def (write-dependency-manual-object-adapter-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders"))
         (test-dir (string-append root "/t")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (ensure-dir test-dir)
    (write-text (string-append root "/gerbil.pkg")
                "(package: sample/orders\n  depend: (\"git.cons.io/mighty-gerbils/gerbil-poo\"))\n")
    (write-text (string-append owner "/dict.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import\n  (only-in :clan/pure/dict/orderdict\n           orderdict-empty? orderdict-ref orderdict-put orderdict->list\n           list->orderdict orderdict=?)\n  (only-in :clan/poo/mop define-type Any raise-type-error)\n  (only-in ./table methods.table))\n(define-type (OrderDict. @ [methods.table] Value)\n  Key: String\n  Value: Any\n  .validate: => (lambda (super) (lambda (x) (super x)))\n  .empty: orderdict-empty?\n  .ref: (lambda (d k) (hash-get (hash) k))\n  .acons: (lambda (k v d) (orderdict-put d k v))\n  .foldl: (lambda (f seed d) seed)\n  .<-list: list->orderdict\n  .list<-: orderdict->list\n  .sexp<-: (lambda (x) `(list->orderdict ,(orderdict->list x)))\n  .=?: (lambda (a b) (orderdict=? a b)))\n")
    (write-text (string-append test-dir "/dict-test.ss")
                ";;; -*- Gerbil -*-\n(import :std/test ../src/orders/dict)\n(def (table-contract-tests adapter) adapter)\n(def order-dict-test\n  (test-suite \"order dict\"\n    (test-case \"adapter contract witness\"\n      (check (table-contract-tests (OrderDict. String)) => (OrderDict. String)))))\n")))
;; Unit <- String
(def (write-check-changed-project root)
  (let* ((src (string-append root "/src"))
         (changed (string-append src "/changed"))
         (stable (string-append src "/stable")))
    (reset-fixture-root root)
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir changed)
    (ensure-dir stable)
    (write-text (string-append changed "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/changed)\n(def changed-value 1)\n")
    (write-text (string-append stable "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/stable)\n(def stable-value 1)\n")))
;; InitializeGitFixture <- String
(def (initialize-git-fixture root)
  (run-git root ["init"])
  (run-git root ["config" "user.email" "gerbil-harness@example.invalid"])
  (run-git root ["config" "user.name" "Gerbil Harness Test"])
  (run-git root ["add" "."])
  (run-git root ["commit" "-m" "baseline"]))
;; RunGit <- String (List XX)
(def (run-git root args)
  (void
   (run-process (cons "git" args)
                directory: root
                stderr-redirection: #t)))
;; ResetFixtureRoot <- String
(def (reset-fixture-root root)
  (when (file-exists? root)
    (void
     (run-process ["rm" "-rf" root]
                  stderr-redirection: #t))))
;; String <- String
(def (write-functional-idiom-control-context-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/facade.ss")
                ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export drain)\n")
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export drain)\n(def (drain xs)\n  (let/cc stop\n    (let loop ((rest xs))\n      (if (null? rest) (stop #f) (loop (cdr rest)))))\n  (try (void) (finally (void))))\n")))
;; Unit <- String Allowed
(def (write-macro-runtime-source-project root allowed?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/macros")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (if allowed?
      (write-text (string-append root "/gerbil.pkg")
                  "(package: sample/macros\n  policy: ((macro-governance allow-generated: #t explanation: \"Macro transformer edits are allowed only with runtime-source and expansion evidence.\" witness: \"search runtime-source macro sugar module-sugar\")))\n")
      (delete-file-if-exists (string-append root "/gerbil.pkg")))
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/macros)\n(defsyntax (with-order stx)\n  #'(void))\n")))
;; String <- String Declared
(def (write-protocol-evidence-project root declared?)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/protocol.ss")
                (string-append
                 ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/protocol)\n"
                 (if declared? "(defprotocol <Renderable>)\n" "")
                 "(defgeneric :render)\n"
                 "(defmethod (:render (value <Renderable>)) value)\n"))))
;; EnsureDir <- String
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; Unit <- String SourceLine
(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))
;; DeleteFileIfExists <- String
(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))
;; Unit <- String OwnerName
(def (write-large-policy-source root owner-name)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/" owner-name))
         (source-path (string-append owner "/core.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n;;; Large source leaf.\n" port)
        (let lp ((index 0))
          (when (fx< index 45)
            (display "(def value" port)
            (display index port)
            (display " " port)
            (display index port)
            (display ")\n" port)
            (lp (fx1+ index))))
        (let lp ((index 0))
          (when (fx< index 610)
            (display ";; padding\n" port)
            (lp (fx1+ index))))))))
;; Unit <- String OwnerName
(def (write-large-policy-test root owner-name)
  (write-padded-policy-test root owner-name 650))
;; Unit <- String OwnerName PaddingLineCount
(def (write-padded-policy-test root owner-name padding-line-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test (test-suite \"" port)
        (display owner-name port)
        (display "\"))\n" port)
        (let lp ((index 0))
          (when (fx< index padding-line-count)
            (display ";; generated replay padding\n" port)
            (lp (fx1+ index))))))))
;; Unit <- String OwnerName TestCaseCount
(def (write-complex-policy-test root owner-name test-case-count)
  (let* ((test-dir (string-append root "/t"))
         (source-path (string-append test-dir "/" owner-name "-test.ss")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir test-dir)
    (with-catch
     (lambda (_) #f)
     (lambda () (delete-file source-path)))
    (call-with-output-file source-path
      (lambda (port)
        (display ";;; -*- Gerbil -*-\n(import :std/test)\n" port)
        (display "(def " port)
        (display owner-name port)
        (display "-test\n  (test-suite \"" port)
        (display owner-name port)
        (display "\"\n" port)
        (let lp ((index 0))
          (when (fx< index test-case-count)
            (display "    (test-case \"case-" port)
            (display index port)
            (display "\" (check " port)
            (display index port)
            (display " => " port)
            (display index port)
            (display "))\n" port)
            (lp (fx1+ index))))
        (display "    ))\n" port)))))
