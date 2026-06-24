;;; -*- Gerbil -*-
;;; Worker facade.
(package: sample/concurrency)
(export run-jobs)

;; Result <- Thread Spawn Join Mutex Race Parallel
(def (run-jobs jobs)
  (let* ((mx (make-mutex "jobs"))
         (done? #f)
         (threads
          (map (lambda (job)
                 (spawn
                  (lambda ()
                    (with-lock mx
                      (lambda ()
                        (if done?
                          'skipped
                          (job)))))))
               jobs))
         (results (map thread-join! threads)))
    (set! done? #t)
    results))
