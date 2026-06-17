;;; -*- Gerbil -*-
(package: sample/poo-type-validation)
(import :clan/poo/mop)

(define-type (Tuple. @ [Type.] types)
  types: TypeList
  .element?: tuple?
  .json<-: tuple->json
  .marshal: marshal-tuple)

(define-type (EmailAddress. @ [String.] .validate)
  .validate: => (lambda (super)
                  (lambda (x)
                    (unless (and (string? x) (string-index x #\@))
                      (raise-type-error "EmailAddress" x))
                    (super x)))
  .sexp<-: (lambda (x) x))

(define-type (PositiveList. @ [List.] Elt .validate)
  Elt: Any
  .validate: => (lambda (super)
                  (lambda (xs)
                    (unless (and (list? xs) (andmap positive? xs))
                      (raise-type-error "PositiveList" xs))
                    (super xs)))
  .empty?: null?)
