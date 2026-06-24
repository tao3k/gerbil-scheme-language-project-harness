;;; -*- Gerbil -*-
;;; POO object literal shape helpers shared by policy modules.

(import :parser/facade
        :policy/agent-poo-callees)

(export poo-large-data-object-literal-call?
        poo-object-literal-slot-spec-count)

;; : (-> CallFact Boolean )
(def (poo-large-data-object-literal-call? call)
  (and (member (call-fact-callee call) +poo-data-object-literal-callees+)
       (>= (poo-object-literal-slot-spec-count call)
           +poo-data-object-literal-min-slot-specs+)))

;; : (-> CallFact Integer )
(def (poo-object-literal-slot-spec-count call)
  (poo-object-literal-slot-spec-count/args (call-fact-arguments call)))

;; : (-> (List String) Integer )
(def (poo-object-literal-slot-spec-count/args args)
  (cond
   ((null? args) 0)
   ((poo-keyword-slot-argument? (car args))
    (+ 1
       (poo-object-literal-slot-spec-count/args
        (if (pair? (cdr args))
          (cddr args)
          (cdr args)))))
   (else
    (+ 1 (poo-object-literal-slot-spec-count/args (cdr args))))))

;; : (-> String Boolean )
(def (poo-keyword-slot-argument? arg)
  (and (> (string-length arg) 0)
       (char=? (string-ref arg (- (string-length arg) 1)) #\:)))
