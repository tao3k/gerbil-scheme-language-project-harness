;;; Benchmark report boundary: this owner records corpus applicability and validity.
;;; Timing thresholds remain owned by the benchmark gate and command surfaces.
(export benchmark-corpus-findings
        benchmark-put-corpus-fields!)

;;; Boundary: only full mode can claim an indexed project corpus.
;;; Invariant: a passing full measurement has both files and definitions.
;;; Risk: treating uncollected hot metrics as empty would create a false failure.
;; : (-> BenchmarkMode Boolean Integer Integer (List BenchmarkFinding))
(def (benchmark-corpus-findings mode collected? files definitions)
  (filter
   (lambda (finding) finding)
   [(and (equal? mode "full")
         (or (not collected?) (= files 0) (= definitions 0))
         (hash (kind "empty-project-corpus")
               (severity "error")
               (summary
                "full benchmark requires a non-empty parser-owned project corpus")
               (files files)
               (definitions definitions)))]))

;;; Compatibility boundary: v1 keeps numeric fields; corpusCollected carries applicability.
;;; Invariant: applicability and both counts are updated before packet rendering.
;;; Mutation preserves the packet identity shared by hot and full renderers.
;; : (forall (k v) (-> (HashTable k v) Boolean Integer Integer (HashTable k v)))
;; : (-> Json Boolean Integer Integer Json)
(def (benchmark-put-corpus-fields! packet collected? files definitions)
  (for-each
   (lambda (field)
     (hash-put! packet (car field) (cdr field)))
   (list (cons 'corpusCollected collected?)
         (cons 'files files)
         (cons 'definitions definitions)))
  packet)
