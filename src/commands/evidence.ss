;;; -*- Gerbil -*-
;;; Boundary:
;;; - module owns an agent-facing surface.
;;; - Keep contracts, evidence, and failure semantics explicit.
;;; Evidence graph command output.

(import :constants
        :parser/facade
        :protocol/json
        (only-in :std/sugar filter match unless)
        :support/args)

(export evidence-main
        evidence-graph-packet
        evidence-analysis-request-packet)
;; String
(def +evidence-graph-schema-id+
  "agent.semantic-protocols.semantic-evidence-graph")
;; String
(def +evidence-graph-protocol-id+
  "agent.semantic-protocols.evidence-graph")
;; String
(def +graph-turbo-request-schema-id+
  "agent.semantic-protocols.semantic-graph-turbo-request")
;; String
(def +semantic-language-protocol-id+
  "agent.semantic-protocols.semantic-language")
;;; Invariant:
;;; - evidence-main owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; String <- (List String)
(def (evidence-main args)
  (match args
    ([] (error "expected evidence <graph|analyze>"))
    ([action . rest]
     (unless (member action '("graph" "analyze" "analysis"))
       (error "expected evidence <graph|analyze>"))
     (let* ((root (evidence-project-root rest))
            (json? (flag? "--json" rest)))
       (cond
        ((equal? action "graph")
         (let (packet (evidence-graph-packet root))
           (if json?
             (write-json-line packet)
             (display-evidence-graph packet))))
        (else
         (let (packet (evidence-analysis-request-packet root))
           (if json?
             (write-json-line packet)
             (display-evidence-analysis-request packet)))))
       0))))
;; String <- (List String)
(def (evidence-project-root args)
  (let (workspace (option "--workspace" args))
    (if workspace workspace (project-root args))))
;;; Boundary:
;;; - evidence-graph-packet coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; String <- String
(def (evidence-graph-packet root)
  (let* ((index (collect-project root))
         (owner-path (evidence-owner-path index))
         (owner-id (evidence-node-id "gerbil-scheme:owner" owner-path))
         (claim-id (evidence-node-id "gerbil-scheme:claim" owner-path))
         (receipt-id (evidence-node-id "gerbil-scheme:receipt" "gerbil-harness-check-changed"))
         (action-id (evidence-node-id "gerbil-scheme:action" "run-gerbil-harness-check"))
         (gap-id (evidence-node-id "gerbil-scheme:gap" (string-append owner-path ":receipt")))
         (check-command "gerbil-scheme-harness check --changed .")
         (nodes [(evidence-node owner-id "owner" owner-path owner-path "current"
                                (hash (languageId +language-id+)
                                      (source "provider-project")))
                 (evidence-node claim-id "invariant-candidate"
                                "Gerbil Scheme provider behavior needs executable evidence"
                                owner-path "needs-injection"
                                (hash (candidateId "gerbil-scheme.evidence.project-harness")
                                      (sourceRuleId "GERBIL-SCHEME-EVIDENCE-GRAPH")
                                      (receiptKind "harness-check")
                                      (summary "Project-level Gerbil Scheme search and policy behavior should be linked to verification receipts.")))
                 (evidence-node receipt-id "verification-receipt" check-command
                                owner-path "needs-injection"
                                (hash (receiptId "gerbil-scheme.harness.check.changed")
                                      (command check-command)
                                      (summary "Run the Gerbil Scheme harness check and attach the receipt before treating the claim as verified.")))
                 (evidence-node action-id "review-action"
                                "Run gerbil-scheme-harness check --changed ."
                                owner-path "missing"
                                (hash (actionId "gerbil-scheme.run-harness-check")
                                      (priority "p0")
                                      (targetId "gerbil-scheme.evidence.project-harness")
                                      (summary "run-receipt")))])
         (edges [(evidence-edge "gerbil-scheme:edge:owner-claim"
                                "supports-claim" owner-id claim-id)
                 (evidence-edge "gerbil-scheme:edge:claim-receipt"
                                "requires-evidence" claim-id receipt-id)
                 (evidence-edge "gerbil-scheme:edge:action-claim"
                                "requires-evidence" action-id claim-id)])
         (gaps [(hash (gapId gap-id)
                      (ownerPath owner-path)
                      (summary "No attached Gerbil Scheme harness check receipt for this evidence graph.")
                      (severity "warning")
                      (fields (hash (nextCommand check-command))))]))
    (hash
     (schemaId +evidence-graph-schema-id+)
     (schemaVersion "1")
     (protocolId +evidence-graph-protocol-id+)
     (protocolVersion "1")
     (graphId "gerbil-scheme.evidence.graph")
     (producer (evidence-producer))
     (project (evidence-project index))
     (summary (evidence-summary nodes edges gaps))
     (nodes nodes)
     (edges edges)
     (gaps gaps)
     (fields (hash (next "pipe JSON to `asp graph render --packet - --view seeds`"))))))
;;; Boundary:
;;; - evidence-analysis-request-packet coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; String <- String
(def (evidence-analysis-request-packet root)
  (let* ((graph (evidence-graph-packet root))
         (analysis-graph (evidence-analysis-graph graph))
         (graph-summary (hash-get graph 'summary))
         (request-summary (hash
                           (graphs 1)
                           (nodes (hash-get graph-summary 'nodes))
                           (edges (hash-get graph-summary 'edges))
                           (owners (hash-get graph-summary 'owners))
                           (claims (hash-get graph-summary 'claims))
                           (staleItems (hash-get graph-summary 'staleItems))
                           (gaps (hash-get graph-summary 'gaps)))))
    (hash
     (schemaId +graph-turbo-request-schema-id+)
     (schemaVersion "1")
     (protocolId +semantic-language-protocol-id+)
     (protocolVersion "1")
     (packetKind "graph-turbo-request")
     (requestId (string-append
                 "gerbil-scheme.evidence.analysis.graphs-1.nodes-"
                 (number->string (hash-get request-summary 'nodes))
                 ".gaps-"
                 (number->string (hash-get request-summary 'gaps))))
     (surface "evidence-analyze")
     (queryTerms ["gerbil scheme evidence quality"])
     (profile "evidence-quality")
     (algorithm "typed-ppr-diverse")
     (seedIds (evidence-analysis-seed-ids analysis-graph))
     (budget 8)
     (producer (evidence-producer))
     (project (hash (root root)
                    (fields (hash))))
     (summary request-summary)
     (graphs [analysis-graph])
     (fields (hash (next "pipe JSON to `asp graph render --packet - --view seeds`"))))))
;; String <- Packet
(def (display-evidence-graph packet)
  (let (summary (hash-get packet 'summary))
    (displayln "evidence-graph nodes=" (hash-get summary 'nodes)
               " edges=" (hash-get summary 'edges)
               " owners=" (hash-get summary 'owners)
               " claims=" (hash-get summary 'claims)
               " stale-items=" (hash-get summary 'staleItems)
               " gaps=" (hash-get summary 'gaps))))
;; String <- Packet
(def (display-evidence-analysis-request packet)
  (let (summary (hash-get packet 'summary))
    (displayln "evidence-analysis profile=" (hash-get packet 'profile)
               " graphs=" (hash-get summary 'graphs)
               " nodes=" (hash-get summary 'nodes)
               " edges=" (hash-get summary 'edges)
               " owners=" (hash-get summary 'owners)
               " claims=" (hash-get summary 'claims)
               " stale-items=" (hash-get summary 'staleItems)
               " gaps=" (hash-get summary 'gaps)
               " next=\"asp graph render --packet - --view seeds\"")))
;; String <- ProjectIndex
(def (evidence-owner-path index)
  (let (package (project-index-package index))
    (cond
     (package (project-package-path package))
     ((pair? (project-index-files index))
      (source-file-path (car (project-index-files index))))
     (else "."))))
;; String <- Prefix Value
(def (evidence-node-id prefix value)
  (string-append prefix ":" value))
;; String <- NodeId String Label OwnerPath Status Fields
(def (evidence-node node-id kind label owner-path status fields)
  (hash (nodeId node-id)
        (kind kind)
        (label label)
        (ownerPath owner-path)
        (status status)
        (location (hash (path owner-path)
                        (line 1)
                        (column 0)))
        (fields fields)))
;; String <- EdgeId String FromNodeId ToNodeId
(def (evidence-edge edge-id kind from-node-id to-node-id)
  (hash (edgeId edge-id)
        (kind kind)
        (fromNodeId from-node-id)
        (toNodeId to-node-id)))
;; String <- Nodes Edges Gaps
(def (evidence-summary nodes edges gaps)
  (hash (nodes (length nodes))
        (edges (length edges))
        (owners (count-node-kind nodes "owner"))
        (claims (count-node-kind nodes "invariant-candidate"))
        (staleItems 0)
        (gaps (length gaps))))
;;; Invariant:
;;; - count-node-kind owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; Integer <- Nodes String
(def (count-node-kind nodes kind)
  (length (filter (lambda (node)
                    (equal? (hash-get node 'kind) kind))
                  nodes)))
;; String
(def (evidence-producer)
  (hash (languageId +language-id+)
        (providerId +provider-id+)
        (namespace "agent.semantic-protocols.languages.gerbil-scheme.gerbil-scheme-harness")))
;; String <- ProjectIndex
(def (evidence-project index)
  (let ((root (project-index-root index))
        (package (project-index-package index)))
    (hash (root root)
          (package (if package (project-package-name package) "gerbil-scheme-project"))
          (fields (hash)))))
;;; Boundary:
;;; - evidence-analysis-graph composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Graph
(def (evidence-analysis-graph graph)
  (hash (graphId (hash-get graph 'graphId))
        (summary (hash-get graph 'summary))
        (nodes (map evidence-analysis-node (hash-get graph 'nodes)))
        (edges (map evidence-analysis-edge (hash-get graph 'edges)))
        (gaps (hash-get graph 'gaps))))
;; String <- Node
(def (evidence-analysis-node node)
  (let* ((location (hash-get node 'location))
         (path (hash-get node 'ownerPath))
         (line (hash-get location 'line)))
    (hash (id (hash-get node 'nodeId))
          (kind (hash-get node 'kind))
          (role (evidence-node-role (hash-get node 'kind)))
          (value (hash-get node 'label))
          (path path)
          (ownerPath path)
          (locator (string-append path ":" (number->string line) ":" (number->string line)))
          (startLine line)
          (endLine line)
          (fields (hash-get node 'fields)))))
;; String <- Edge
(def (evidence-analysis-edge edge)
  (hash (source (hash-get edge 'fromNodeId))
        (target (hash-get edge 'toNodeId))
        (relation (hash-get edge 'kind))
        (fields (hash (edgeId (hash-get edge 'edgeId))))))
;;; Boundary:
;;; - evidence-analysis-seed-ids composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; String <- Graph
(def (evidence-analysis-seed-ids graph)
  (map (lambda (node) (hash-get node 'id))
       (filter (lambda (node)
                 (equal? (hash-get node 'role) "owner"))
               (hash-get graph 'nodes))))
;; String <- String
(def (evidence-node-role kind)
  (cond
   ((equal? kind "owner") "owner")
   ((equal? kind "invariant-candidate") "claim")
   ((equal? kind "verification-receipt") "receipt")
   ((equal? kind "review-action") "action")
   (else "evidence")))
