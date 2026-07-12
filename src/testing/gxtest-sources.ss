;;; -*- Gerbil -*-
;;; Selected-file source closure for gxtest.

;;; Boundary:
;;; - This module owns ordered graph traversal over already-resolved import
;;;   edges.
;;; - Import syntax stays in gxtest-imports; runner scheduling stays in
;;;   gxtest-run.

(import (only-in :std/srfi/13 string-prefix?)
        (only-in :std/sugar filter-map foldl hash-get hash-put!)
        (only-in "./gxtest-context"
                 gxtest-source-module-path)
        (only-in "./gxtest-imports"
                 compiled-in-process-gxtest-file?
                 gxtest-import-files
                 gxtest-source-file-import-list)
        :gerbil/gambit)

(export compiled-in-process-gxtest-file?
        gxtest-import-files
        gxtest-selected-source-files
        gxtest-selected-source-module-files
        gxtest-selected-test-files)

;; : (-> (List Path) PathSet)
(def (gxtest-path-set (paths []))
  (let (table (make-hash-table))
    (for-each (lambda (path)
                (hash-put! table path #t))
              paths)
    table))

;; : (-> PathSet Path Boolean)
(def (gxtest-path-seen? table path)
  (if (hash-get table path) #t #f))

;; : (-> PathSet Path PathSet)
(def (gxtest-path-set-add! table path)
  (hash-put! table path #t)
  table)

;; : (-> (List Path) (List Path))
(def (gxtest-unique-paths paths)
  (let (state (foldl gxtest-unique-path-step
                     (list (gxtest-path-set) [])
                     paths))
    (reverse (cadr state))))

;; : (-> Path UniquePathState UniquePathState)
(def (gxtest-unique-path-step path state)
  (let ((seen (car state))
        (out (cadr state)))
    (if (gxtest-path-seen? seen path)
      state
      (begin
        (gxtest-path-set-add! seen path)
        (list seen (cons path out))))))

;; : (-> Path (List Path) (List Path))
(def (gxtest-file-source-closure file seen)
  (gxtest-files-source-closure [file] seen))

;; : (-> (List Path) SourceQueue)
(def (gxtest-source-queue files)
  (cons files []))

;; : (-> SourceQueue)
(def (gxtest-source-queue-empty)
  (cons [] []))

;; : (-> SourceQueue (Values MaybePath SourceQueue))
(def (gxtest-source-queue-pop queue)
  (let ((front (car queue))
        (rear (cdr queue)))
    (cond
     ((and (null? front) (null? rear))
      (values #f (gxtest-source-queue-empty)))
     ((null? front)
      (gxtest-source-queue-pop (cons (reverse rear) [])))
     (else
      (values (car front) (cons (cdr front) rear))))))

;; : (-> SourceQueue (List Path) SourceQueue)
(def (gxtest-source-queue-push-list queue files)
  (cons (car queue)
        (foldl (lambda (file rear)
                 (cons file rear))
               (cdr queue)
               files)))

;; gxtest-source-closure-walk
;;   : (-> PathSet SourceQueue (List Path) (List Path))
;;   | doc m%
;;       `gxtest-source-closure-walk` is an explicit graph traversal driver:
;;       queue order, seen mutation, and output accumulation are the traversal
;;       protocol, not a pure list transform.
;;     %
(def (gxtest-source-closure-walk seen-table queue out)
  (call-with-values
    (lambda () (gxtest-source-queue-pop queue))
    (lambda (file queue)
      (cond
       ;; Imports enter the queue after their consumer.  The accumulated
       ;; reverse discovery order therefore places every DAG dependency before
       ;; the source that imports it, which is the order required by cold gxc
       ;; builds without pre-existing library artifacts.
       ((not file) out)
       ((gxtest-path-seen? seen-table file)
        (gxtest-source-closure-walk seen-table queue out))
       (else
        (gxtest-path-set-add! seen-table file)
        (gxtest-source-closure-walk
         seen-table
         (gxtest-source-queue-push-list
          queue
          (gxtest-source-file-import-list file))
         (cons file out)))))))

;; gxtest-files-source-closure
;;   : (-> (List Path) (List Path) (List Path))
;;   | doc m%
;;       `gxtest-files-source-closure` walks selected test files and their
;;       imported source/test modules with a FIFO queue so dependency discovery
;;       preserves stable order without loop-local `append` growth.
;;     %
(def (gxtest-files-source-closure files seen)
  (gxtest-source-closure-walk (gxtest-path-set seen)
                              (gxtest-source-queue files)
                              []))

;; : (-> (List Path) (List Path))
(def (gxtest-selected-source-files files)
  (gxtest-unique-paths (gxtest-files-source-closure files [])))

;; : (-> (List Path) (List Path))
(def (gxtest-selected-source-module-files files)
  (filter-map (lambda (file)
                (and (string-prefix? "src/" file)
                     (gxtest-source-module-path file)))
              (gxtest-selected-source-files files)))

;; : (-> (List Path) (List Path))
(def (gxtest-selected-test-files files)
  (filter-map (lambda (file)
                (and (string-prefix? "t/" file)
                     file))
              (gxtest-selected-source-files files)))
