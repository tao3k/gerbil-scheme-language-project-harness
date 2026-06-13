;;; -*- Gerbil -*-
;;; Reusable downstream POO policy scenario fixtures.

(import :gerbil/gambit)

(export write-poo-direct-writeenv-project
        write-poo-io-override-project
        write-downstream-poo-agent-project
        write-poo-method-shape-project
        write-downstream-poo-agent-positive-project)

(def (write-poo-direct-writeenv-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(def (render order) (writeenv order))\n")))

(def (write-poo-io-override-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(defmethod (@method :wr object) (lambda (self writeenv) self))\n")))

(def (write-downstream-poo-agent-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(def (process order) order)\n(def (order-total order) order)\n")
    (write-text (string-append owner "/io.ss")
                ";;; -*- Gerbil -*-\n(import :clan/poo/io)\n(defmethod (@method :wr object) (lambda (self writeenv) (writeenv self)))\n")))

(def (write-poo-method-shape-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/methods.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/mop)\n(defmethod (@method order-discount Order) (lambda (self amount) amount))\n")))

(def (write-downstream-poo-agent-positive-project root)
  (let* ((src (string-append root "/src"))
         (owner (string-append src "/orders")))
    (ensure-dir ".run")
    (ensure-dir root)
    (ensure-dir src)
    (ensure-dir owner)
    (write-text (string-append owner "/core.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/object :clan/poo/mop)\n(defclass (Order object) (id total) transparent: #t)\n(def (order-total order) order)\n(def (order-summary order) order)\n")
    (write-text (string-append owner "/methods.ss")
                ";;; -*- Gerbil -*-\n(package: sample/orders)\n(import :clan/poo/mop)\n(.defgeneric (order-discount Order amount))\n(defmethod (@method order-discount Order) (lambda (self amount) amount))\n")))

(def (ensure-dir path)
  (with-catch
   (lambda (_) #f)
   (lambda () (create-directory path))))

(def (write-text path text)
  (delete-file-if-exists path)
  (call-with-output-file path
    (lambda (port) (display text port))))

(def (delete-file-if-exists path)
  (with-catch
   (lambda (_) #f)
   (lambda () (delete-file path))))
