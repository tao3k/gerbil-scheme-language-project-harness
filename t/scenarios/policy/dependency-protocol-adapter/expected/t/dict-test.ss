;;; -*- Gerbil -*-
(import :std/test ../src/orders/dict)
(def (table-contract-tests adapter) adapter)
(def order-dict-test
  (test-suite "order dict"
    (test-case "adapter contract witness"
      (check (table-contract-tests (OrderDict. String)) => (OrderDict. String)))))

