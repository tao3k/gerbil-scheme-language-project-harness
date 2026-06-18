;;; -*- Gerbil -*-
(package: sample/poo-trace-debug)
(import :clan/poo/mop)

;; BaseProbe
(.def base
  value: 1
  label: "base")

;; TraceProbe <- BaseProbe
(.def (trace-probe @ [base])
  value: => (trace-inherited-slot next-method)
  runner: (traced-function "runner" (lambda (x) x))
  debug: (trace-poo self))

;; Protocol
(defprotocol trace-probe)

;; Generic
(defgeneric :pr)

;; Generic
(defgeneric :wr)

;; : (-> TraceProbe Port Void )
(defmethod (@method :pr trace-probe)
  (lambda (self port)
    (display "trace-probe" port)))

;; : (-> TraceProbe Port Void )
(defmethod (@method :wr trace-probe)
  (lambda (self port)
    (display "trace-probe" port)))
