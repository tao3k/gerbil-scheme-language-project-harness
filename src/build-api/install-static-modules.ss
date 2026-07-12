;;; -*- Gerbil -*-
;;; Static module surface for the installed gslph binary.

(export cli-install-static-modules)

(import :gslph/src/build-api/release-modules)

(def (unique-module-paths module-paths)
  (let loop ((rest module-paths) (result []))
    (match rest
      ([] (reverse result))
      ([module-path . tail]
       (if (member module-path result)
         (loop tail result)
         (loop tail (cons module-path result)))))))

(def cli-install-static-modules
  (unique-module-paths
   (cons "cli-launcher.ss" cli-release-modules)))
