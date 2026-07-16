(import :std/test
        ../src/building/model
        ../src/building/native-toolchain
        ../src/building/std-builder)

(export std-builder-execution-window-test main)

(def std-builder-execution-window-test
  (test-suite "std-builder execution windows"
    (test-case "topology groups flatten into one ordered execution window"
      (check
       (topology-groups->upstream-execution-windows
        '((prepare compile) () (link package)))
       => '((prepare compile link package))))

    (test-case "empty topology groups produce no execution window"
      (check (topology-groups->upstream-execution-windows '()) => '())
      (check (topology-groups->upstream-execution-windows '(() ())) => '()))

    (test-case "one topology window invokes the upstream make procedure once"
      (let (calls 0)
        (let* ((make-proc
                (lambda args
                  (set! calls (+ calls 1))
                  (void)))
               (builder
                (make-std-builder
                 "fake-std/make"
                 make-proc
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (windows
                (topology-groups->upstream-execution-windows
                 '((prepare compile) (link package)))))
          (for-each
           (lambda (window)
             (std-builder-run-spec! builder window []))
           windows)
          (check calls => 1))))

    (test-case "current topology window stays skipped without invoking make"
      (let (calls 0)
        (let* ((make-proc
                (lambda args
                  (set! calls (+ calls 1))
                  (void)))
               (builder
                (make-std-builder
                 "fake-std/make"
                 make-proc
                 'compile
                 "fake upstream make"
                 #f
                 []
                 (native-toolchain-default)))
               (windows
                (topology-groups->upstream-execution-windows
                 '((prepare compile) (link package))))
               (stages
                (std-builder-stage-plan
                 builder
                 windows
                 (lambda (stage context) #t)
                 (lambda (spec) "topology-window")
                 []
                 (lambda (stage context result) (void))))
               (receipt (build-stage-run! (car stages) [])))
          (check (build-stage-receipt-status receipt) => 'skipped)
          (check calls => 0))))))

(def (main . args)
  (run-tests! std-builder-execution-window-test))
