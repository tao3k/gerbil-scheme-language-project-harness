;;; -*- Gerbil -*-
;;; Parallel source-file parse scheduling.

(import :gerbil/gambit
        :parser/model
        :parser/profile
        :parser/source-file
        :support/time
        (only-in :std/srfi/1 iota)
        (only-in :std/sugar cut while))

(export parse-source-files/concurrent
        parse-source-files
        parse-source-files/profile)

;;; Profile row boundary:
;;; - Worker details become one JSON-ready row before crossing back into the
;;;   foreground scheduler.
;;; - Stage rows remain optional so non-profile parsing has no row allocation.
;; parse-profile-row
;;   : (-> String Integer SourceFile (Maybe (List HashTable)) HashTable)
;;   | doc m%
;;       `parse-profile-row path elapsed-ms source-file stage-rows` records the
;;       per-file parse cost and optional parser stage timings.
;;     %
(def (parse-profile-row path elapsed-ms source-file stage-rows)
  (let (row
        (hash (path path)
              (durationMs elapsed-ms)
              (lineCount (source-file-line-count source-file))
              (definitions (length (source-file-definitions source-file)))
              (calls (length (source-file-calls source-file)))))
    (when stage-rows
      (hash-put! row 'phases stage-rows))
    row))

;;; Worker body boundary:
;;; - Worker threads own exactly one parse operation and one mailbox send.
;;; - Error payloads stay data-shaped so the foreground thread remains the only
;;;   place that raises into the scheduler.
;; parse-source-worker!
;;   : (-> Thread String String Integer Boolean Unit)
;;   | doc m%
;;       `parse-source-worker! foreground-thread root path index profile?`
;;       parses one file and sends either an `ok` or `error` vector.
;;     %
(def (parse-source-worker! foreground-thread root path index profile?)
  (with-catch
   (lambda (exn)
     (thread-send foreground-thread
                  (vector 'error (current-thread) index exn)))
   (lambda ()
     (let (file-start (monotonic-ms))
       (if profile?
         (call-with-values
          (lambda () (parse-source-file/profile root path))
          (lambda (source-file stage-rows)
            (thread-send foreground-thread
                         (vector 'ok
                                 (current-thread)
                                 index
                                 source-file
                                 (duration-ms file-start (monotonic-ms))
                                 stage-rows))))
         (let (source-file (parse-source-file root path))
           (thread-send foreground-thread
                        (vector 'ok
                                (current-thread)
                                index
                                source-file
                                (duration-ms file-start (monotonic-ms))
                                #f))))))))

;;; Spawn boundary:
;;; - The foreground scheduler chooses indexes; this helper only maps an index
;;;   to its path and starts a named worker.
;; spawn-parse-worker!
;;   : (-> Thread String Vector Integer Boolean Thread)
;;   | doc m%
;;       `spawn-parse-worker! foreground-thread root file-vector index profile?`
;;       starts one bounded worker for the indexed source file.
;;     %
(def (spawn-parse-worker! foreground-thread root file-vector index profile?)
  (let (path (vector-ref file-vector index))
    (spawn/name
     [worker: path]
     (lambda ()
       (parse-source-worker! foreground-thread root path index profile?)))))

;;; Receive boundary:
;;; - The mailbox protocol is vector-shaped and foreground-owned.
;;; - Successful results update output vectors in input order; errors re-raise
;;;   after the worker joins.
;; receive-parse-worker!
;;   : (-> Vector Vector (Maybe Vector) Boolean Integer)
;;   | doc m%
;;       `receive-parse-worker! file-vector source-vector row-vector profile?`
;;       receives one worker message, records it, and returns completed count.
;;     %
(def (receive-parse-worker! file-vector source-vector row-vector profile?)
  (let (message (thread-receive))
    (unless (vector? message)
      (error "unexpected parse worker message" message))
    (let ((status (vector-ref message 0))
          (worker-thread (vector-ref message 1))
          (index (vector-ref message 2)))
      (thread-join! worker-thread)
      (case status
        ((ok)
         (record-parse-worker-success! file-vector
                                       source-vector
                                       row-vector
                                       profile?
                                       message)
         1)
        ((error)
         (raise (vector-ref message 3)))
        (else
         (error "unexpected parse worker status" status))))))

;; record-parse-worker-success!
;;   : (-> Vector Vector (Maybe Vector) Boolean Vector Unit)
;;   | doc m%
;;       `record-parse-worker-success!` writes one successful worker result into
;;       the foreground-owned result vectors.
;;     %
(def (record-parse-worker-success! file-vector source-vector row-vector profile?
                                   message)
  (let ((index (vector-ref message 2))
        (source-file (vector-ref message 3))
        (elapsed-ms (vector-ref message 4))
        (stage-rows (vector-ref message 5)))
    (vector-set! source-vector index source-file)
    (when profile?
      (vector-set! row-vector
                   index
                   (parse-profile-row (vector-ref file-vector index)
                                      elapsed-ms
                                      source-file
                                      stage-rows)))))

;;; Aggregate phase boundary:
;;; - Keep scheduler metadata in one packet so benchmark receipts can explain
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
(def (parse-source-files/concurrent root files profile?)
  (let* ((file-count (length files))
         (worker-count (collect-project-worker-count file-count))
         (file-vector (list->vector files))
         (source-vector (make-vector file-count #f))
         (row-vector (and profile? (make-vector file-count #f)))
         (foreground-thread (current-thread))
         (next-index 0)
         (active-workers 0)
         (completed 0)
         (start (monotonic-ms)))
    ;; : (-> Boolean)
    (def (spawn-next-worker!)
      (and (< next-index file-count)
           (let (index next-index)
             (set! next-index (+ next-index 1))
             (spawn-parse-worker! foreground-thread
                                  root
                                  file-vector
                                  index
                                  profile?)
             (set! active-workers (+ active-workers 1))
             #t)))
    (for-each (lambda (_) (spawn-next-worker!))
              (iota worker-count))
    (while (> active-workers 0)
      (set! completed
        (+ completed
           (receive-parse-worker! file-vector
                                  source-vector
                                  row-vector
                                  profile?)))
      (set! active-workers (- active-workers 1))
      (spawn-next-worker!))
    (when (not (= completed file-count))
      (error "parse worker completion mismatch" completed file-count))
    (let* ((source-files (vector->list source-vector))
           (rows (and profile? (vector->list row-vector)))
           (parse-phase (parse-worker-phase-row start worker-count)))
      (if profile?
        (values source-files
                parse-phase
                (slowest-profile-rows rows 10))
        source-files))))

;; parse-source-files
;;   : (-> String (List String) (List SourceFile))
;;   | doc m%
;;       `parse-source-files root files` parses files concurrently without
;;       profile telemetry.
;;     %
(def (parse-source-files root files)
  ((cut parse-source-files/concurrent <> <> #f) root files))

;; parse-source-files/profile
;;   : (-> String (List String) (Values (List SourceFile) HashTable (List HashTable)))
;;   | doc m%
;;       `parse-source-files/profile root files` parses files concurrently and
;;       returns parsed sources plus aggregate and slowest-file profile rows.
;;     %
(def (parse-source-files/profile root files)
  ((cut parse-source-files/concurrent <> <> #t) root files))
