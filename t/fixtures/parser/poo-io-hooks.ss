;;; -*- Gerbil -*-
(package: sample/poo-io-hooks)

(import :clan/poo/mop)

;; Protocol
(defprotocol object)

;; Generic
(defgeneric :pr)

;; Generic
(defgeneric :wr)

;; Generic
(defgeneric :json)

;; Generic
(defgeneric :write-json)

;; Void <- Object Port Options
(defmethod (@method :pr object)
  (lambda (self port options) (void)))

;; Void <- Object WriteEnv
(defmethod (@method :wr object)
  (lambda (self writeenv) (void)))

;; Json <- Object
(defmethod (@method :json object)
  (lambda (self) (hash)))

;; Void <- Object Port
(defmethod (@method :write-json object)
  (lambda (self port) (void)))

;; StringAdapter <- JsonHooks
(define-type (methods.string<-json @ [] .json<- .<-json)
  .string<-: (compose string<-json .json<-)
  .<-string: (compose .<-json json<-string))

;; BytesAdapter <- MarshalHooks
(define-type (methods.bytes<-marshal @ [] .marshal .unmarshal)
  .bytes<-: bytes<-marshal
  .<-bytes: marshal<-bytes)
