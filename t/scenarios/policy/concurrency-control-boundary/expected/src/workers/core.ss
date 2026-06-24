;;; -*- Gerbil -*-
;;; Boundary:
;;; - Worker execution names spawn, join, and sequentialization separately so
;;;   repairs preserve concurrency-control responsibilities.
(package: sample/concurrency)
(export run-jobs)

;; job-sequentializer
;;   : (-> String (-> Job Result) (-> Job Result))
;;   | doc m%
;;       `job-sequentializer` owns the mutex boundary for one worker function.
;;
;;       # Examples
;;
;;       ```scheme
;;       ((job-sequentializer "jobs" run-one) job)
;;       ;; => result
;;       ```
;;     %
(def (job-sequentializer name run-one)
  (let (mx (make-mutex name))
    (lambda (job)
      (with-lock mx (lambda () (run-one job))))))

;; spawn-job
;;   : (-> (-> Job Result) Job Thread)
;;   | doc m%
;;       `spawn-job` owns the worker spawn boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (spawn-job run-one job)
;;       ;; => thread
;;       ```
;;     %
(def (spawn-job run-one job)
  (spawn (lambda () (run-one job))))

;; join-workers
;;   : (-> (List Thread) (List Result))
;;   | doc m%
;;       `join-workers` owns the join boundary for worker threads.
;;
;;       # Examples
;;
;;       ```scheme
;;       (join-workers threads)
;;       ;; => results
;;       ```
;;     %
(def (join-workers threads)
  (map thread-join! threads))

;; run-jobs
;;   : (-> (List Job) (List Result))
;;   | doc m%
;;       `run-jobs` composes the local concurrency helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-jobs jobs)
;;       ;; => results
;;       ```
;;     %
(def (run-jobs jobs)
  (let (run-one (job-sequentializer "jobs" (lambda (job) (job))))
    (join-workers
     (map (lambda (job) (spawn-job run-one job)) jobs))))
