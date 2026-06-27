;;; -*- Gerbil -*-
;;; Upstream performance quality signals for R013 typed-combinator guidance.

(import :parser/facade
        (only-in :std/misc/list unique)
        (only-in :std/sugar filter))

(export typed-combinator-style-upstream-performance-quality-facets)

;; (List String)
(def +typed-combinator-style-generic-numeric-callees+
  '("+" "-" "*" "/" "<" ">" "<=" ">=" "="))

;; (List String)
(def +typed-combinator-style-gambit-numeric-callees+
  '("fx+" "fx-" "fx*" "fx/" "fx<" "fx>" "fx<=" "fx>=" "fx="
    "fl+" "fl-" "fl*" "fl/" "fl<" "fl>" "fl<=" "fl>=" "fl="
    "##fx+" "##fx-" "##fx*" "##fx<" "##fx>" "##fx<=" "##fx>="
    "##fx="
    "##fl+" "##fl-" "##fl*" "##fl<" "##fl>" "##fl<=" "##fl>="
    "##fl="))

;;; Upstream performance facets:
;;; - Keep this derived from parser-owned callFacts and loopDriverFacts.
;;; - Generic numeric hot loops and repeated dynamic apply hide the call shape
;;;   Gerbil/Gambit optimizers need for fx/fl and inline-rule specialization.
;; : (-> SourceFile (List QualityFacet) )
(def (typed-combinator-style-upstream-performance-quality-facets file)
  (unique
   (append
    (if (typed-combinator-style-generic-numeric-hot-loop? file)
      ["gambit-numeric-primitive-boundary"
       "numeric-domain-contract"
       "generic-numeric-hot-loop"]
      [])
    (if (typed-combinator-style-dynamic-apply-hot-loop? file)
      ["gerbil-inline-rule-call-shape"
       "dynamic-apply-hot-loop"
       "compiler-inline-rule-obscured"]
      [])
    (if (typed-combinator-style-macro-generated-dynamic-apply-hot-loop? file)
      ["macro-phase-optimizer-visible-fast-path"
       "phase-macro-generated-wrapper"
       "optimizer-visible-call-shape"]
      []))))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-macro-generated-dynamic-apply-hot-loop? file)
  (and (pair? (source-file-macros file))
       (typed-combinator-style-dynamic-apply-hot-loop? file)))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-generic-numeric-hot-loop? file)
  (and (pair? (source-file-loop-driver-facts file))
       (>= (typed-combinator-style-call-count
            file
            +typed-combinator-style-generic-numeric-callees+)
           2)
       (= (typed-combinator-style-call-count
           file
           +typed-combinator-style-gambit-numeric-callees+)
          0)))

;; : (-> SourceFile Boolean )
(def (typed-combinator-style-dynamic-apply-hot-loop? file)
  (and (pair? (source-file-loop-driver-facts file))
       (>= (typed-combinator-style-call-count file '("apply")) 2)))

;; : (-> SourceFile (List String) Nat )
(def (typed-combinator-style-call-count file callees)
  (length
   (filter (lambda (call)
             (member (call-fact-callee call) callees))
           (source-file-calls file))))
