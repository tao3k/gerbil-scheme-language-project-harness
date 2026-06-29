;;; -*- Gerbil -*-
(import :clan/poo)

(def +profile-projection-shape+
  (.o kind: "marlin.config-interface.loop-policy.profile-projection-module.v1"
      profile-id: "default"
      profile-name: "default"
      owner: "agent"
      status: "active"
      source-path: "src/config.ss"
      target-path: "src/config/profile.ss"
      projection-kind: "loop-policy"
      loop-limit: 100
      retry-limit: 3
      timeout-ms: 5000
      priority: "high"
      scheduler: "cooperative"
      memory-policy: "bounded"
      diagnostics: #t
      trace-level: "summary"))

(def (build-profile-projection module-id-value)
  (.mix +profile-projection-shape+
        (.o module-id: module-id-value)))

(def (profile-run-budget profile rows)
  (let ((loop-limit (.ref profile 'loop-limit))
        (timeout-ms (.ref profile 'timeout-ms)))
    (let loop ((rest rows) (count 0) (budget 0))
      (cond
       ((or (null? rest) (>= count loop-limit))
        budget)
       (else
        (loop (cdr rest)
              (+ count 1)
              (+ budget timeout-ms)))))))
