;;; -*- Gerbil -*-
;;; Project-local Gerbil capability posture facts for agent steering.

(import :language/evidence
        :parser/facade
        :policy/catalog
        (only-in :std/srfi/13 string-contains)
        :support/list)

(export capability-posture-facts
        matching-capability-posture-facts)
;;; Boundary:
;;; - matching-capability-posture-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Fact) <- ProjectIndex (List XX)
(def (matching-capability-posture-facts index terms)
  (filter (cut capability-posture-matches-terms? <> terms)
          (capability-posture-facts index)))
;;; Boundary:
;;; - capability-posture-facts composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List Fact) <- ProjectIndex
(def (capability-posture-facts index)
  (let* ((files (project-index-files index))
         (package (project-index-package index))
         (dependencies (if package (project-package-dependencies package) '()))
         (macro-facts (append-map source-file-macros files))
         (binding-facts (append-map source-file-bindings files))
         (poo-facts (append-map source-file-poo-forms files))
         (higher-order-facts (append-map source-file-higher-order-forms files))
         (control-flow-facts (append-map source-file-control-flow-forms files))
         (module-imports (append-map source-file-module-imports files))
         (poo-active? (or (pair? poo-facts)
                          (dependency-contains? dependencies "gerbil-poo"))))
    [(capability-posture-fact
      "package-module-posture"
      "package-module"
      (if (or package (pair? module-imports)) "active" "weak")
      "Gerbil package/module/namespace/import facts should preserve project module shape instead of flattening into small-Scheme files."
      "parser-owned-package-and-module-facts"
      "search owner <path> --workspace . --view seeds"
      ["capability" "posture" "package" "module" "namespace" "import" "export"]
      (hash (files (length files))
            (package (if package (project-package-name package) #f))
            (packagePath (if package (project-package-path package) #f))
            (imports (length module-imports)))
      []
      ["package-module-style"]
      "agent-edits-gerbil-package-module"
      "keep-package-namespace-import-export-style-and-query-owner-before-editing")
     (capability-posture-fact
      "macro-posture"
      "macro"
      (if (pair? macro-facts) "active" "available")
      "Macro edits require parser facts plus runtime-source witness; do not write transformers from dialect memory."
      "parser-owned-macro-facts-and-runtime-source-route"
      "search runtime-source macro sugar"
      ["capability" "posture" "macro" "defsyntax" "defrule" "runtime-source" "hygienic"]
      (hash (macros (length macro-facts))
            (macroSelectors (take* (map macro-fact-selector macro-facts) 8)))
      ["GERBIL-SCHEME-AGENT-R011"]
      ["macro-runtime-source-witness" "parser-owned-macro-heads"]
      "agent-edits-macro-or-syntax-transformer"
      "cite-runtime-source-and-parser-macro-fact-before-changing-transformers")
     (capability-posture-fact
      "poo-posture"
      "poo"
      (cond
       ((pair? poo-facts) "active")
       (poo-active? "dependency-active")
       (else "inactive"))
      "POO dependency or parser POO forms should steer object modeling toward defclass/defgeneric/defmethod/protocol evidence."
      "package-dependency-and-parser-owned-poo-facts"
      "search pattern poo class"
      ["capability" "posture" "poo" "object" "defclass" "defgeneric" "defmethod" "protocol" "gerbil-poo"]
      (hash (dependencies dependencies)
            (pooForms (length poo-facts))
            (pooSelectors (take* (map poo-form-fact-selector poo-facts) 8)))
      ["GERBIL-SCHEME-AGENT-R008" "GERBIL-SCHEME-AGENT-R012"]
      ["poo-method-shape" "protocol-evidence" "manual-object-encoding-opportunity"]
      "agent-models-objects-or-protocols-in-gerbil"
      "prefer-defclass-defgeneric-defmethod-or-protocol-when-poo-capability-is-active")
     (capability-posture-fact
      "higher-order-posture"
      "higher-order"
      (if (pair? higher-order-facts) "active" "available")
      "Pure data transforms should prefer Gerbil higher-order and functional combinators before introducing manual loops."
      "parser-owned-higher-order-facts"
      "search structural --workspace . --view seeds"
      ["capability" "posture" "higher-order" "map" "filter" "fold" "for/fold" "cut" "functional"]
      (hash (higherOrderForms (length higher-order-facts))
            (higherOrderSelectors (take* (map higher-order-fact-selector higher-order-facts) 8)))
      ["GERBIL-SCHEME-AGENT-R009"]
      ["functional-data-transform" "typed-combinator-style"]
      "agent-writes-data-transform-or-loop"
      "use-map-filter-fold-for-fold-cut-for-pure-transforms")
     (capability-posture-fact
      "control-flow-posture"
      "control-flow"
      (if (pair? control-flow-facts) "active" "available")
      "Named control-flow facts identify where loops are IO/state/generator drivers rather than pure data transforms."
      "parser-owned-control-flow-facts"
      "search structural --workspace . --view seeds"
      ["capability" "posture" "control-flow" "named-let" "loop" "generator" "state" "driver"]
      (hash (controlFlowForms (length control-flow-facts))
            (controlFlowSelectors (take* (map control-flow-fact-selector control-flow-facts) 8)))
      ["GERBIL-SCHEME-AGENT-R009"]
      ["manual-loop-functional-advice" "stateful-driver-exception"]
      "agent-edits-loop-or-driver"
      "preserve-named-let-for-io-state-generator-continuation-drivers")
     (capability-posture-fact
      "configurable-interface-posture"
      "configurable-interface"
      (configurable-interface-status package)
      "Downstream projects can override source scope and agent policy through gerbil.pkg policy without redeclaring built-in defaults."
      "parser-owned-gerbil.pkg-and-build.ss-policy"
      "info --json ."
      ["capability" "posture" "configurable" "interface" "source-scope" "agent-policy" "gerbil.pkg" "build.ss"]
      (hash (sourceScope (source-scope-status package))
            (agentPolicy (agent-policy-status package))
            (dependencies dependencies))
      []
      ["downstream-policy-override" "build-ss-runtime-root-fallback"]
      "agent-configures-downstream-project-harness"
      "use-gerbil.pkg-policy-overrides-only-when-project-declares-them")
     (capability-posture-fact
      "quality-closure-posture"
      "quality-closure"
      "declared-closure"
      "Agent-facing Gerbil engineering quality is closed through info, guide, check, self-apply, structural snapshots, and bench receipts."
      "info-owned-closure-commands-plus-parser-owned-policy-facts"
      "info --json ."
      ["capability" "posture" "quality" "closure" "engineering-quality" "agent-steering" "policy" "guide" "check" "self-apply" "bench" "snapshot" "search-projection" "source-class"]
      (hash (files (length files))
            (definitions (length (project-definitions index)))
            (agentRules (agent-steering-rule-ids))
            (facts (agent-steering-facts))
            (closures ["info" "guide" "check" "self-apply" "bench" "structural-snapshot"]))
      (agent-steering-rule-ids)
      ["policy-covered" "guide-covered" "snapshot-covered" "bench-covered" "check-covered" "self-apply-covered" "source-class-covered"]
      "agent-assesses-gerbil-project-quality-before-editing"
      "query-capability-posture-and-run-closure-commands-before-claiming-quality")]))
;; Fact <- String Capability Status Summary Witness Next (List XX) Counts PolicyRules QualitySignals AgentScenario String
(def (capability-posture-fact id capability status summary witness next terms counts
                              policy-rules quality-signals agent-scenario intent)
  (evidence-fact
   id
   summary
   "fact"
   witness
   next
   terms
   (hash (capability capability)
         (status status)
         (counts counts)
         (policyRules policy-rules))
   []
   agent-scenario
   intent
   quality-signals
   [(hash (id "basic-scheme-fallback")
          (risk "agent-writes-generic-scheme-shape-when-gerbil-project-facts-expose-stronger-engineering-capability")
          (correction "query-capability-posture-and-structural-facts-before-editing"))]))
;;; Boundary:
;;; - capability-posture-matches-terms? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- CapabilityPosture (List SearchTerm)
(def (capability-posture-matches-terms? fact terms)
  (or (null? terms)
      (ormap (lambda (term)
               (or (string-contains (hash-get fact 'id) term)
                   (string-contains (hash-get (hash-get fact 'details) 'capability) term)
                   (ormap (cut string-contains <> term)
                          (hash-get fact 'terms))))
             terms)))
;;; Boundary:
;;; - append-map composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Integer <- (YY <- XX) (List XX)
(def (append-map proc xs)
  (apply append (map proc xs)))
;;; Boundary:
;;; - dependency-contains? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- (List DependencyName) DependencyNeedle
(def (dependency-contains? dependencies needle)
  (ormap (cut string-contains <> needle) dependencies))
;; Status <- Package
(def (configurable-interface-status package)
  (cond
   ((not package) "builtin-defaults")
   ((or (project-package-source-scope-policy package)
        (project-package-agent-policy package))
    "project-overridden")
   (else "builtin-defaults")))
;; String <- Package
(def (source-scope-status package)
  (let (policy (and package (project-package-source-scope-policy package)))
    (if policy
      (hash (status "project-overridden")
            (roots (source-scope-policy-roots policy))
            (runtimeRoots (source-scope-policy-runtime-roots policy))
            (excludeDirectories (source-scope-policy-exclude-directories policy))
            (explanation (source-scope-policy-explanation policy)))
      (hash (status "builtin-defaults")
            (roots ["."])
            (runtimeRoots [])
            (excludeDirectories [])
            (explanation "Builtin source-scope defaults apply unless gerbil.pkg policy overrides them.")))))
;; Status <- Package
(def (agent-policy-status package)
  (let (policy (and package (project-package-agent-policy package)))
    (if policy
      (hash (status "project-overridden")
            (enabledRules (agent-policy-enabled-rules policy))
            (disabledRules (agent-policy-disabled-rules policy)))
      (hash (status "builtin-defaults")
            (enabledRules [])
            (disabledRules [])))))
