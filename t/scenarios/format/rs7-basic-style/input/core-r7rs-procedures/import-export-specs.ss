;;; -*- Gerbil -*-    
;;; Boundary: R7RS import and export specs: only, except, prefix, rename.    

(define-library (fixture rs7 basic import-export)
  (export simple-name
          (rename internal-name public-name))
  (import (scheme base)
          (only (scheme write) write display)
          (except (scheme base) map for-each)
          (prefix (scheme file) file:)
          (rename (scheme read) (read read-datum)))
  (begin
    (define simple-name 'ok)
    (define internal-name 'renamed)))    

