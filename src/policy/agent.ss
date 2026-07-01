;;; -*- Gerbil -*-
;;; Agent-facing policy checks over facade intent comments.

(import :gerbil/gambit
        :parser/facade
        :policy/agent-basic
        :policy/agent-macro-protocol
        :policy/agent-alist-access
        :policy/agent-anonymous-pair
        :policy/agent-build
        :policy/agent-build-runtime
        :policy/agent-comment
        :policy/agent-dependency-adapter
        :policy/agent-import
        :policy/agent-list-growth
        :policy/agent-list-random-access
        :policy/agent-macro-io
        :policy/agent-string-growth
        :policy/agent-poo
        :policy/agent-source-scope
        :policy/agent-style
        :policy/agent-support
        :policy/gerbil-utils-source
        :policy/model
        :policy/modularity
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/1 take)
        (only-in :std/srfi/13
                 string-contains
                 string-prefix?
                 string-suffix?
                 string-trim)
        (only-in :std/sugar cut filter filter-map find hash ormap while with-catch)
        :types/findings)

(export run-agent-policy
        facade-intent-finding
        generic-owner-segment
        generic-owner-finding
        vague-definition-finding
        top-level-executable-finding
        functional-idiom-advice-finding
        poo-direct-writeenv-finding
        poo-io-runtime-witness-finding
        poo-object-model-finding
        poo-method-shape-finding
        poo-prototype-fixed-point-finding
        poo-documentation-usage-finding
        macro-runtime-source-witness-finding
        protocol-evidence-finding
        typed-combinator-style-finding
        comment-quality-finding
        controlled-branch-shape-finding
        predicate-family-combinator-finding
        dependency-protocol-adapter-finding
        explicit-precise-import-finding
        package-build-responsibility-finding
        build-runtime-quality-finding
        policy-source-scope-finding
        alist-access-finding
        anonymous-pair-access-finding
        list-growth-loop-performance-finding
        list-random-access-loop-performance-finding
        string-growth-loop-performance-finding
        macro-expansion-io-boundary-finding
        facade-export-conflict-findings)
;;; Agent policy aggregation boundary:
;;; - Specific semantic/style rules run before self-audit rules.
;;; - Self-audit findings then catch policy implementation shortcuts such as
;;;   path-scope hardcoding and repeated inline alist lookup.
;;; - Export conflict checks remain last because they compare accumulated facade bindings.
;; : (-> ProjectIndex (List TypeFinding) )
(def (run-agent-policy index)
  (append
   (facade-intent-findings index)
   (generic-owner-findings index)
   (vague-definition-findings index)
   (top-level-executable-findings index)
   (functional-idiom-advice-findings index)
   (poo-direct-writeenv-findings index)
   (poo-io-runtime-witness-findings index)
   (poo-object-model-findings index)
   (poo-method-shape-findings index)
   (poo-prototype-fixed-point-findings index)
   (poo-construction-performance-findings index)
   (poo-generated-receipt-boundary-findings index)
   (poo-clone-override-loop-performance-findings index)
   (poo-materialization-loop-performance-findings index)
   (poo-composition-loop-performance-findings index)
   (poo-validation-loop-performance-findings index)
   (poo-lens-loop-performance-findings index)
   (poo-object-construction-loop-performance-findings index)
   (poo-type-construction-loop-performance-findings index)
   (poo-debug-instrumentation-loop-performance-findings index)
   (poo-slot-spec-mutation-loop-performance-findings index)
   (poo-slot-predicate-loop-performance-findings index)
   (poo-documentation-usage-findings index)
   (list-growth-loop-performance-findings index)
   (list-random-access-loop-performance-findings index)
   (string-growth-loop-performance-findings index)
   (macro-expansion-io-boundary-findings index)
   (macro-runtime-source-witness-findings index)
   (protocol-evidence-findings index)
   (typed-combinator-style-findings index)
   (comment-quality-findings index)
   (controlled-branch-shape-findings index)
   (predicate-family-combinator-findings index)
   (dependency-protocol-adapter-findings index)
   (explicit-precise-import-findings index)
   (package-build-responsibility-findings index)
   (package-build-canonical-shape-findings index)
   (build-runtime-quality-findings index)
   (policy-source-scope-findings index)
   (alist-access-findings index)
   (anonymous-pair-access-findings index)
   (facade-export-conflict-findings index)))
