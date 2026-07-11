;;; -*- Gerbil -*-
;;; Parallel source-file parse scheduling.

(import :gerbil/gambit
        :gslph/src/parser/model
        :gslph/src/parser/profile
        :gslph/src/parser/source-file
        :gslph/src/support/time
        (only-in :std/srfi/1 iota)
        (only-in :std/sugar cut while))

(export parse-source-files/concurrent
        parse-source-files
        parse-source-files/profile)

;;; Profile row boundary:
;;; - Worker details become one JSON-ready row before crossing back into the
;;;   foreground scheduler.
;;; - Full-project profile rows are scalar-only; stage timing is an explicit
;;;   per-owner operation and never retains extra source trees here.
;; parse-profile-row
;;   : (-> String Integer SourceFile HashTable)
;;   | doc m%
;;       `parse-profile-row path elapsed-ms source-file` records the per-file
;;       parser cost and scalar source facts.
;;     %
(def (parse-profile-row path elapsed-ms source-file)
  (hash (path path)
        (durationMs elapsed-ms)
        (lineCount (source-file-line-count source-file))
        (definitions (length (source-file-definitions source-file)))
        (calls (length (source-file-calls source-file)))))

;;; Worker body boundary:
;;; - Worker threads own exactly one parse operation and one mailbox send.
;;; - Error payloads stay data-shaped so the foreground thread remains the only
;;;   place that raises into the scheduler.
;; parse-source-worker!
;;   : (-> Thread String String Integer Boolean)
;;   | doc m%
;;       `parse-source-worker! foreground-thread root path index`
;;       parses one file and sends either an `ok` or `error` vector.
;;     %
(def (parse-source-worker! foreground-thread root path index)
  (with-catch
   (lambda (exn)
     (thread-send foreground-thread
                  (vector 'error (current-thread) index exn))
     #f)
   (lambda ()
     (let* ((file-start (monotonic-ms))
            (source-file (parse-source-file root path)))
       (thread-send foreground-thread
                    (vector 'ok
                            (current-thread)
                            index
                            source-file
                            (duration-ms file-start (monotonic-ms))
                            #f))
       #t))))

;;; Worker reuse boundary:
;;; - A collection creates one thread per worker, never one thread per source
;;;   file, so repeated project collection cannot retain a thread history that
;;;   grows with corpus size.
;; parse-source-worker-batch!
;;   : (-> Thread String Vector Integer Integer Unit)
;;   | doc m%
;;       `parse-source-worker-batch!` parses a stride-partitioned group of
;;       source indexes and stops after its first reported error.
;;     %
(def (parse-source-worker-batch! foreground-thread root file-vector
                                 start-index stride)
  (let loop ((index start-index))
    (when (< index (vector-length file-vector))
      (let (path (vector-ref file-vector index))
        (when (parse-source-worker! foreground-thread root path index)
          (loop (+ index stride)))))))

;;; Spawn boundary:
;;; - The foreground scheduler chooses indexes; this helper only maps an index
;;;   to its path and starts a named worker.
;; spawn-parse-worker!
;;   : (-> Thread String Vector Integer Integer Thread)
;;   | doc m%
;;       `spawn-parse-worker! foreground-thread root file-vector index profile?`
;;       starts one bounded worker for the indexed source file.
;;     %
(def (spawn-parse-worker! foreground-thread root file-vector
                          start-index stride)
  (spawn/name
   [worker: start-index]
   (lambda ()
     (parse-source-worker-batch! foreground-thread root file-vector
                                 start-index stride))))

;;; Receive boundary:
;;; - The mailbox protocol is vector-shaped and foreground-owned.
;;; - Successful results update output vectors in input order; errors re-raise
;;;   after the worker joins.
;; receive-parse-worker!
;;   : (-> Vector Vector Boolean (Values Integer (Maybe HashTable)))
;;   | doc m%
;;       `receive-parse-worker! file-vector source-vector row-vector profile?`
;;       receives one worker message, records it, and returns completed count.
;;     %
(def (receive-parse-worker! file-vector source-vector timing?)
  (let (message (thread-receive))
    (unless (vector? message)
      (error "unexpected parse worker message" message))
    (let (status (vector-ref message 0))
      (case status
        ((ok)
         (values 1
                 (record-parse-worker-success! file-vector
                                               source-vector
                                               timing?
                                               message)))
        ((error)
         (raise (vector-ref message 3)))
        (else
         (error "unexpected parse worker status" status))))))

;; record-parse-worker-success!
;;   : (-> Vector Vector Boolean Vector (Maybe HashTable))
;;   | doc m%
;;       `record-parse-worker-success!` writes one successful worker result into
;;       the foreground-owned result vectors.
;;     %
(def (record-parse-worker-success! file-vector source-vector timing? message)
  (let ((index (vector-ref message 2))
        (source-file (vector-ref message 3))
        (elapsed-ms (vector-ref message 4)))
    (when source-vector
      (vector-set! source-vector index source-file))
    (if timing?
      (parse-profile-row (vector-ref file-vector index)
                         elapsed-ms
                         source-file)
      #f)))

;;; Aggregate phase boundary:
;;; - Keep scheduler metadata in one packet so profile receipts can explain
;;;   concurrency behavior without re-reading source.
;; parse-worker-phase-row
;;   : (-> Integer Integer HashTable)
;;   | doc m%
;;       `parse-worker-phase-row start worker-count` records aggregate parse
;;       duration and scheduler metadata.
;;     %
(def (parse-worker-phase-row start worker-count)
  (let (row (profile-row "parse-source-files"
                         (duration-ms start (monotonic-ms))))
    (hash-put! row 'workerCount worker-count)
    (hash-put! row 'parallel (> worker-count 1))
    (hash-put! row 'scheduler "green-thread-mailbox")
    (hash-put! row 'sharedState "foreground-owned")
    (hash-put! row 'backpressure "bounded-active-workers")
    row))

;;; Parallel parse boundary:
;;; - The foreground thread owns scheduling counters and result vectors.
;;; - The only local mutation left is the bounded worker loop; parser work,
;;;   mailbox packets, and profile rows are top-level helpers.
;; parse-source-files/concurrent
;;   : (-> String (List String) Boolean (Or (Values (List SourceFile) HashTable (List HashTable)) (List SourceFile)))
;;   | doc m%
;;       `parse-source-files/concurrent root files profile?` parses files
;;       through bounded green-thread workers and optionally returns profile
;;       rows.
;;
;;       # Examples
;;
;;       ```scheme
;;       (parse-source-files/concurrent "." ["build.ss"] #f)
;;       ;; => source files in input order
;;       ```
;;     %
(def (parse-source-files/concurrent* root files timing? retain-source?)
  (let* ((file-count (length files))
         (worker-count (collect-project-worker-count file-count))
         (file-vector (list->vector files))
         (source-vector (and retain-source? (make-vector file-count #f)))
         (profile-frontier '())
         (foreground-thread (current-thread))
         (workers
          (map (lambda (start-index)
                 (spawn-parse-worker! foreground-thread
                                      root
                                      file-vector
                                      start-index
                                      worker-count))
               (iota worker-count)))
         (start (monotonic-ms)))
    (let loop ((completed 0))
      (if (= completed file-count)
        (for-each thread-join! workers)
        (call-with-values
         (lambda ()
           (receive-parse-worker! file-vector source-vector timing?))
         (lambda (count profile-row)
           (when profile-row
             (set! profile-frontier
               (slowest-profile-rows
                (cons profile-row profile-frontier)
                10)))
           (loop (+ completed count))))))
    (let* ((source-files (and retain-source? (vector->list source-vector)))
           (parse-phase (parse-worker-phase-row start worker-count)))
      (if timing?
        (values source-files
                parse-phase
                profile-frontier)
        source-files))))

;; `profile?` preserves the public parser contract.  The implementation keeps
;; all-file parsing on the ordinary concurrent path and profiles only its
;; bounded timing frontier.
(def (parse-source-files/concurrent root files profile?)
  (if profile?
    (parse-source-files/profile root files)
    (parse-source-files/concurrent* root files #f #t)))

;; parse-source-files
;;   : (-> String (List String) (List SourceFile))
;;   | doc m%
;;       `parse-source-files root files` parses files concurrently without
;;       profile telemetry.
;;     %
(def (parse-source-files root files)
  ((cut parse-source-files/concurrent <> <> #f) root files))

;; parse-source-files/profile
;;   : (-> String (List String) HashTable)
;;   | doc m%
;;       `parse-source-files/profile root files` materializes the project once
;;       and returns a packet with its parse phase and bounded timing frontier.
;;     %
(def (parse-source-files/profile root files)
  ;; Full-project profiling is evidence collection, not a second parser pass.
  ;; A caller that needs stage timing can profile an already selected owner.
  (call-with-values
   (lambda ()
     (parse-source-files/concurrent* root files #t #t))
   (lambda (source-files parse-phase profile-frontier)
     (hash (sourceFiles source-files)
           (parsePhase parse-phase)
           (slowestFiles profile-frontier)))))
