;;; -*- Gerbil -*-
;;; Boundary:
;;; - Widget updates keep slot lookup, mutation, and validation behind local
;;;   lens helpers instead of one broad owner.
(package: sample/widgets)
(export rename-widget)

;; widget-slot-lens
;;   : (-> Slot Lens)
;;   | doc m%
;;       `widget-slot-lens` creates the local descriptor for a widget slot.
;;
;;       # Examples
;;
;;       ```scheme
;;       (widget-slot-lens 'name)
;;       ;; => lens
;;       ```
;;     %
(def (widget-slot-lens slot)
  slot)

;; lens-ref
;;   : (-> Lens Widget Value)
;;   | doc m%
;;       `lens-ref` owns slot reads through the local lens boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (lens-ref lens widget)
;;       ;; => value
;;       ```
;;     %
(def (lens-ref lens widget)
  (hash-get widget lens))

;; lens-set
;;   : (-> Lens Widget Value Widget)
;;   | doc m%
;;       `lens-set` owns copy-on-write slot updates through the local lens
;;       boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (lens-set lens widget value)
;;       ;; => updated-widget
;;       ```
;;     %
(def (lens-set lens widget value)
  (let (copy (hash-copy widget))
    (hash-put! copy lens value)
    copy))

;; valid-widget-name?
;;   : (-> String Boolean)
;;   | doc m%
;;       `valid-widget-name?` keeps validation at the update boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (valid-widget-name? "title")
;;       ;; => #t
;;       ```
;;     %
(def (valid-widget-name? name)
  (and (string? name)
       (> (string-length name) 0)))

;; rename-widget
;;   : (-> Widget Slot String Widget)
;;   | doc m%
;;       `rename-widget` composes local slot helpers without depending on a
;;       reference corpus package.
;;
;;       # Examples
;;
;;       ```scheme
;;       (rename-widget widget 'name "title")
;;       ;; => widget
;;       ```
;;     %
(def (rename-widget widget slot name)
  (let* ((lens (widget-slot-lens slot))
         (current (lens-ref lens widget))
         (next (if (valid-widget-name? name) name current)))
    (lens-set lens widget next)))
