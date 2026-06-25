;;; -*- Gerbil -*-
;;; Boundary:
;;; - Widget slot access is a local typed descriptor boundary.
;;; - The descriptor uses Gerbil native `using` slot access instead of a broad
;;;   mixed get/set/validate owner.
(package: sample/widgets)
(export update-widget)

;; widget-slot
;;   : (-> Slot WidgetSlot)
;;   | type Slot = Symbol
;;   | type WidgetSlot = Descriptor
;;   | doc m%
;;       `widget-slot` names the local slot descriptor used by update helpers.
;;     %
(defclass widget-slot (name)
  final: #t)

;; widget-slot-descriptor
;;   : (-> Slot WidgetSlot)
;;   | type Slot = Symbol
;;   | type WidgetSlot = Descriptor
;;   | doc m%
;;       `widget-slot-descriptor slot` creates the typed descriptor once at the
;;       boundary.
;;
;;       # Examples
;;
;;       ```scheme
;;       (widget-slot-descriptor 'name)
;;       ;; => descriptor
;;       ```
;;     %
(def (widget-slot-descriptor slot)
  (widget-slot name: slot))

;; widget-slot-ref
;;   : (-> WidgetSlot Widget Name)
;;   | type WidgetSlot = Descriptor
;;   | type Widget = HashTable
;;   | type Name = String
;;   | doc m%
;;       `widget-slot-ref descriptor widget` owns slot reads through Gerbil
;;       native typed slot access.
;;     %
(def (widget-slot-ref descriptor widget)
  (using (descriptor :- widget-slot)
    (hash-get widget descriptor.name)))

;; widget-slot-set
;;   : (-> WidgetSlot Widget Name Widget)
;;   | type WidgetSlot = Descriptor
;;   | type Widget = HashTable
;;   | type Name = String
;;   | doc m%
;;       `widget-slot-set descriptor widget value` owns copy-on-write updates at
;;       the descriptor boundary.
;;     %
(def (widget-slot-set descriptor widget value)
  (using (descriptor :- widget-slot)
    (let (copy (hash-copy widget))
      (hash-put! copy descriptor.name value)
      copy)))

;; usable-widget-value?
;;   : (-> Name Boolean)
;;   | type Name = String
;;   | doc m%
;;       `usable-widget-value? value` keeps validation separate from mutation.
;;     %
(def (usable-widget-value? value)
  (and value
       (not (equal? value ""))))

;; update-widget
;;   : (-> Widget Slot Name Widget)
;;   | type Widget = HashTable
;;   | type Slot = Symbol
;;   | type Name = String
;;   | doc m%
;;       `update-widget widget slot value` composes the typed descriptor helpers
;;       without depending on a reference-corpus package.
;;
;;       # Examples
;;
;;       ```scheme
;;       (update-widget widget 'name "title")
;;       ;; => widget
;;       ```
;;     %
(def (update-widget widget slot value)
  (let* ((descriptor (widget-slot-descriptor slot))
         (current (widget-slot-ref descriptor widget))
         (next (if (usable-widget-value? value) value current)))
    (widget-slot-set descriptor widget next)))
