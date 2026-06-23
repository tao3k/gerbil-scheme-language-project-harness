;;; -*- Gerbil -*-
(package: sample/orders)
(export dispatch-order)

(def (dispatch-order command args)
  (let (fast-result
        (and (equal? command "search")
             (try-fast-search args)))
    (if fast-result
      fast-result
      (let (binary-name (command-binary-name command))
        (if (known-command? command)
          (if binary-name
            (let (binary (sibling-binary-path binary-name))
              (if (file-exists? binary)
                (run-binary binary args)
                (run-source command args)))
            (run-source command args))
          (usage-error))))))
