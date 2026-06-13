;;; -*- Gerbil -*-
(package: sample/control-flow)
(import :std/misc/list-builder
        :std/misc/ports)

(def (total xs)
  (let loop ((rest xs) (acc 0)) (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))

(def (plain-let x)
  (let ((value x)) value))

(def (first-or-stop xs)
  (let/cc stop
    (if (null? xs) (stop #f) (car xs))))

(def (safe-take generating)
  (with-list-builder (collect!)
    (try
     (collect! (generating))
     (catch (lambda (c) (and (eof-object? c))) => void)
     (finally (void)))))

(def (capture-output thunk)
  (call-with-output-string
   (lambda (port)
     (parameterize ((current-output-port port))
       (thunk)))))
