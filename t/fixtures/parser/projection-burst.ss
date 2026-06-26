;;; -*- Gerbil -*-
(package: sample/projection-burst)

;; : (-> OrderFact String)
(def (emit-order-line order)
  (displayln
   (string-append
    "id=" (hash-get order 'id)
    " state=" (hash-get order 'state)
    " total=" (hash-get order 'total)
    " currency=" (hash-get order 'currency)
    " id2=" (hash-get order 'id)
    " state2=" (hash-get order 'state)))
  (displayln
   (string-append
    "total2=" (hash-get order 'total)
    " currency2=" (hash-get order 'currency)
    " id3=" (hash-get order 'id)
    " state3=" (hash-get order 'state)
    " total3=" (hash-get order 'total)
    " currency3=" (hash-get order 'currency))))
