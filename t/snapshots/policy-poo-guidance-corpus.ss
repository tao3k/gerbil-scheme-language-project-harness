(policyScenarioCorpus
 (id "poo-guidance-corpus")
 (mode "soft-guidance")
 (contract
  "scenario corpus records POO parser facts and target findings without adding hard policy rules")
 (scenarios
  ((scenario
    (id "poo-type-descriptor")
    (before (phase (targetFindings ()) (pooForms ())))
    (after
     (phase
      (targetFindings ())
      (pooForms
       ((pooForm
         (name "Order.")
         (role "type")
         (supers ("Class."))
         (slots (".slot.id" ".slot.total" ".slot.currency" ".validate" ".new"))
         (options
          ("methodSlot:.slot.id"
           "methodBody:.slot.id:call:Slot"
           "methodBodyQuality:.slot.id:low-level"
           "methodTableBody:low-level"
           "methodSlot:.slot.total"
           "methodBody:.slot.total:call:Slot"
           "methodBodyQuality:.slot.total:low-level"
           "methodTableBody:low-level"
           "methodSlot:.slot.currency"
           "methodBody:.slot.currency:call:Slot"
           "methodBodyQuality:.slot.currency:low-level"
           "methodTableBody:low-level"
           "methodSlot:.validate"
           "methodBody:.validate:identifier"
           "methodBodyQuality:.validate:validation-boundary"
           "methodTableBody:validation-boundary"
           "methodSlot:.new"
           "methodBody:.new:identifier"
           "descriptor:mop"
           "descriptor:class-slot"))
         (selector "src/orders/schema.ss:22-27")))))))
   (scenario
    (id "poo-method-family-serialization")
    (before (phase (targetFindings ()) (pooForms ())))
    (after
     (phase
      (targetFindings ())
      (pooForms
       ((pooForm
         (name "OrderCodec.")
         (role "type")
         (supers ("Wrapper."))
         (slots (".wrap" ".unwrap" ".json<-" ".string<-json" ".bytes<-marshal"))
         (options
          ("methodSlot:.wrap"
           "methodBody:.wrap:identifier"
           "methodSlot:.unwrap"
           "methodBody:.unwrap:identifier"
           "methodSlot:.json<-"
           "methodBody:.json<-:identifier"
           "methodFamily:serialization"
           "serializationSlot:.json<-"
           "methodSlot:.string<-json"
           "methodBody:.string<-json:identifier"
           "methodFamily:serialization"
           "serializationSlot:.string<-json"
           "methodSlot:.bytes<-marshal"
           "methodBody:.bytes<-marshal:identifier"
           "methodFamily:serialization"
           "serializationSlot:.bytes<-marshal"
           "typeclass:wrapper"
           "wrapperAlgebra:wrap-unwrap-bind-map"))
         (selector "src/orders/io.ss:15-20")))))))
   (scenario
    (id "poo-algebra-wrapper")
    (before (phase (targetFindings ()) (pooForms ())))
    (after
     (phase
      (targetFindings ())
      (pooForms
       ((pooForm
         (name "OrderFunctor.")
         (role "type")
         (supers ("Functor."))
         (slots (".map" ".tap" ".ap"))
         (options
          ("methodSlot:.map"
           "methodBody:.map:identifier"
           "methodSlot:.tap"
           "methodBody:.tap:identifier"
           "methodSlot:.ap"
           "methodBody:.ap:identifier"
           "typeclass:functor"
           "functorAlgebra:tap-ap-map"))
         (selector "src/orders/fun.ss:38-41"))
        (pooForm
         (name "OrderWrapper.")
         (role "type")
         (supers ("Wrapper."))
         (slots (".wrap" ".unwrap" ".bind" ".map/wrap"))
         (options
          ("methodSlot:.wrap"
           "methodBody:.wrap:identifier"
           "methodSlot:.unwrap"
           "methodBody:.unwrap:identifier"
           "methodSlot:.bind"
           "methodBody:.bind:identifier"
           "methodSlot:.map/wrap"
           "methodBody:.map/wrap:identifier"
           "typeclass:wrapper"
           "wrapperAlgebra:wrap-unwrap-bind-map"))
         (selector "src/orders/fun.ss:43-47")))))))
   (scenario
    (id "poo-domain-algebra")
    (before (phase (targetFindings ()) (pooForms ())))
    (after
     (phase
      (targetFindings ())
      (pooForms
       ((pooForm
         (name "OrderPolynomial.")
         (role "type")
         (supers ("Polynomial."))
         (slots (".Ring" ".zero" ".add" ".scale"))
         (options
          ("methodSlot:.Ring"
           "methodBody:.Ring:identifier"
           "methodSlot:.zero"
           "methodBody:.zero:call:@list"
           "methodSlot:.add"
           "methodBody:.add:identifier"
           "methodSlot:.scale"
           "methodBody:.scale:identifier"
           "domainAlgebra:polynomial-ring"
           "domainDescriptor:parameterized-ring"))
         (selector "src/math/polynomial.ss:22-26")))))))
   (scenario
    (id "poo-boundary-accessors")
    (before (phase (targetFindings ()) (pooForms ())))
    (after (phase (targetFindings ()) (pooForms ())))))))
