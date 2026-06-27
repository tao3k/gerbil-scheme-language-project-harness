;;; -*- Gerbil -*-
;;; Boundary:
;;; - Actor lifecycle and mailbox protocol are separate local helpers.
(package: scenario/actor-runtime-boundary/expected)
(export deliver-message collect-mailbox start-actor stop-actor run-actor)

;; deliver-message
;;   : (-> Mailbox Message Void)
;;   | doc m%
;;       `deliver-message` owns the mailbox send boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (deliver-message mailbox message)
;;       ;; => void
;;       ```
;;     %
(def (deliver-message mailbox message)
  (send mailbox message))

;; collect-mailbox
;;   : (-> Mailbox (List Message) (List Result))
;;   | doc m%
;;       `collect-mailbox` owns the mailbox receive loop.
;;
;;       # Examples
;;
;;       ```scheme
;;       (collect-mailbox mailbox messages)
;;       ;; => results
;;       ```
;;     %
(def (collect-mailbox mailbox messages)
  (map (lambda (_) (receive mailbox)) messages))

;; start-actor
;;   : (-> Mailbox (List Message) Thread)
;;   | doc m%
;;       `start-actor` owns actor spawn and parameter propagation.
;;
;;       # Examples
;;
;;       ```scheme
;;       (start-actor mailbox messages)
;;       ;; => thread
;;       ```
;;     %
(def (start-actor mailbox messages)
  (spawn
   (lambda ()
     (for-each (lambda (message)
                 (deliver-message mailbox message))
               messages))))

;; stop-actor
;;   : (-> Thread Result)
;;   | doc m%
;;       `stop-actor` owns lifecycle shutdown and join.
;;
;;       # Examples
;;
;;       ```scheme
;;       (stop-actor worker)
;;       ;; => result
;;       ```
;;     %
(def (stop-actor worker)
  (thread-join! worker))

;; run-actor
;;   : (-> Mailbox (List Message) (List Result))
;;   | doc m%
;;       `run-actor` composes the actor lifecycle and mailbox helpers.
;;
;;       # Examples
;;
;;       ```scheme
;;       (run-actor mailbox messages)
;;       ;; => results
;;       ```
;;     %
(def (run-actor mailbox messages)
  (let (worker (start-actor mailbox messages))
    (let (results (collect-mailbox mailbox messages))
      (stop-actor worker)
      results)))
