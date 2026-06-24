;;; -*- Gerbil -*-
;;; Wrapped codec facade.
(package: sample/wrapper)
(export WrappedCodec.)

;; WrappedCodec <- Wrapper Functor ParametricFunctor Marshal Bytes JSON String Wrap Unwrap
(define-type (WrappedCodec. @ [Wrapper. Wrap. ParametricFunctor.] T .wrap .unwrap)
  .marshal: (lambda (v port) (marshal T (.unwrap v) port))
  .unmarshal: (lambda (port) (.wrap (unmarshal T port)))
  .bytes<-: (lambda (v) (bytes<- T (.unwrap v)))
  .<-bytes: (lambda (b) (.wrap (<-bytes T b)))
  .json<-: (lambda (v) (json<- T (.unwrap v)))
  .<-json: (lambda (j) (.wrap (<-json T j)))
  .map/wrap: (lambda (f x) (.wrap (f (.unwrap x)))))
