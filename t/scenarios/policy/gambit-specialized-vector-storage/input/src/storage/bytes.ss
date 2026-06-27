;;; -*- Gerbil -*-
;;; Input: boxed vectors for byte payloads lose the storage type.
(package: scenario/gambit-specialized-vector-storage/input)
(export copy-bytes)

(def (copy-bytes bytes)
  (list->vector bytes))
