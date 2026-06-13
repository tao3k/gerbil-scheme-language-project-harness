;;; -*- Gerbil -*-
;;; Gerbil language/runtime/std evidence facts for agent-facing search.

(import :std/srfi/13)

(export runtime-bin
        evidence-fact
        active-runtime-facts
        runtime-source-facts
        language-rule-facts
        standard-library-facts
        hygienic-macro-pattern-evidence
        hygienic-macro-pattern-query?
        hygienic-macro-minimal-forms
        hygienic-macro-failure-cases)

(def (runtime-bin name)
  (let ((default-bin (path-expand (string-append "bin/" name) (gerbil-home)))
        (sibling-bin (path-expand (string-append "../bin/" name) (gerbil-home))))
    (if (file-exists? default-bin) default-bin sibling-bin)))

(def (gerbil-runtime-tag version-string)
  (let (start (string-index version-string #\v))
    (and start
         (let* ((tail (substring version-string start (string-length version-string)))
                (end (string-index tail #\space)))
           (if end (substring tail 0 end) tail)))))

(def (evidence-fact id summary evidence-grade witness next terms details selectors
                    agent-scenario intent quality-signals failure-cases)
  (hash (id id)
        (summary summary)
        (evidenceGrade evidence-grade)
        (witness witness)
        (next next)
        (terms terms)
        (details details)
        (selectors selectors)
        (agentScenario agent-scenario)
        (intent intent)
        (qualitySignals quality-signals)
        (failureCases failure-cases)))

(def (active-runtime-facts)
  (let* ((home (path-normalize (gerbil-home)))
         (gxi (path-normalize (runtime-bin "gxi")))
         (gsc (path-normalize (runtime-bin "gsc")))
         (paths (map path-normalize (load-path)))
         (witness (if (and (file-exists? gxi) (file-exists? gsc))
                    "gerbil-home-gxi-gsc-load-path-resolved"
                    "gerbil-home-load-path-resolved")))
    [(evidence-fact
      "active-gerbil-runtime"
      "Active Gerbil runtime discovered from the executing provider process."
      "fact"
      witness
      "search env load-path"
      ["env" "runtime" "gxi" "gsc" "gerbil-home" "load-path" home gxi gsc]
      (hash (gerbilHome home)
            (gxi gxi)
            (gsc gsc)
            (gxiExists (file-exists? gxi))
            (gscExists (file-exists? gsc))
            (loadPath paths))
      []
      "agent-needs-active-gerbil-runtime-before-import-or-macro-claims"
      "discover-active-gxi-gsc-and-load-path-before-writing-gerbil-code"
      ["active-gxi" "active-gsc" "runtime-load-path"]
      [(hash (id "stale-doc-runtime")
             (risk "agent-trusts-online-gerbil-version-instead-of-active-gxi")
             (correction "query-search-env-before-version-or-import-guidance"))
       (hash (id "global-path-hardcoding")
             (risk "agent-copies-user-machine-path-into-project-docs-or-code")
             (correction "treat-runtime-path-as-evidence-not-project-config"))])]))

(def (runtime-source-facts)
  (let* ((home (path-normalize (gerbil-home)))
         (gxi (path-normalize (runtime-bin "gxi")))
         (version-string (gerbil-system-version-string))
         (tag (or (gerbil-runtime-tag version-string) "unknown-runtime-tag")))
    [(evidence-fact
      "gerbil-runtime-source"
      "Gerbil language facts must come from a source checkout matched to the active runtime version."
      "fact"
      "active-runtime-version-to-source-acquisition-plan"
      "search runtime-source macro sugar module-sugar"
      ["runtime-source" "source" "source-facts" "runtime" "version" "clone" "checkout" "macro" "gerbil" "std" "sugar" "std/sugar" "defrule" "defsyntax-call" "module-sugar" "module" "import" "export" "only-in" "except-in" "rename-in" "rename-out" "for-syntax" tag version-string]
      (hash (runtime (hash (gerbilHome home)
                           (gxi gxi)
                           (systemVersion version-string)
                           (tag tag)))
            (sourceRef (hash (kind "runtime-version-source")
                             (manager "git")
                             (repository "https://git.cons.io/mighty-gerbils/gerbil")
                             (checkout tag)
                             (checkoutPolicy "exact-tag-from-active-runtime")
                             (statePathPolicy "asp-state-managed")
                             (selectorScheme "runtime-source-owner-selector")))
            (acquisition (hash (owner "asp")
                               (operation "clone-or-fetch-checkout-index")
                               (stateNamespace "runtime-source/gerbil-scheme")
                               (versionKey tag)
                               (indexOwner "asp-structural-index")))
            (nextSearch "search runtime-source macro sugar module-sugar"))
      []
      "agent-needs-gerbil-macro-facts-from-versioned-source"
      "clone-active-runtime-source-before-answering-language-or-macro-usage"
      ["no-memory" "version-matched-source" "asp-state-managed-checkout" "source-index-required"]
      [(hash (id "memory-language-answer")
             (risk "agent-answers-gerbil-language-usage-from-training-memory")
             (correction "acquire-runtime-source-and-search-source-facts"))
       (hash (id "wrong-runtime-version")
             (risk "agent-uses-source-from-a-different-gerbil-version")
             (correction "checkout-source-tag-derived-from-active-runtime"))
       (hash (id "unindexed-source-checkout")
             (risk "agent-clones-source-but-searches-it-with-raw-grep")
             (correction "index-checkout-through-asp-before-agent-facing-search"))])
     (evidence-fact
      "gerbil-runtime-writeenv-source"
      "Gerbil writeenv and printer hook guidance must come from the active runtime source before POO :wr roundtrip claims."
      "fact"
      "active-runtime-version-to-writeenv-source-acquisition-plan"
      "search runtime-source writeenv printer hook"
      ["runtime-source" "source" "runtime" "version" "writeenv" "printer" "printer-hook" "hook" "write" "write-object" ":wr" "wr" "poo" "io" "serialization" tag version-string]
      (hash (runtime (hash (gerbilHome home)
                           (gxi gxi)
                           (systemVersion version-string)
                           (tag tag)))
            (sourceRef (hash (kind "runtime-version-source")
                             (manager "git")
                             (repository "https://git.cons.io/mighty-gerbils/gerbil")
                             (checkout tag)
                             (checkoutPolicy "exact-tag-from-active-runtime")
                             (statePathPolicy "asp-state-managed")
                             (selectorScheme "runtime-source-owner-selector")))
            (acquisition (hash (owner "asp")
                               (operation "clone-or-fetch-checkout-index")
                               (stateNamespace "runtime-source/gerbil-scheme")
                               (versionKey tag)
                               (indexOwner "asp-structural-index")))
            (nextSearch "search runtime-source writeenv printer hook"))
      [(hash (role "writeenv-builtin")
             (symbol "writeenv")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/builtin.ssxi.ss#writeenv"))
       (hash (role "core-writeenv-binding")
             (symbol "writeenv")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/core.ssi#writeenv"))
       (hash (role "runtime-write-object-owner")
             (symbol "write-object")
             (selector "gerbil-runtime-source://src/bootstrap/gerbil/core/runtime.ssi#write-object"))]
      "agent-needs-runtime-printer-hook-facts-before-poo-writeenv-roundtrip-claims"
      "query-versioned-runtime-writeenv-and-write-object-source-before-promoting-poo-io-to-verified"
      ["no-memory" "version-matched-source" "asp-state-managed-checkout" "writeenv-source-index-required" "printer-hook-source-required"]
      [(hash (id "memory-writeenv-answer")
             (risk "agent-answers-writeenv-or-printer-hook-behavior-from-training-memory")
             (correction "acquire-active-runtime-source-and-query-writeenv-selectors"))
       (hash (id "poo-writeenv-roundtrip-assumption")
             (risk "agent-promotes-poo-io-pattern-to-verified-without-runtime-writeenv-roundtrip-witness")
             (correction "keep-poo-io-partial-until-runtime-source-backed-roundtrip-witness-exists"))
       (hash (id "raw-runtime-source-search")
             (risk "agent-clones-gerbil-source-but-searches-it-with-raw-grep")
             (correction "use-asp-managed-runtime-source-index-before-agent-facing-search"))])]))

(def (language-rule-facts)
  [(evidence-fact
    "hygienic-macro"
    "Gerbil macros are syntax objects expanded by the active Gerbil expander; macro guidance must route through parser/runtime witnesses."
    "fact"
    "provider-loads-macro-forms-and-parser-witnesses"
    "search pattern hygienic-macro"
    ["lang" "macro" "hygienic" "hygienic-macro" "defsyntax" "syntax-case" "syntax-rules"]
    (hash (rule "hygienic-macro")
          (authority "language-rules"))
    [(hash (role "macro-form-parser")
           (symbol "defsyntax")
           (selector "src/checker/forms.ss:13"))]
    "agent-does-not-know-gerbil-macro-phase-rules"
    "route-macro-questions-through-parser-and-generated-code-policy"
    ["parser-owned-macro-heads" "forbidden-form-policy" "pattern-route"]
    [(hash (id "generated-code-forbidden-form")
           (risk "agent-blindly-emits-defsyntax-or-syntax-case-in-generated-code")
           (correction "use-parser-witness-and-policy-check-before-writing-macro-forms"))
     (hash (id "racket-macro-assumption")
           (risk "agent-mixes-racket-macro-examples-with-gerbil-code")
           (correction "query-gerbil-pattern-and-owner-selectors-first"))])
   (evidence-fact
    "module-import"
    "Gerbil module imports are resolved through the active load path and module-sugar import/export sets; project guidance must include runtime source when import set syntax matters."
    "fact"
    "runtime-source-module-sugar-import-export-sets"
    "search runtime-source module-sugar"
    ["lang" "module" "import" "export" "load-path" "package" "module-sugar" "only-in" "except-in" "rename-in" "prefix-in" "rename-out" "for-syntax" "for-template"]
    (hash (rule "module-import")
          (authority "language-rules")
          (runtimeSourceSelector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss"))
    [(hash (role "import-filter")
           (symbol "only-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#only-in"))
     (hash (role "import-filter")
           (symbol "except-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#except-in"))
     (hash (role "import-rename")
           (symbol "rename-in")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-in"))
     (hash (role "phase-import")
           (symbol "for-syntax")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#for-syntax"))
     (hash (role "export-rename")
           (symbol "rename-out")
           (selector "gerbil-runtime-source://src/gerbil/core/module-sugar.ss#rename-out"))]
    "agent-does-not-know-gerbil-module-load-path-resolution"
    "query-active-load-path-and-module-sugar-source-before-adding-imports-or-exports"
    ["load-path-policy" "runtime-route" "module-sugar-source" "import-set-witness" "export-set-witness"]
    [(hash (id "missing-load-path")
           (risk "agent-adds-import-that-current-gxi-cannot-resolve")
           (correction "query-search-env-load-path-before-editing-imports"))
     (hash (id "racket-require-assumption")
           (risk "agent-uses-racket-require-forms-in-gerbil-imports")
           (correction "use-gerbil-module-sugar-selectors-for-only-in-except-in-rename-in"))
     (hash (id "unchecked-rename-in")
           (risk "agent-renames-an-identifier-that-is-not-in-the-import-set")
           (correction "use-rename-in-witness-that-checks-identifier-membership"))
     (hash (id "rename-out-confusion")
           (risk "agent-confuses-import-renaming-with-export-renaming")
           (correction "use-rename-in-for-imports-and-rename-out-for-exports"))])
   (evidence-fact
    "scheme-style"
    "Gerbil code quality guidance should follow domain owners, t/ test owners, directional data-flow names, and named control-flow helpers."
    "fact"
    "gerbil-utils-style-audit-and-harness-policy"
    "search lang style"
    ["lang" "style" "quality" "tests" "t" "owner" "domain" "data-flow" "control-flow" "gerbil-utils"]
    (hash (rule "scheme-style")
          (authority "language-rules")
          (reference "https://git.cons.io/mighty-gerbils/gerbil-utils")
          (testDirectory "t")
          (policyRules ["GERBIL-SCHEME-MOD-R006"
                        "GERBIL-SCHEME-AGENT-R004"
                        "GERBIL-SCHEME-AGENT-R005"])
          (styleDoc "docs/10-19-rfcs/10.05-cli-first-harness-ux/10.05.90-gerbil-scheme-style-conventions.org"))
    [(hash (role "style-reference")
           (symbol "generating<-list")
           (selector "gerbil-utils://generator.ss#generating<-list"))
     (hash (role "test-layout-reference")
           (symbol "assq-test")
           (selector "gerbil-utils://pure/dict/t/assq-test.ss#assq-test"))
     (hash (role "root-test-layout-reference")
           (symbol "base-test")
           (selector "gerbil-utils://t/base-test.ss#base-test"))]
    "agent-needs-high-quality-gerbil-code-conventions"
    "prefer-domain-owners-t-tests-directional-data-flow-and-named-control-flow"
    ["domain-owner-names" "t-test-layout" "real-project-t-tests" "directional-data-flow-names" "named-control-flow-helpers" "vague-definition-policy" "top-level-executable-policy"]
    [(hash (id "legacy-test-directory")
           (risk "agent-creates-top-level-test-directory-for-gerbil-unit-tests")
           (correction "use-t-directory-and-native-std-test-suites"))
     (hash (id "generic-owner-name")
           (risk "agent-creates-utils-or-helpers-owner-instead-of-domain-owner")
           (correction "name-the-domain-owner-and-keep-facades-thin"))
     (hash (id "vague-definition-name")
           (risk "agent-writes-helper-process-handle-or-convert-without-domain-semantics")
           (correction "name-the-domain-action-or-use-directional-data-flow-naming"))
     (hash (id "top-level-executable-call")
           (risk "agent-puts-runtime-effects-at-src-top-level-instead-of-a-named-entrypoint")
           (correction "move-executable-call-behind-a-named-definition-or-bin-entrypoint"))
     (hash (id "inline-control-flow")
           (risk "agent-writes-large-inline-continuation-thread-or-generator-block")
           (correction "extract-named-helper-and-cover-it-with-a-native-unit-test"))])])

(def (standard-library-facts)
  [(evidence-fact
    "std/srfi/13"
    "SRFI-13 string procedures are available to the harness and used by search rendering."
    "fact"
    "provider-imports-:std/srfi/13"
    "search std string"
    ["std" "standard-library" "srfi" "srfi-13" "std/srfi/13" "string" "string-contains" "string-prefix"]
    (hash (module ":std/srfi/13")
          (capabilities ["string-contains" "string-prefix?" "string-suffix?"]))
    []
    "agent-does-not-know-gerbil-standard-string-module"
    "use-active-provider-standard-library-fact-instead-of-dialect-memory"
    ["provider-imports-std-module" "string-prefix-capability" "string-contains-capability"]
    [(hash (id "guessed-racket-string-api")
           (risk "agent-imports-or-calls-a-similar-api-from-another-scheme")
           (correction "use-std-srfi-13-fact-and-selector-backed-provider-import"))])
   (evidence-fact
    "std/misc/ports"
    "Port helpers are available to the harness and used for guide/test output capture."
    "fact"
    "provider-imports-:std/misc/ports"
    "search std ports"
    ["std" "standard-library" "ports" "std/misc/ports" "call-with-output-string"]
    (hash (module ":std/misc/ports")
          (capabilities ["call-with-output-string" "read-all-as-string"]))
    []
    "agent-needs-test-output-capture-without-shelling-out"
    "use-gerbil-port-helper-facts-for-unit-test-output-capture"
    ["provider-imports-std-module" "port-capture-capability"]
    [(hash (id "shell-output-capture")
           (risk "agent-spawns-shell-or-temp-files-for-unit-output")
           (correction "use-call-with-output-string-from-std-misc-ports"))])
   (evidence-fact
    "std/text/json"
    "Gerbil JSON parsing is available through :std/text/json; import read-json with only-in when the harness needs machine packet validation."
    "fact"
    "provider-imports-:std/text/json"
    "search std json"
    ["std" "standard-library" "json" "std/text/json" ":std/text/json" "read-json" "only-in"]
    (hash (module ":std/text/json")
          (capabilities ["read-json"])
          (minimalImport "(import (only-in :std/text/json read-json))"))
    []
    "agent-needs-json-packet-validation-without-python-parser"
    "use-gerbil-std-text-json-read-json-with-only-in"
    ["provider-imports-std-module" "read-json-capability" "only-in-minimal-import"]
    [(hash (id "foreign-json-parser")
           (risk "agent-adds-python-or-shell-json-parser-for-gerbil-tests")
           (correction "use-read-json-from-std-text-json"))
     (hash (id "broad-json-import")
           (risk "agent-imports-more-json-surface-than-the-test-needs")
           (correction "use-only-in-std-text-json-read-json"))])
   (evidence-fact
    "std/sugar"
    "Gerbil sugar macros are available through :std/sugar and must be treated as runtime-source-backed macro evidence, not generic Scheme memory."
    "fact"
    "runtime-source-std-sugar-defrule-and-defsyntax"
    "search pattern hygienic-macro"
    ["std" "standard-library" "sugar" "std/sugar" ":std/sugar" "defrule" "defsyntax" "syntax-call" "defsyntax-call" "for-syntax"]
    (hash (module ":std/sugar")
          (capabilities ["defrule" "defsyntax" "syntax-call" "defsyntax-call"])
          (runtimeSourceSelector "gerbil-runtime-source://src/std/sugar.ss"))
    [(hash (role "std-sugar-source")
           (symbol "defrule")
           (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
     (hash (role "std-sugar-source")
           (symbol "defsyntax-call")
           (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
     (hash (role "std-sugar-import")
           (symbol "for-syntax")
           (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))]
    "agent-needs-gerbil-sugar-macro-facts-from-versioned-source"
    "search-runtime-source-std-sugar-before-writing-defrule-or-defsyntax-call"
    ["runtime-source-backed-std-module" "macro-sugar-capability" "for-syntax-import-witness"]
    [(hash (id "generic-scheme-rule-macro")
           (risk "agent-assumes-defrule-or-syntax-call-shape-from-another-scheme")
           (correction "query-std-sugar-and-runtime-source-before-writing-sugar-macros"))
     (hash (id "missing-for-syntax-import")
           (risk "agent-writes-macro-helper-without-phase-specific-import-evidence")
           (correction "use-std-sugar-for-syntax-import-witness"))])
   (evidence-fact
    "std/test"
    "Gerbil test support is the harness unit-test surface."
    "fact"
    "test-suite-loads-:std/test"
    "search std test"
    ["std" "standard-library" "test" "std/test" "test-suite" "check"]
    (hash (module ":std/test")
          (capabilities ["test-suite" "test-case" "check"]))
    []
    "agent-needs-native-gerbil-unit-test-interface"
    "use-std-test-suite-and-check-for-harness-tests"
    ["provider-imports-std-module" "native-test-capability"]
    [(hash (id "foreign-test-framework")
           (risk "agent-adds-python-or-non-gerbil-test-wrapper")
           (correction "use-std-test-native-gerbil-test-suite"))])])

(def (hygienic-macro-pattern-evidence terms)
  (and (hygienic-macro-pattern-query? terms)
       (hash (id "hygienic-macro")
             (extension "gerbil-scheme")
             (focus "syntax-case/defsyntax")
             (sourceRef (hash (kind "provider-source")
                              (manager "native-provider")
                              (package "gerbil-scheme-language-project-harness")
                              (dependency "gerbil-scheme-language-project-harness")
                              (repository "agent-semantic-protocols/languages/gerbil-scheme-language-project-harness")
                              (pathPolicy "repository-relative")
                              (selectorScheme "provider-owner-selector")))
             (sourceOwners ["src/checker/forms.ss"
                            "gerbil-runtime-source://src/std/sugar.ss"])
             (selectors
              [(hash (role "macro-form")
                     (symbol "defsyntax")
                     (selector "src/checker/forms.ss:13"))
               (hash (role "std-sugar-rule-macro")
                     (symbol "defrule")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
               (hash (role "std-sugar-procedural-macro")
                     (symbol "defsyntax-call")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))
               (hash (role "std-sugar-phase-import")
                     (symbol "for-syntax")
                     (selector "gerbil-runtime-source://src/std/sugar.ss#import-for-syntax"))])
             (agentScenario "agent-does-not-know-gerbil-macro-syntax-or-generated-code-policy")
             (intent "recognize-gerbil-macro-surfaces-and-avoid-forbidden-generated-forms")
             (minimalForms (hygienic-macro-minimal-forms))
             (failureCases (hygienic-macro-failure-cases))
             (qualitySignals ["parser-owned-macro-heads"
                              "runtime-source-std-sugar"
                              "for-syntax-import-witness"
                              "generated-code-policy"
                              "test-backed-query"])
             (witness "parser-and-test-backed-hygienic-macro-pattern")
             (next "search lang hygienic-macro"))))

(def (hygienic-macro-minimal-forms)
  [(hash (role "macro-definition")
         (symbol "defsyntax")
         (template (hash (head "defsyntax")
                         (operands ["(<name> stx)" "..."])
                         (keywords [])))
         (selector "src/checker/forms.ss:13"))
   (hash (role "macro-policy")
         (symbol "syntax-case")
         (template (hash (head "policy")
                         (operands ["generated-code"
                                    "must-not-emit-defsyntax-or-syntax-case-without-policy-witness"])
                         (keywords [])))
         (selector "src/checker/forms.ss:13"))
   (hash (role "std-sugar-rule-macro")
         (symbol "defrule")
         (template (hash (head "defrule")
                         (operands ["(<name> arg ...)" "body ..."])
                         (keywords [])))
         (selector "gerbil-runtime-source://src/std/sugar.ss#defrule"))
   (hash (role "std-sugar-procedural-macro")
         (symbol "defsyntax-call")
         (template (hash (head "defsyntax-call")
                         (operands ["<macro-name>" "<syntax-argument> ..."])
                         (keywords [])))
         (selector "gerbil-runtime-source://src/std/sugar.ss#defsyntax-call"))])

(def (hygienic-macro-failure-cases)
  [(hash (id "generated-code-forbidden-form")
         (risk "agent-blindly-emits-defsyntax-syntax-case-or-defrules")
         (correction "run-policy-check-or-route-through-parser-owned-macro-witness"))
   (hash (id "racket-macro-assumption")
         (risk "agent-copies-racket-syntax-case-shape-into-gerbil-code")
         (correction "query-gerbil-lang-and-pattern-before-editing-macro-code"))])

(def (hygienic-macro-pattern-query? terms)
  (and (pair? terms)
       (or (member "hygienic-macro" terms)
           (member "hygienic" terms)
           (member "macro" terms)
           (member "defsyntax" terms)
           (member "syntax-case" terms))))
