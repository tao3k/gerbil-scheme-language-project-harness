;;; -*- Gerbil -*-
;;; Parser-owned typed-combinator contract facts.

(import :gerbil/gambit
        :parser/model
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13
                 string-contains
                 string-prefix?
                 string-ref
                 string-trim
                 string-trim-both)
        (only-in :std/sugar andmap cut filter filter-map find foldl hash ormap while with-catch)
        :support/list)

(export typed-contract-facts-from-definitions)

;;; Boundary:
;;; - typed-contract-facts-from-definitions composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; (List TypedContractFact) <- FullPath Relpath (List Definition) (List CallFact) (List HigherOrderFact) (List ControlFlowFact)
(def (typed-contract-facts-from-definitions fullpath relpath definitions calls higher-order-forms control-flow-forms)
  (with-catch
   (lambda (_) '())
   (lambda ()
     (let (lines (read-file-lines fullpath))
       (filter-map (cut typed-contract-fact-from-definition
                        relpath lines <> calls
                        higher-order-forms control-flow-forms)
                   definitions)))))

;;; Boundary:
;;; - typed-contract-fact-from-definition coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; (Maybe TypedContractFact) <- Relpath (List SourceLine) Definition (List CallFact) (List HigherOrderFact) (List ControlFlowFact)
(def (typed-contract-fact-from-definition relpath lines definition calls higher-order-forms control-flow-forms)
  (let* ((comment-line-number (fx1- (definition-start definition)))
         (line (line-at* lines (fx1- comment-line-number)))
         (contract (typed-contract-comment-body line)))
    (and contract
         (let* ((tokens (typed-contract-tokens contract))
                (arrow-count (typed-contract-arrow-count contract))
                (group-count (typed-contract-group-count contract))
                (contract-output (typed-contract-output contract))
                (contract-inputs (typed-contract-inputs contract))
                (contract-input-count (length contract-inputs))
                (arity-alignment
                 (typed-contract-arity-alignment definition
                                                 arrow-count
                                                 contract-input-count))
                (reasons (typed-contract-invalid-reasons definition contract tokens
                                                         arrow-count
                                                         group-count))
                (quality (typed-contract-quality reasons arrow-count group-count))
                (matched-calls
                 (definition-calls definition calls))
                (matched-higher-order
                 (definition-higher-order-forms definition higher-order-forms))
                (matched-control-flow
                 (definition-control-flow-forms definition control-flow-forms))
                (quality-facets
                 (typed-contract-quality-facets
                  definition quality arity-alignment reasons
                  matched-calls matched-higher-order matched-control-flow))
                (repair-evidence
                 (typed-contract-repair-evidence
                  relpath definition contract quality quality-facets
                  matched-calls matched-higher-order matched-control-flow)))
           (make-typed-contract-fact
            (definition-name definition)
            (definition-kind definition)
            (definition-formals definition)
            (definition-arity definition)
            relpath
            (definition-start definition)
            (definition-end definition)
            comment-line-number
            comment-line-number
            contract
            contract-output
            contract-inputs
            contract-input-count
            arity-alignment
            tokens
            arrow-count
            group-count
            quality
            reasons
            quality-facets
            repair-evidence)))))

;;; Quality facets are parser-owned evidence for later policy decisions.
;;; Keep style signals separate from hard findings so guidance stays flexible.
;; (List QualityFacet) <- Definition SignatureQuality ArityAlignment (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact)
(def (typed-contract-quality-facets definition quality arity-alignment reasons calls higher-order-forms control-flow-forms)
  (dedupe-strings
   (filter identity
           (append
            [(if (pair? reasons) "contract-invalid" "contract-valid")
             quality
             arity-alignment
             (and (> (definition-arity definition) 0) "arity-bearing-definition")
             (and (pair? calls) "call-backed")
             (and (pair? higher-order-forms) "higher-order-used")
             (and (pair? higher-order-forms) "combinator-backed")
             (and (manual-loop-drift? control-flow-forms) "manual-loop-drift")
             (and (combinator-candidate? definition reasons calls higher-order-forms control-flow-forms)
                  "combinator-candidate")
             (and (over-abstracted-contract-risk? quality calls higher-order-forms)
                  "over-abstracted-contract-risk")]
            (map control-flow-facet control-flow-forms)))))

;; Boolean <- Definition (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact)
(def (combinator-candidate? definition reasons calls higher-order-forms control-flow-forms)
  (and (not (pair? reasons))
       (> (definition-arity definition) 0)
       (or (manual-loop-drift? control-flow-forms)
           (and (pair? calls) (not (pair? higher-order-forms))))))

;; Boolean <- SignatureQuality (List CallFact) (List HigherOrderFact)
(def (over-abstracted-contract-risk? quality calls higher-order-forms)
  (and (member quality ["higher-order-transform" "grouped-transform"])
       (not (pair? calls))
       (not (pair? higher-order-forms))))

;;; Manual-loop drift is a style signal, not a forced rewrite by itself.
;;; Runtime/control boundaries suppress the signal when loops encode structure.
;; Boolean <- (List ControlFlowFact)
(def (manual-loop-drift? control-flow-forms)
  (and (control-flow-role-present? control-flow-forms "manual-loop")
       (not (ormap (cut control-flow-role-present? control-flow-forms <>)
                   ["resource-scope" "continuation-control"
                    "protected-control" "builder-control"]))))

;;; Role lookup keeps control-flow facet detection declarative.
;;; Callers can compose role predicates without inlining loop tests.
;; Boolean <- (List ControlFlowFact) String
(def (control-flow-role-present? control-flow-forms role)
  (ormap (lambda (fact) (equal? (control-flow-fact-role fact) role))
         control-flow-forms))

;; QualityFacet <- ControlFlowFact
(def (control-flow-facet fact)
  (string-append "control-flow:" (control-flow-fact-role fact)))

;;; Repair evidence packages parser witnesses for guide output.
;;; Keep allowed moves flexible while preserving runtime and macro boundaries.
;; RepairEvidence <- Relpath Definition SignatureContract SignatureQuality (List QualityFacet) (List CallFact) (List HigherOrderFact) (List ControlFlowFact)
(def (typed-contract-repair-evidence relpath definition contract quality quality-facets calls higher-order-forms control-flow-forms)
  (hash (factSource "native-parser")
        (trigger "typed-combinator-style")
        (definition (definition-name definition))
        (definitionKind (definition-kind definition))
        (definitionFormals (definition-formals definition))
        (definitionArity (definition-arity definition))
        (path relpath)
        (lineSpan [(definition-start definition) (definition-end definition)])
        (selector (definition-source-selector definition))
        (contract contract)
        (quality quality)
        (qualityFacets quality-facets)
        (matchedCalls (map call-repair-evidence (take-at-most calls 5)))
        (matchedHigherOrder (map higher-order-repair-evidence
                                 (take-at-most higher-order-forms 5)))
        (matchedControlFlow (map control-flow-repair-evidence
                                 (take-at-most control-flow-forms 5)))
        (allowedMoves (typed-contract-allowed-moves quality-facets))
        (forbiddenMoves ["change-public-export-without-policy-evidence"
                         "rewrite-io-or-runtime-boundary-without-witness"
                         "replace-macro-transformer-without-runtime-source-witness"])
        (witnessNeeded (typed-contract-witness-needed quality-facets))
        (agentRepairMode "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))

;; (List RepairMove) <- (List QualityFacet)
(def (typed-contract-allowed-moves quality-facets)
  (dedupe-strings
   (append ["add-or-expand-adjacent-typed-contract-block"]
           (if (member "combinator-candidate" quality-facets)
             ["extract-predicate-mapper-or-reducer-helper"
              "compose-with-map-filter-fold-cut-curry-or-compose"]
             [])
           (if (member "manual-loop-drift" quality-facets)
             ["replace-manual-loop-with-higher-order-combinator-when-no-state-witness"]
             []))))

;; (List WitnessName) <- (List QualityFacet)
(def (typed-contract-witness-needed quality-facets)
  (dedupe-strings
   (append
    (if (member "manual-loop-drift" quality-facets)
      ["state-or-early-exit-witness-if-named-let-remains"]
      [])
    (if (member "over-abstracted-contract-risk" quality-facets)
      ["callsite-or-higher-order-implementation-evidence"]
      [])
    ["parser-snapshot-or-policy-check"])))

;;; Definition-scoped call evidence stays attached to the owning helper.
;;; Matching by caller name avoids comment-text or selector substring heuristics.
;; (List CallFact) <- Definition (List CallFact)
(def (definition-calls definition calls)
  (filter (lambda (fact)
            (equal? (or (call-fact-caller fact) "")
                    (definition-name definition)))
          calls))

;;; Definition-scoped higher-order evidence exposes the combinator witness.
;;; Matching by caller name keeps map/filter/fold advice parser-owned.
;; (List HigherOrderFact) <- Definition (List HigherOrderFact)
(def (definition-higher-order-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (higher-order-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;;; Definition-scoped control-flow evidence separates real structure from style advice.
;;; Matching by caller name keeps loop-risk detection local to the helper.
;; (List ControlFlowFact) <- Definition (List ControlFlowFact)
(def (definition-control-flow-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (control-flow-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;; Json <- CallFact
(def (call-repair-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (arity (call-fact-arity fact))
        (selector (call-fact-source-selector fact))))

;; Json <- HigherOrderFact
(def (higher-order-repair-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (selector (higher-order-source-selector fact))))

;; Json <- ControlFlowFact
(def (control-flow-repair-evidence fact)
  (hash (kind "control-flow")
        (name (control-flow-fact-name fact))
        (role (control-flow-fact-role fact))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (selector (control-flow-source-selector fact))))

;; Selector <- Definition
(def (definition-source-selector definition)
  (string-append (definition-path definition) ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; Selector <- CallFact
(def (call-fact-source-selector fact)
  (string-append (call-fact-path fact) ":"
                 (number->string (call-fact-start fact))
                 "-"
                 (number->string (call-fact-end fact))))

;; Selector <- HigherOrderFact
(def (higher-order-source-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

;; Selector <- ControlFlowFact
(def (control-flow-source-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))

;;; Stable de-duplication keeps quality facets compact while preserving first evidence.
;;; Do not sort here.
;;; Source-order facets make repair payloads easier to trace.
;; (List String) <- (List String)
(def (dedupe-strings items)
  (dedupe items))

;; SignatureContract <- SourceLine
(def (typed-contract-comment-body line)
  (and (string? line)
       (let (trimmed (string-trim line))
         (and (string-prefix? ";;" trimmed)
              (not (string-prefix? ";;; -*-" trimmed))
              (let (body (typed-contract-body-text trimmed))
                (and (not (blank-string? body))
                     body))))))

;; SignatureContract <- SourceLine
(def (typed-contract-body-text trimmed)
  (let (body (string-trim (drop-leading-semicolons trimmed)))
    (if (string-prefix? ":" body)
      (string-trim (substring body 1 (string-length body)))
      body)))

;;; Invariant:
;;; - drop-leading-semicolons owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; SourceLine <- SourceLine
(def (drop-leading-semicolons text)
  (let ((length (string-length text))
        (index 0))
    (while (and (< index length)
                (char=? (string-ref text index) #\;))
      (set! index (fx1+ index)))
    (substring text index length)))

;; (List SignatureReason) <- Definition SignatureContract (List SignatureToken) Integer Integer
(def (typed-contract-invalid-reasons definition contract tokens arrow-count group-count)
  (append
   (if (string-contains contract ";") ["inline-comment"] [])
   (if (and (= arrow-count 0)
            (typed-contract-transform-definition? definition))
     ["missing-transform-arrow"]
     [])
   (if (typed-contract-unknown-token? tokens)
     ["unknown-or-any-token"]
     [])
   (if (typed-contract-simple-placeholder? tokens arrow-count group-count)
     ["placeholder-contract-without-domain-or-higher-order-shape"]
     [])))

;; SignatureQuality <- (List SignatureReason) Integer Integer
(def (typed-contract-quality reasons arrow-count group-count)
  (cond
   ((pair? reasons) "invalid")
   ((= arrow-count 0) "declaration-contract")
   ((> arrow-count 1) "higher-order-transform")
   ((> group-count 0) "grouped-transform")
   (else "domain-transform")))

;; ArityAlignment <- Definition Integer Integer
(def (typed-contract-arity-alignment definition arrow-count contract-input-count)
  (cond
   ((= arrow-count 0) "declaration")
   ((= (definition-arity definition) contract-input-count) "aligned")
   (else "input-count-mismatch")))

;; Boolean <- Definition
(def (typed-contract-transform-definition? definition)
  (> (definition-arity definition) 0))

;;; Boundary:
;;; - typed-contract-simple-placeholder? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- (List SignatureToken) Integer Integer
(def (typed-contract-simple-placeholder? tokens arrow-count group-count)
  (and (= arrow-count 1)
       (find typed-contract-generic-token? tokens)
       (not (find typed-contract-domain-token? tokens))))

;;; Boundary:
;;; - typed-contract-unknown-token? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; Boolean <- (List SignatureToken)
(def (typed-contract-unknown-token? tokens)
  (not (not (find (lambda (token)
                    (member token ["Any" "Unknown"]))
                  tokens))))

;; Boolean <- SignatureToken
(def (typed-contract-domain-token? token)
  (and (not (typed-contract-generic-token? token))
       (not (member token ["List" "Maybe" "NonEmptyList" "Vector" "Hash"]))
       (not (member token ["Boolean" "String" "Integer" "Number" "Unit" "Character"]))))

;; Boolean <- SignatureToken
(def (typed-contract-generic-token? token)
  (or (typed-contract-type-variable-token? token)
      (member token ["Fact" "Value" "TypeSpec" "Side" "Groups" "Key"])))

;; Boolean <- SignatureToken
(def (typed-contract-type-variable-token? token)
  (and (<= (string-length token) 2)
       (string-all-uppercase? token)))

;;; Boundary:
;;; - string-all-uppercase? is a predicate over characters.
;;; - Keep the non-empty guard separate from the universal character check.
;; Boolean <- String
(def (string-all-uppercase? text)
  (let (chars (string->list text))
    (and (pair? chars)
         (andmap (lambda (ch)
                   (or (char-upper-case? ch)
                       (char-numeric? ch)))
                 chars))))

;;; Invariant:
;;; - typed-contract-tokens owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; (List SignatureToken) <- SignatureContract
(def (typed-contract-tokens contract)
  (let ((length (string-length contract))
        (index 0)
        (start #f)
        (tokens '()))
    (while (< index length)
      (if (typed-contract-token-char? (string-ref contract index))
        (if (not start)
          (set! start index))
        (if start
          (begin
            (set! tokens (cons (substring contract start index) tokens))
            (set! start #f))))
      (set! index (fx1+ index)))
    (reverse
     (if start
       (cons (substring contract start index) tokens)
       tokens))))

;; TypeExpr <- SignatureContract
(def (typed-contract-output contract)
  (let (arrow (string-contains contract "<-"))
    (string-trim-both
     (if arrow
       (substring contract 0 arrow)
       contract))))

;; (List TypeExpr) <- SignatureContract
(def (typed-contract-inputs contract)
  (let (arrow (string-contains contract "<-"))
    (if arrow
      (split-top-level-type-exprs
       (substring contract
                  (+ arrow (string-length "<-"))
                  (string-length contract)))
      [])))

;;; Boundary:
;;; - split-top-level-type-exprs is a depth-aware parser for type arguments.
;;; - Fold state tracks index, parenthesis depth, current token start, and output.
;; (List TypeExpr) <- TypeExprs
(def (split-top-level-type-exprs text)
  (let* ((length (string-length text))
         (state
          (foldl (cut split-type-expr-step text <> <>)
                 [0 0 #f '()]
                 (string->list text))))
    (split-type-expr-state-output text state)))

;;; Boundary:
;;; - split-type-expr-step owns one-character type-parser state transitions.
;;; - Keep branch shape shallow so contract tokenization remains policy-auditable.
;; SplitTypeExprState <- TypeExprs Character SplitTypeExprState
(def (split-type-expr-step text ch state)
  (let ((index (car state))
        (depth (cadr state))
        (start (caddr state))
        (out (cadddr state)))
    (if (split-type-expr-boundary? ch depth)
      (split-type-expr-close-state text index depth start out)
      [(fx1+ index)
       (split-type-expr-next-depth ch depth)
       (or start index)
       out])))

;; Boolean <- Character Depth
(def (split-type-expr-boundary? ch depth)
  (and (= depth 0) (char=? ch #\space)))

;; Depth <- Character Depth
(def (split-type-expr-next-depth ch depth)
  (cond
   ((char=? ch #\() (fx1+ depth))
   ((char=? ch #\)) (max 0 (fx1- depth)))
   (else depth)))

;; SplitTypeExprState <- TypeExprs Index Depth Start (List TypeExpr)
(def (split-type-expr-close-state text index depth start out)
  [(fx1+ index)
   depth
   #f
   (if start
     (cons-nonblank-type-expr (substring text start index) out)
     out)])

;; (List TypeExpr) <- TypeExprs SplitTypeExprState
(def (split-type-expr-state-output text state)
  (let ((index (car state))
        (start (caddr state))
        (out (cadddr state)))
    (reverse
     (if start
       (cons-nonblank-type-expr (substring text start index) out)
       out))))

;; (List TypeExpr) <- TypeExpr (List TypeExpr)
(def (cons-nonblank-type-expr value out)
  (let (trimmed (string-trim-both value))
    (if (blank-string? trimmed)
      out
      (cons trimmed out))))

;; Boolean <- Character
(def (typed-contract-token-char? ch)
  (or (char-upper-case? ch)
      (char-lower-case? ch)
      (char-numeric? ch)))

;;; Boundary:
;;; - Count only literal top-level arrow tokens in the source contract text.
;;; - Indexed character pairs keep the two-character lookahead bounded.
;; Integer <- SignatureContract
(def (typed-contract-arrow-count contract)
  (let (text-length (string-length contract))
    (length
     (filter (lambda (entry)
               (let (index (fx1- (cdr entry)))
                 (and (< index (fx1- text-length))
                      (char=? (car entry) #\<)
                      (char=? (string-ref contract (fx1+ index)) #\-))))
             (map-indexed cons (string->list contract))))))

;;; Boundary:
;;; - Group count is a direct predicate count over parentheses.
;;; - Keep this independent from depth parsing so contract quality facts stay cheap.
;; Integer <- SignatureContract
(def (typed-contract-group-count contract)
  (length
   (filter (lambda (ch)
             (or (char=? ch #\()
                 (char=? ch #\))))
           (string->list contract))))

;;; Boundary:
;;; - line-at* is zero-based and total over malformed indices.
;;; - Guard before list-ref so typed contract facts never raise on drifted spans.
;; (Maybe SourceLine) <- (List SourceLine) LineNumber
(def (line-at* lines index)
  (and (>= index 0)
       (< index (length lines))
       (list-ref lines index)))

;; Boolean <- String
(def (blank-string? value)
  (or (not (string? value))
      (= (string-length (string-trim value)) 0)))
