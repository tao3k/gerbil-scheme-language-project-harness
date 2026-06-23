;;; -*- Gerbil -*-
(package: sample/orders)
(export dispatch-order)

;; : (-> Command Args MaybeResult )
(def (native-search-result command args)
  (and (equal? command "search")
       (try-fast-search args)))

;; : (-> Command Args MaybeBinary Result )
(def (run-sibling-or-source command args binary-name)
  (if binary-name
    (let (binary (sibling-binary-path binary-name))
      (if (file-exists? binary)
        (run-binary binary args)
        (run-source command args)))
    (run-source command args)))

;; : (-> Command Args Result )
(def (dispatch-source-command command args)
  (if (known-command? command)
    (run-sibling-or-source command args (command-binary-name command))
    (usage-error)))

;; : (-> Command Args Result )
(def (dispatch-order command args)
  (or (native-search-result command args)
      (dispatch-source-command command args)))
