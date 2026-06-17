;;; -*- Gerbil -*-
(package: sample/poo-trie-descriptor)
(import :clan/poo/mop :clan/poo/brace)

(define-type (Costep. @ [Type.])
  height: Height
  key: Key
  .sexp<-: costep->sexp
  .validate: validate-costep)

(define-type (Trie. @ [Wrap. methods.table] .validate .wrap .unwrap)
  Wrapper: Identity
  Value: Any
  Key: UInt
  Height: UInt
  T: {(:: @T [methods.bytes<-marshal Type.])
      sexp: `(.@ ,(.@ @ sexp) T)
      .element?: $Trie?
      .marshal: marshal-trie
      .unmarshal: unmarshal-trie}
  Unstep: {(:: @U Type.)
           sexp: `(.@ ,(.@ @ sexp) Unstep)
           .element?: $Unstep?
           .symmetric: symmetric-unstep
           .up: trie-unstep-up}
  Step: {(:: @S Type.)
         sexp: `(.@ ,(.@ @ sexp) Step)
         .element?: $Step?
         .op: apply-trie-step}
  .sexp<-: trie->sexp
  .empty: Empty
  .empty?: Empty?
  .singleton: Leaf
  .ref: trie-ref
  .acons: trie-acons
  .remove: trie-remove
  .foldl: trie-foldl
  .<-list: list->trie
  .list<-: trie->list
  .=?: trie=?)
