;;; -*- Gerbil -*-
;;; Policy tests for gerbil-utils/base.ss-style higher-order abstraction.

(import :std/test
        :std/srfi/13
        :parser/facade
        :policy/facade
        :types/facade
        :policy/fixtures)

(export agent-style-higher-order-policy-test)

;; PolicyTest
(def agent-style-higher-order-policy-test
  (test-suite "gerbil scheme harness higher-order style policy"
    (test-case "agent policy warns on repeated wrapper lambdas without a combinator boundary"
          (let* ((root ".run/policy-wrapper-lambda-drift")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/facade.ss")
                        ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export decorate)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export decorate)\n;; : (-> String String (-> String String))\n(def (decorate prefix suffix)\n  (let ((left (lambda (text) (string-append prefix text)))\n        (right (lambda (text) (string-append text suffix))))\n    (lambda (text) (right (left text)))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (type-finding-severity finding) => "warning")
              (check (hash-get details 'qualityRepairTriggered) => #t)
              (check (not (not (member "wrapper-lambda-drift"
                                       (hash-get details 'qualityFacets))))
                     => #t)
              (check (not (not (member "function-specialization-opportunity"
                                       (hash-get details 'qualityFacets))))
                     => #t)
              (check (not (not (member "extract repeated wrapper lambdas into a named factory, case-lambda function factory, curry/rcurry specializer, or compose/rcompose pipeline"
                                       (hash-get details 'qualityFacetSteering))))
                     => #t)
              (check (not (not (string-contains
                                (type-finding-message finding)
                                "quality facets require repair")))
                     => #t))))
    (test-case "agent policy keeps case-lambda function factory as gerbil-utils style evidence"
          (let* ((root ".run/policy-case-lambda-factory")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/facade.ss")
                        ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export decorate)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export decorate)\n;; : (-> String String (-> String String))\n(def decorate\n  (case-lambda\n    ((prefix) (lambda (text) (string-append prefix text)))\n    ((prefix suffix) (lambda (text) (string-append prefix text suffix)))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R013" findings)))
              (check matching => []))))
    (test-case "agent policy warns on multi-arity nested boolean predicates"
          (let* ((root ".run/policy-boolean-predicate-combinator")
                 (src (string-append root "/src"))
                 (owner (string-append src "/orders")))
            (ensure-dir ".run")
            (ensure-dir root)
            (ensure-dir src)
            (ensure-dir owner)
            (write-text (string-append root "/gerbil.pkg")
                        "(package: sample/orders)\n")
            (write-text (string-append owner "/facade.ss")
                        ";;; -*- Gerbil -*-\n;;; Orders facade intent.\n(export path-matches-token?)\n")
            (write-text
             (string-append owner "/core.ss")
             ";;; -*- Gerbil -*-\n(package: sample/orders)\n(export path-matches-token?)\n;; : (-> Path String Boolean)\n(def (path-matches-token? relpath token)\n  (or (string-prefix? (string-append token \"/\") relpath)\n      (string-contains relpath (string-append \"/\" token \"/\"))\n      (string-suffix? (string-append \"/\" token) relpath)\n      (and (not (string-contains token \"/\"))\n           (string-contains relpath token))))\n")
            (let* ((index (collect-project root))
                   (findings (run-agent-policy index))
                   (matching (filter-rule "GERBIL-SCHEME-AGENT-R016" findings))
                   (finding (car matching))
                   (details (type-finding-details finding)))
              (check (length matching) => 1)
              (check (type-finding-path finding) => "src/orders/core.ss")
              (check (type-finding-selector finding) => "src/orders/core.ss:5-10")
              (check (hash-get details 'styleGuide)
                     => "predicate-family-combinator")
              (check (hash-get details 'evidenceSource)
                     => "parser-owned booleanConditionFacts")
              (check (hash-get details 'conditionCount) => 6)
              (check (if (member "string-prefix?"
                                 (hash-get details 'conditionCallees))
                       #t
                       #f)
                     => #t)
              (check (if (member "string-suffix?"
                                 (hash-get details 'conditionCallees))
                       #t
                       #f)
                     => #t))))))
