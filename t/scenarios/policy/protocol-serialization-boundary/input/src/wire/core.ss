;;; -*- Gerbil -*-
;;; Wire facade.
(package: sample/wire)
(export encode-wire)

;; Bytes <- JSON String Marshal
(def (encode-wire payload tag)
  (let* ((json (string-append "{\"tag\":\"" tag "\",\"payload\":" payload "}"))
         (body (string-append "marshal:" json))
         (bytes (string->bytes body)))
    bytes))
