;;; -*- Gerbil -*-
;;; Reusable downstream POO policy scenario fixtures.

(import :gerbil/gambit)

(export write-poo-direct-writeenv-project
        write-poo-io-override-project
        write-downstream-poo-agent-project
        write-poo-method-shape-project
        write-downstream-poo-agent-positive-project)
;; Unit <- String
(def (write-poo-direct-writeenv-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(def (render order) (writeenv order))\n")))
;; String <- String
(def (write-poo-io-override-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(defmethod (@method :wr object) (lambda (self writeenv) self))\n")))
;; Unit <- String
(def (write-downstream-poo-agent-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n(def (make-order id total) (hash (id id) (total total)))\n(def (order-total order) order)\n")
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(defmethod (@method :wr object) (lambda (self writeenv) (writeenv self)))\n")))
;; Unit <- String
(def (write-poo-method-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/methods.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/mop)\n(defmethod (@method order-discount Order) (lambda (self amount) amount))\n")))
;; Unit <- String
(def (write-downstream-poo-agent-positive-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n;;; Fixture preserves parser-visible POO and combinator evidence for agent repair tests.\n(package: sample/orders)\n(import (only-in :clan/poo/object defclass object))\n;;; POO invariant: keep Order as a class so method policy has runtime model evidence.\n;; Order <- Id Total\n(defclass (Order object) (id total) transparent: #t)\n;; Total <- Order\n(def (order-total order) order)\n;;; Composition boundary: summary stays parser-visible as map evidence for R013.\n;; Summary <- Order\n(def (order-summary order) (car (map order-total [order])))\n")
    (write-text (string-append owner "/methods.ss")
                ";;; -*- Gerbil -*-\n;;; Fixture keeps generic and method evidence split for downstream POO repairs.\n(package: sample/orders)\n(import (only-in :clan/poo/mop .defgeneric defmethod @method))\n;;; Generic boundary: declare the method shape before adding specializers.\n;; Amount <- Order Amount\n(.defgeneric (order-discount Order amount))\n;;; Method boundary: keep the override parser-visible without runtime IO mutation.\n;; Amount <- Order Amount\n(defmethod (@method order-discount Order) (lambda (self amount) (car (map (lambda (value) value) [amount]))))\n")))
;; EnsureDir <- String
(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))
;; Unit <- String SourceLine
(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))
;; DeleteFileIfExists <- String
(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))
