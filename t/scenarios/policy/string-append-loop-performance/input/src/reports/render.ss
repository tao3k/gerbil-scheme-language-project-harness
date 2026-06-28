;;; -*- Gerbil -*-
(package: sample/reports)

(export render-lines)

(def (render-lines lines)
  (let loop ((remaining lines) (out ""))
    (if (null? remaining)
      out
      (loop (cdr remaining)
            (string-append out (car remaining) "\n")))))
