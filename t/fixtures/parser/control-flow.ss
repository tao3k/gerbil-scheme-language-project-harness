;;; -*- Gerbil -*-
;;; Boundary:
;;; - test owner records policy expectations.
;;; - Keep typed contracts and fixture intent explicit.
(package: sample/control-flow)
(import :std/misc/list-builder
        :std/misc/ports)
;; Parameter <- Boolean
(def current-setting
  (make-parameter #f))
;; Integer <- (List Number)
(def (total xs)
  (let loop ((rest xs) (acc 0)) (if (null? rest) acc (loop (cdr rest) (+ acc (car rest))))))
;; PlainLet <- XX
(def (plain-let x)
  (let ((value x)) value))
;; FirstOrStop <- (List XX)
(def (first-or-stop xs)
  (let/cc stop
    (if (null? xs) (stop #f) (car xs))))
;; SafeTake <- Generating
(def (safe-take generating)
  (with-list-builder (collect!)
    (try
     (collect! (generating))
     (catch (lambda (c) (and (eof-object? c))) => void)
     (finally (void)))))
;; CaptureOutput <- Thunk
(def (capture-output thunk)
  (call-with-output-string
   (lambda (port)
     (parameterize ((current-output-port port))
       (thunk)))))
;; Dynamic <- Thunk
(def (with-dynamic thunk)
  (dynamic-wind
    (lambda () (void))
    thunk
    (lambda () (void))))
;; ParameterCall <- Thunk
(def (parameter-call thunk)
  (call-with-parameters thunk current-setting #t))
;; Worker <- Thunk
(def (worker thunk)
  (spawn/name 'worker thunk))
;; CoroutineSource <- Thunk
(def (coroutine-source thunk)
  (in-cothread thunk))
;; ContinuationDebug <- Thunk
(def (continuation-debug thunk)
  (continuation-capture
   (lambda (cont)
     (thunk))))
;; DecodeEvent <- Event
(def (decode-event event)
  (match event
    (['ok value] value)
    (else #f)))
