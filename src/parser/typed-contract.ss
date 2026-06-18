;;; -*- Gerbil -*-
;;; Parser-owned typed-combinator contract facts.

(import :gerbil/gambit
        :parser/model
        :parser/typed-comment-metadata
        :parser/typed-contract-scheme
        (only-in :std/misc/ports read-file-lines)
        (only-in :std/srfi/13
                 string-join
                 string-contains
                 string-empty?
                 string-every
                 string-prefix?
                 string-trim
                 string-trim-both)
        (only-in :std/srfi/1 iota last take take-while)
        (only-in :std/misc/list length<=n? unique)
        (only-in :std/sugar cut filter filter-map find foldl hash ormap while with-catch)
        )

(export typed-contract-facts-from-definitions
        typed-contract-facts-from-lines)

;;; Boundary:
;;; - typed-contract-facts-from-definitions composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; typed-contract-facts-from-definitions
;;   : (-> FullPath Relpath (List Definition) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (List TypedContractFact) )
;;   | doc m%
;;       `typed-contract-facts-from-definitions fullpath relpath definitions calls higher-order-forms control-flow-forms`
;;       attaches adjacent typed comment facts to parsed definitions while preserving parser-owned implementation evidence.
;;
;;       # Examples
;;       ```scheme
;;       (typed-contract-facts-from-definitions fullpath relpath [] [] [] [])
;;       ;; => ()
;;       ```
;;     %
(def (typed-contract-facts-from-definitions fullpath relpath definitions calls higher-order-forms control-flow-forms)
  (with-catch
   (lambda (_) '())
   (lambda ()
     (let (lines (read-file-lines fullpath))
       (typed-contract-facts-from-lines
        lines relpath definitions calls higher-order-forms control-flow-forms)))))

;;; Boundary:
;;; - parse-source-file already owns source line IO; this helper keeps typed
;;;   contract extraction reusable without re-reading the file on hot paths.
;; : (-> (List SourceLine) Relpath (List Definition) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (List TypedContractFact) )
(def (typed-contract-facts-from-lines lines relpath definitions calls higher-order-forms control-flow-forms)
  (filter-map (cut typed-contract-fact-from-definition
                   relpath lines <> calls
                   higher-order-forms control-flow-forms)
              definitions))

;;; Boundary:
;;; - typed-contract-fact-from-definition coordinates multiple evidence fields.
;;; - Keep packet shape and invariants stable.
;; : (-> Relpath (List SourceLine) Definition (List CallFact) (List HigherOrderFact) (List ControlFlowFact) (Maybe TypedContractFact) )
(def (typed-contract-fact-from-definition relpath lines definition calls higher-order-forms control-flow-forms)
  (let (entry (typed-contract-entry-near-definition lines definition))
    (and entry
         (let* ((comment-start (car entry))
                (comment-end (cadr entry))
                (contract (caddr entry))
                (block-style (cadddr entry))
                (block-facets (typed-contract-entry-facets entry))
                (typed-comment (typed-contract-entry-typed-comment entry))
                (tokens (typed-contract-tokens contract))
                (arrow-count (typed-contract-arrow-count contract))
                (group-count (typed-contract-group-count contract))
                (contract-output (typed-contract-output contract))
                (contract-inputs (typed-contract-inputs contract))
                (contract-input-count (length contract-inputs))
                (arity-alignment
                 (typed-contract-arity-alignment definition
                                                 arrow-count
                                                 contract-input-count))
                (reasons (typed-contract-invalid-reasons
                          definition contract contract-output contract-inputs
                          typed-comment tokens arrow-count group-count))
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
                 matched-calls matched-higher-order matched-control-flow
                  block-style block-facets))
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
            comment-start
            comment-end
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
            repair-evidence
            typed-comment)))))

;;; Quality facets are parser-owned evidence for later policy decisions.
;;; Keep style signals separate from hard findings so guidance stays flexible.
;; : (-> Definition SignatureQuality ArityAlignment (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) BlockStyle (List QualityFacet) (List QualityFacet) )
(def (typed-contract-quality-facets definition quality arity-alignment reasons calls higher-order-forms control-flow-forms block-style block-facets)
  (unique
   (filter identity
           (append
            [(if (pair? reasons) "contract-invalid" "contract-valid")
             block-style
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
            block-facets
            (map control-flow-facet control-flow-forms)))))

;; : (-> Definition (List SignatureReason) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) Boolean )
(def (combinator-candidate? definition reasons calls higher-order-forms control-flow-forms)
  (and (not (pair? reasons))
       (> (definition-arity definition) 0)
       (or (manual-loop-drift? control-flow-forms)
           (and (pair? calls) (not (pair? higher-order-forms))))))

;; : (-> SignatureQuality (List CallFact) (List HigherOrderFact) Boolean )
(def (over-abstracted-contract-risk? quality calls higher-order-forms)
  (and (member quality ["higher-order-transform" "grouped-transform"])
       (not (pair? calls))
       (not (pair? higher-order-forms))))

;;; Manual-loop drift is a style signal, not a forced rewrite by itself.
;;; Runtime/control boundaries suppress the signal when loops encode structure.
;; : (-> (List ControlFlowFact) Boolean )
(def (manual-loop-drift? control-flow-forms)
  (and (control-flow-role-present? control-flow-forms "manual-loop")
       (not (ormap (cut control-flow-role-present? control-flow-forms <>)
                   ["resource-scope" "continuation-control"
                    "protected-control" "builder-control"]))))

;;; Role lookup keeps control-flow facet detection declarative.
;;; Callers can compose role predicates without inlining loop tests.
;; : (-> (List ControlFlowFact) String Boolean )
(def (control-flow-role-present? control-flow-forms role)
  (ormap (lambda (fact) (equal? (control-flow-fact-role fact) role))
         control-flow-forms))

;; : (-> ControlFlowFact QualityFacet )
(def (control-flow-facet fact)
  (string-append "control-flow:" (control-flow-fact-role fact)))

;;; Repair evidence packages parser witnesses for guide output.
;;; Keep allowed moves flexible while preserving runtime and macro boundaries.
;; : (-> Relpath Definition SignatureContract SignatureQuality (List QualityFacet) (List CallFact) (List HigherOrderFact) (List ControlFlowFact) RepairEvidence )
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
        (matchedCalls (map call-repair-evidence
                           (if (length<=n? calls 5) calls (take calls 5))))
        (matchedHigherOrder (map higher-order-repair-evidence
                                 (if (length<=n? higher-order-forms 5)
                                   higher-order-forms
                                   (take higher-order-forms 5))))
        (matchedControlFlow (map control-flow-repair-evidence
                                 (if (length<=n? control-flow-forms 5)
                                   control-flow-forms
                                   (take control-flow-forms 5))))
        (allowedMoves (typed-contract-allowed-moves quality-facets))
        (forbiddenMoves ["change-public-export-without-policy-evidence"
                         "rewrite-io-or-runtime-boundary-without-witness"
                         "replace-macro-transformer-without-runtime-source-witness"])
        (witnessNeeded (typed-contract-witness-needed quality-facets))
        (agentRepairMode "use parserEvidence to choose the smallest helper/combinator rewrite; keep names and exact composition flexible when tests and selectors preserve behavior")))

;; : (-> (List QualityFacet) (List RepairMove) )
(def (typed-contract-allowed-moves quality-facets)
  (unique
   (append ["add-or-expand-adjacent-typed-contract-block"]
           (if (member "combinator-candidate" quality-facets)
             ["extract-predicate-mapper-or-reducer-helper"
              "compose-with-map-filter-fold-cut-curry-or-compose"]
             [])
           (if (member "manual-loop-drift" quality-facets)
             ["replace-manual-loop-with-higher-order-combinator-when-no-state-witness"]
             []))))

;; : (-> (List QualityFacet) (List WitnessName) )
(def (typed-contract-witness-needed quality-facets)
  (unique
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
;; : (-> Definition (List CallFact) (List CallFact) )
(def (definition-calls definition calls)
  (filter (lambda (fact)
            (equal? (or (call-fact-caller fact) "")
                    (definition-name definition)))
          calls))

;;; Definition-scoped higher-order evidence exposes the combinator witness.
;;; Matching by caller name keeps map/filter/fold advice parser-owned.
;; : (-> Definition (List HigherOrderFact) (List HigherOrderFact) )
(def (definition-higher-order-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (higher-order-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;;; Definition-scoped control-flow evidence separates real structure from style advice.
;;; Matching by caller name keeps loop-risk detection local to the helper.
;; : (-> Definition (List ControlFlowFact) (List ControlFlowFact) )
(def (definition-control-flow-forms definition facts)
  (filter (lambda (fact)
            (equal? (or (control-flow-fact-caller fact) "")
                    (definition-name definition)))
          facts))

;; : (-> CallFact Json )
(def (call-repair-evidence fact)
  (hash (kind "call")
        (name (call-fact-callee fact))
        (arity (call-fact-arity fact))
        (selector (call-fact-source-selector fact))))

;; : (-> HigherOrderFact Json )
(def (higher-order-repair-evidence fact)
  (hash (kind "higher-order")
        (name (higher-order-fact-name fact))
        (role (higher-order-fact-role fact))
        (operandCount (higher-order-fact-operand-count fact))
        (selector (higher-order-source-selector fact))))

;; : (-> ControlFlowFact Json )
(def (control-flow-repair-evidence fact)
  (hash (kind "control-flow")
        (name (control-flow-fact-name fact))
        (role (control-flow-fact-role fact))
        (bindingCount (control-flow-fact-binding-count fact))
        (bodyFormCount (control-flow-fact-body-form-count fact))
        (selector (control-flow-source-selector fact))))

;; : (-> Definition Selector )
(def (definition-source-selector definition)
  (string-append (definition-path definition) ":"
                 (number->string (definition-start definition))
                 "-"
                 (number->string (definition-end definition))))

;; : (-> CallFact Selector )
(def (call-fact-source-selector fact)
  (string-append (call-fact-path fact) ":"
                 (number->string (call-fact-start fact))
                 "-"
                 (number->string (call-fact-end fact))))

;; : (-> HigherOrderFact Selector )
(def (higher-order-source-selector fact)
  (string-append (higher-order-fact-path fact) ":"
                 (number->string (higher-order-fact-start fact))
                 "-"
                 (number->string (higher-order-fact-end fact))))

;; : (-> ControlFlowFact Selector )
(def (control-flow-source-selector fact)
  (string-append (control-flow-fact-path fact) ":"
                 (number->string (control-flow-fact-start fact))
                 "-"
                 (number->string (control-flow-fact-end fact))))

;;; Stable de-duplication keeps quality facets compact while preserving first evidence.
;;; Do not sort here.
;;; Source-order facets make repair payloads easier to trace.

;; : (-> (List SourceLine) Definition (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-entry-near-definition lines definition)
  (or (typed-contract-block-entry lines definition)
      (typed-contract-legacy-entry lines definition)))

;; : (-> (List SourceLine) Definition (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-legacy-entry lines definition)
  (let* ((comment-line-number (fx1- (definition-start definition)))
         (line (line-at* lines (fx1- comment-line-number)))
         (contract (typed-contract-comment-body line)))
    (and contract
         [comment-line-number
          comment-line-number
          contract
          "legacy-contract"
          (typed-contract-legacy-facets contract)
          (typed-comment-empty-metadata "legacy-contract" contract)])))

;; : (-> SignatureContract (List QualityFacet))
(def (typed-contract-legacy-facets contract)
  (if (string-contains contract "<-")
    ["legacy-typed-contract"
     "gerbil-contract-projection-migration"]
    []))

;; : (-> TypedContractEntry (List QualityFacet))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet))
(def (typed-contract-entry-facets entry)
  (let (tail (cddddr entry))
    (if (pair? tail)
      (car tail)
      [])))

;; : (-> TypedContractEntry TypedCommentMetadata)
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-entry-typed-comment entry)
  (let (tail (cddddr entry))
    (if (and (pair? tail) (pair? (cdr tail)))
      (cadr tail)
      (typed-comment-empty-metadata "legacy-contract" (caddr entry)))))

;; : (-> (List SourceLine) Definition (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-contract-block-entry lines definition)
  (let (block
        (typed-comment-block-before lines
                                    (fx1- (definition-start definition))))
    (typed-comment-block-signature-entry block)))

;;; Invariant:
;;; - typed-comment-block-before returns source-order entries.
;;; - The block is contiguous and immediately above the definition.
;; : (-> (List SourceLine) LineNumber (List TypedCommentLine))
;; | type TypedCommentLine = (Tuple LineNumber TypedCommentText)
(def (typed-comment-block-before lines line-number)
  (map (lambda (current)
         [current (typed-comment-text (line-at* lines (fx1- current)))])
       (reverse
        (take-while (lambda (current)
                      (typed-comment-line? (line-at* lines (fx1- current))))
                    (iota line-number line-number -1)))))

;; : (-> SourceLine Boolean)
(def (typed-comment-line? line)
  (and (string? line)
       (let (trimmed (string-trim line))
         (and (string-prefix? ";;" trimmed)
              (not (string-prefix? ";;; -*-" trimmed))))))

;; : (-> SourceLine TypedCommentText)
(def (typed-comment-text line)
  (string-trim (string-trim (string-trim line) #\;)))

;; : (-> (List TypedCommentLine) (Maybe TypedContractEntry))
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-comment-block-signature-entry block)
  (let (signature-start (find typed-comment-signature-start? block))
    (and signature-start
         (typed-comment-signature-entry block signature-start))))

;; : (-> TypedCommentLine Boolean)
(def (typed-comment-signature-start? entry)
  (string-prefix? ":" (string-trim (cadr entry))))

;; : (-> (List TypedCommentLine) TypedCommentLine TypedContractEntry)
;; | type TypedContractEntry = (Tuple LineNumber LineNumber SignatureContract BlockStyle (List QualityFacet) TypedCommentMetadata)
(def (typed-comment-signature-entry block signature-start)
  (let* ((signature-entries
          (cons signature-start
                (take-while (lambda (entry)
                              (not (typed-comment-section-start? entry)))
                            (cdr (member signature-start block)))))
         (entries (member signature-start block))
         (section-entries (drop entries (length signature-entries)))
         (parts
          (filter-map
           (lambda (entry)
             (let* ((text (string-trim (cadr entry)))
                    (part (if (typed-comment-signature-start? entry)
                            (typed-comment-strip-signature-marker text)
                            text)))
               (and (not (blank-string? part)) part)))
           signature-entries)))
    [(typed-comment-signature-comment-start block signature-start)
     (typed-comment-block-end-line entries)
     (string-join parts " ")
     "scheme-native-block"
     (typed-comment-section-facets section-entries)
     (typed-comment-metadata block
                             signature-start
                             (string-join parts " ")
                             section-entries)]))

;; : (-> (List TypedCommentLine) LineNumber)
(def (typed-comment-block-end-line entries)
  (car (last entries)))

;; : (-> SourceLine SignatureContract )
(def (typed-contract-comment-body line)
  (and (string? line)
       (let (trimmed (string-trim line))
         (and (string-prefix? ";;" trimmed)
              (not (string-prefix? ";;; -*-" trimmed))
              (let (body (typed-contract-body-text trimmed))
                (and (not (blank-string? body))
                     (not (string-prefix? "|" (string-trim body)))
                     body))))))

;; : (-> SourceLine SignatureContract )
(def (typed-contract-body-text trimmed)
  (let (body (string-trim (string-trim trimmed #\;)))
    (if (string-prefix? ":" body)
      (string-trim (substring body 1 (string-length body)))
      body)))


;; : (-> Definition SignatureContract (List SignatureToken) Integer Integer (List SignatureReason) )
;;; Structural TypeSpec diagnostics are folded into the same invalid-reason
;;; channel as token evidence. Policy can then reject pseudo typed comments
;;; without reparsing source text or hard-coding suspicious type names.
;; : (-> Definition SignatureContract TypeExpr (List TypeExpr) TypedCommentMetadata (List SignatureToken) Integer Integer (List SignatureReason) )
(def (typed-contract-invalid-reasons definition contract contract-output contract-inputs typed-comment tokens arrow-count group-count)
  (unique
   (append
    (if (string-contains contract ";") ["inline-comment"] [])
    (if (and (= arrow-count 0)
             (typed-contract-transform-definition? definition))
      ["missing-transform-arrow"]
      [])
    (if (typed-contract-unknown-token? tokens)
      ["unknown-or-any-token"]
      [])
    (if (typed-contract-placeholder-token-invalid? tokens arrow-count group-count)
      ["placeholder-type-variable-token"]
      [])
    (if (typed-contract-simple-placeholder? tokens arrow-count group-count)
      ["placeholder-contract-without-domain-or-higher-order-shape"]
      [])
    (typed-contract-structural-invalid-reasons contract-output
                                               contract-inputs
                                               typed-comment
                                               arrow-count
                                               (string-contains contract "<-")))))

;;; Full-form `;; :` blocks carry parser-owned TypeSpec diagnostics in
;;; typed-comment metadata. Legacy `Output <- Input` comments are validated
;;; through their projected input/output expressions so old fields cannot hide
;;; malformed type shapes.
;; : (-> TypeExpr (List TypeExpr) TypedCommentMetadata Integer Boolean (List SignatureReason) )
(def (typed-contract-structural-invalid-reasons contract-output contract-inputs typed-comment arrow-count legacy-transform?)
  (append
   (if (and (> arrow-count 0)
            (not legacy-transform?)
            (typed-comment-signature-type typed-comment))
     (typed-comment-structural-invalid-reasons typed-comment)
     (typed-contract-expression-invalid-reasons contract-output contract-inputs))
   (typed-comment-local-type-invalid-reasons typed-comment)))

;; : (-> TypedCommentMetadata MaybeJson )
(def (typed-comment-signature-type typed-comment)
  (and typed-comment
       (hash-get typed-comment 'signatureType)))

;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-structural-invalid-reasons typed-comment)
  (append
   (typed-contract-json-invalid-reasons
    "type-signature"
    (typed-comment-signature-type typed-comment))
   (typed-comment-runtime-contract-invalid-reasons typed-comment)))

;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-runtime-contract-invalid-reasons typed-comment)
  (typed-comment-runtime-contract-invalid-reasons*
   (if typed-comment
     (or (hash-get typed-comment 'runtimeContractsDetailed) [])
     [])
   0))

;; : (-> (List Json) Integer (List SignatureReason) )
(def (typed-comment-runtime-contract-invalid-reasons* contracts index)
  (if (null? contracts)
    []
    (append
     (typed-contract-json-invalid-reasons
      (string-append "runtime-contract[" (number->string index) "]")
      (car contracts))
     (typed-comment-runtime-contract-invalid-reasons*
      (cdr contracts)
      (fx1+ index)))))

;;; Local type aliases are already section-parsed by typed-comment metadata.
;;; Mapping each section independently preserves the alias name in the repair
;;; reason prefix instead of collapsing all alias diagnostics into one bucket.
;; : (-> TypedCommentMetadata (List SignatureReason) )
(def (typed-comment-local-type-invalid-reasons typed-comment)
  (apply append
         (map typed-comment-local-type-invalid-reasons*
              (if typed-comment
                (or (hash-get typed-comment 'localTypes) [])
                []))))

;; : (-> Json (List SignatureReason) )
(def (typed-comment-local-type-invalid-reasons* local-type)
  (typed-contract-json-invalid-reasons
   (string-append "local-type:" (or (hash-get local-type 'name) "<anonymous>"))
   (hash-get local-type 'expressionType)))

;;; Legacy contracts have separate projected output and input strings.
;;; The indexed map keeps input-position diagnostics stable so agents can fix
;;; the malformed type expression without guessing which side of `<-` failed.
;; : (-> TypeExpr (List TypeExpr) (List SignatureReason) )
(def (typed-contract-expression-invalid-reasons contract-output contract-inputs)
  (append
   (typed-contract-type-expression-invalid-reasons "type-output" contract-output)
   (apply append
          (map (lambda (entry)
                 (typed-contract-type-expression-invalid-reasons
                  (string-append "type-input[" (number->string (car entry)) "]")
                  (cdr entry)))
               (typed-contract-indexed-inputs contract-inputs 0)))))

;; : (-> TypeExprIndex (List TypeExpr) (List (Pair Integer TypeExpr)) )
(def (typed-contract-indexed-inputs inputs index)
  (if (null? inputs)
    []
    (cons (cons index (car inputs))
          (typed-contract-indexed-inputs (cdr inputs) (fx1+ index)))))

;; : (-> SignatureReasonPrefix TypeExpr (List SignatureReason) )
(def (typed-contract-type-expression-invalid-reasons prefix expression)
  (typed-contract-json-invalid-reasons
   prefix
   (scheme-type-expression-text-json expression)))

;;; This is the final diagnostic-to-policy bridge.
;;; It prefixes parser-owned TypeSpec diagnostics with their comment location
;;; class, so policy can group repairs without re-inspecting comment text.
;; : (-> SignatureReasonPrefix Json (List SignatureReason) )
(def (typed-contract-json-invalid-reasons prefix json)
  (map (cut string-append prefix ":" <>)
       (typed-contract-json-diagnostics json)))

;; : (-> Json (List Diagnostic) )
(def (typed-contract-json-diagnostics json)
  (unique
   (append
    (if json (or (hash-get json 'diagnostics) []) [])
    (typed-contract-type-spec-json-diagnostics
     (and json (hash-get json 'typeSpec))))))

;; : (-> MaybeJson (List Diagnostic) )
(def (typed-contract-type-spec-json-diagnostics type-spec-json)
  (if type-spec-json
    (or (hash-get type-spec-json 'diagnostics) [])
    []))

;; : (-> (List SignatureReason) Integer Integer SignatureQuality )
(def (typed-contract-quality reasons arrow-count group-count)
  (cond
   ((pair? reasons) "invalid")
   ((= arrow-count 0) "declaration-contract")
   ((> arrow-count 1) "higher-order-transform")
   ((> group-count 0) "grouped-transform")
   (else "domain-transform")))

;; : (-> Definition Integer Integer ArityAlignment )
(def (typed-contract-arity-alignment definition arrow-count contract-input-count)
  (cond
   ((= arrow-count 0) "declaration")
   ((= (definition-arity definition) contract-input-count) "aligned")
   (else "input-count-mismatch")))

;; : (-> Definition Boolean )
(def (typed-contract-transform-definition? definition)
  (> (definition-arity definition) 0))

;;; Boundary:
;;; - typed-contract-simple-placeholder? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List SignatureToken) Integer Integer Boolean )
(def (typed-contract-simple-placeholder? tokens arrow-count group-count)
  (and (= arrow-count 1)
       (find typed-contract-generic-token? tokens)
       (not (find typed-contract-domain-token? tokens))))

;;; Boundary:
;;; - typed-contract-unknown-token? composes first-class procedures.
;;; - Keep data-flow evidence visible.
;; : (-> (List SignatureToken) Boolean )
(def (typed-contract-unknown-token? tokens)
  (if (find (lambda (token)
              (member token ["Any" "Unknown"]))
            tokens)
    #t
    #f))

;; : (-> SignatureToken Boolean )
(def (typed-contract-domain-token? token)
  (and (not (typed-contract-generic-token? token))
       (not (member token ["List" "Maybe" "NonEmptyList" "Vector" "Hash"]))
       (not (member token ["Boolean" "String" "Integer" "Number" "Unit" "Character"]))))

;; : (-> SignatureToken Boolean )
(def (typed-contract-generic-token? token)
  (or (typed-contract-type-variable-token? token)
      (member token ["Fact" "Value" "TypeSpec" "Side" "Groups" "Key"])))

;;; Boundary:
;;; - Placeholder symbols are low-information type variables from old comments.
;;; - Keep this as token evidence so policy can repair docs without text scans.
;; : (-> (List SignatureToken) Boolean )
(def (typed-contract-placeholder-token? tokens)
  (if (find (lambda (token)
              (member token ["XX" "YY" "ZZ"]))
            tokens)
    #t
    #f))

;;; Placeholder-looking variables in gerbil-utils/base.ss can be real higher-order
;;; contract variables, for example `(Z <- YY) <- (Z <- XX YY) XX`.
;;; Keep the warning for low-information single-arrow comments, but do not mark
;;; nested/grouped higher-order contracts invalid.
;; : (-> (List SignatureToken) Integer Integer Boolean )
(def (typed-contract-placeholder-token-invalid? tokens arrow-count group-count)
  (and (typed-contract-placeholder-token? tokens)
       (= arrow-count 1)
       (= group-count 0)))

;;; Token-classification boundary:
;;; - Short uppercase tokens are treated as polymorphic variables, not domains.
;;; - Keeping this narrow prevents legacy helper names from becoming fake types.
;; : (-> SignatureToken Boolean )
(def (typed-contract-type-variable-token? token)
  (and (<= (string-length token) 2)
       (not (string-empty? token))
       (string-every (lambda (ch)
                       (or (char-upper-case? ch)
                           (char-numeric? ch)))
                     token)))

;;; Invariant:
;;; - typed-contract-tokens owns branch/iteration semantics.
;;; - Preserve exit conditions and fallback order.
;; : (-> SignatureContract (List SignatureToken) )
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

;; : (-> SignatureContract TypeExpr )
(def (typed-contract-output contract)
  (let (arrow (typed-contract-main-transform-arrow-index contract))
    (if arrow
      (string-trim-both (substring contract 0 arrow))
      (or (scheme-contract-output contract)
          contract))))

;; : (-> SignatureContract (List TypeExpr) )
(def (typed-contract-inputs contract)
  (let (arrow (typed-contract-main-transform-arrow-index contract))
    (if arrow
      (split-top-level-type-exprs
       (substring contract
                  (+ arrow (string-length "<-"))
                  (string-length contract)))
      (or (scheme-contract-inputs contract) []))))

;;; Legacy `<-` contracts may contain higher-order arrows inside grouped output
;;; or input positions.  Split the transform at the top-level arrow; fall back to
;;; the first arrow only for malformed legacy comments without balanced groups.
;; : (-> SignatureContract (Maybe Index) )
(def (typed-contract-main-transform-arrow-index contract)
  (and (string-contains contract "<-")
       (or (typed-contract-top-level-transform-arrow-index contract)
           (string-contains contract "<-"))))

;;; Scan the raw contract once while tracking parentheses.  The first top-level
;;; `<-` is the contract transform boundary.
;; : (-> SignatureContract (Maybe Index) )
(def (typed-contract-top-level-transform-arrow-index contract)
  (let ((length (string-length contract))
        (index 0)
        (depth 0)
        (found #f))
    (while (and (not found) (< index length))
      (let (ch (string-ref contract index))
        (cond
         ((and (= depth 0)
               (< index (fx1- length))
               (char=? ch #\<)
               (char=? (string-ref contract (fx1+ index)) #\-))
          (set! found index))
         ((char=? ch #\()
          (set! depth (fx1+ depth)))
         ((char=? ch #\))
          (set! depth (max 0 (fx1- depth))))))
      (set! index (fx1+ index)))
    found))

;;; Boundary:
;;; - line-at* is zero-based and total over malformed indices.
;;; - Guard before list-ref so typed contract facts never raise on drifted spans.
;; : (-> (List SourceLine) LineNumber (Maybe SourceLine) )
(def (line-at* lines index)
  (and (>= index 0)
       (< index (length lines))
       (list-ref lines index)))

;; : (-> String Boolean )
(def (blank-string? value)
  (or (not (string? value))
      (string-empty? (string-trim value))))
