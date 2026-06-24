;;; -*- Gerbil -*-
(package: sample/orders)
(export dispatch-order)

;; : (-> Command Args MaybeResult )
(def (native-search-result command args)
  (and (equal? command "search")
       (try-fast-search args)))

;; : (-> Command Args MaybeBinary Result )
(def (run-sibling-native-command command args binary-name)
  (if binary-name
    (let (binary (sibling-binary-path binary-name))
      (if (file-exists? binary)
        (run-binary binary args)
        (missing-native-command command binary)))
    (missing-native-command command #f)))

;; : (-> Command Args Result )
(def (dispatch-native-command command args)
  (if (known-command? command)
    (run-sibling-native-command command args (command-binary-name command))
    (usage-error)))

;; : (-> Command Args Result )
(def (dispatch-order command args)
  (or (native-search-result command args)
      (dispatch-native-command command args)))
