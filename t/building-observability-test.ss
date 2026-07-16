(import :std/text/json
        :gslph/src/building/model
        :gslph/src/building/observability)

(def (assert-true label value)
  (unless value
    (error "building observability assertion failed" label value)))

(import :std/text/json)

(def (exercise-build-topology-execution-windows-observability)
  (let* ((topology-groups '((prepare) (compile) (link)))
         (execution-windows '((prepare compile link)))
         (json-string
          (build-topology-execution-windows->json-string
           topology-groups
           execution-windows))
         (object (string->json-object json-string)))
    (assert-true
     "topology execution windows schema is stable"
     (equal?
      (hash-get object "schema")
      "gslph.build-topology-execution-windows.v1"))
    (assert-true
     "topology execution windows version is stable"
     (= (hash-get object "version") 1))
    (assert-true
     "topology execution windows metric scope is stable"
     (equal?
      (hash-get object "metric-scope")
      "build-topology-execution-windows"))
    (assert-true
     "topology execution windows executor is std/make"
     (equal? (hash-get object "upstream-executor") "std/make"))
    (assert-true
     "three topology groups form one upstream session"
     (and (= (hash-get object "topology-group-count") 3)
          (= (hash-get object "upstream-session-count") 1)))
    (assert-true
     "three to one eliminates two barriers"
     (= (hash-get object "eliminated-barrier-count") 2))
    (assert-true
     "topology execution windows count flattened specs"
     (= (hash-get object "spec-count") 3))
    (assert-true
     "topology execution windows preserve dependency order"
     (hash-get object "dependency-order-preserved"))
    (assert-true
     "topology execution windows JSON round-trips canonically"
     (equal?
      (parameterize ((write-json-sort-keys? #t))
        (json-object->string object))
      json-string)))

  (let (object
        (build-topology-execution-windows->json-object '() '()))
    (assert-true
     "empty topology execution windows have zero counts"
     (and (= (hash-get object "topology-group-count") 0)
          (= (hash-get object "upstream-session-count") 0)
          (= (hash-get object "eliminated-barrier-count") 0)
          (= (hash-get object "spec-count") 0)))
    (assert-true
     "empty topology execution windows preserve dependency order"
     (hash-get object "dependency-order-preserved"))))

(exercise-build-topology-execution-windows-observability)

(def (exercise-control-plane)
  (let loop ((remaining 2000000) (sum 0))
    (if (zero? remaining)
        sum
        (loop (- remaining 1) (+ sum remaining)))))

(let* ((observation
        (build-action-observe! 3 exercise-control-plane))
       (summary
        (build-plan-observations-summary->json-object (list observation))))
  (assert-true 'receipt
               (integer? (build-stage-observation-receipt observation)))
  (assert-true 'work-item-count
               (= 3 (build-stage-observation-work-item-count observation)))
  (assert-true 'wall-seconds
               (>= (build-stage-observation-wall-seconds observation) 0.0))
  (assert-true 'control-plane-cpu-seconds
               (>= (build-stage-observation-control-plane-cpu-seconds observation)
                   0.0))
  (assert-true 'control-plane-cpu-utilization
               (>= (build-stage-observation-control-plane-cpu-utilization observation)
                   0.0))
  (assert-true 'control-plane-gc-count
               (>= (build-stage-observation-control-plane-gc-count observation) 0.0))
  (assert-true 'control-plane-allocated-bytes
               (>= (build-stage-observation-control-plane-allocated-bytes observation)
                   0.0))
  (assert-true 'summary-stage-count
               (= 1 (hash-get summary "stage-count")))
  (assert-true 'summary-work-item-count
               (= 3 (hash-get summary "work-item-count")))
  (assert-true 'summary-native-child-scope
               (eq? #f (hash-get summary "native-child-cpu-included")))
  (write-build-plan-observations-summary-json (list observation)))

(let* ((guard (make-build-elapsed-budget-guard 5.0))
       (observations
        (build-observe-sequence/guard!
         '(first second)
         (lambda (item)
           (build-action-observe! 1 (lambda () item)))
         guard
         (lambda (_observation _completed-count _elapsed-seconds) #!void))))
  (assert-true 'guarded-sequence-completes
               (= 2 (length observations)))
  (assert-true 'elapsed-budget-allows-under-limit
               (guard 'after-item 4.9 1 (car observations)))
  (assert-true 'elapsed-budget-blocks-over-limit
               (not (guard 'after-item 5.1 1 (car observations)))))

(let ((blocked?
       (with-catch
        (lambda (_exception) #t)
        (lambda ()
          (build-observe-sequence/guard!
           '(first second)
           (lambda (item)
             (build-action-observe! 1 (lambda () item)))
           (lambda (_phase _elapsed-seconds completed-count _subject)
             (< completed-count 1))
           (lambda (_observation _completed-count _elapsed-seconds) #!void))
          #f))))
  (assert-true 'guard-blocks-sequence-at-boundary blocked?))

(let* ((receipt
        (make-build-stage-receipt
         "json-stage" 'std/make 'compiled "JSON projection" 'made 7))
       (observation
        (build-action-observe! 2 (lambda () receipt)))
       (json
        (build-plan-observations->json-string (list observation)))
       (object (string->json-object json))
       (stages (hash-get object "stages"))
       (stage (car stages)))
  (assert-true 'json-schema
               (equal? "gslph.build-observations.v1"
                       (hash-get object "schema")))
  (assert-true 'json-stage-label
               (equal? "json-stage" (hash-get stage "label")))
  (assert-true 'json-stage-kind
               (equal? "std/make" (hash-get stage "kind")))
  (assert-true 'json-native-child-scope
               (eq? #f (hash-get object "native-child-cpu-included"))))
