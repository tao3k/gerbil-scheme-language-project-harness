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

;; : (-> Object Port Options Void )
(defmethod (@method :pr object)
  (lambda (self port options) (void)))

;; : (-> Object WriteEnv Void )
(defmethod (@method :wr object)
  (lambda (self writeenv) (void)))

;; : (-> Object Json )
(defmethod (@method :json object)
  (lambda (self) (hash)))

;; : (-> Object Port Void )
(defmethod (@method :write-json object)
  (lambda (self port) (void)))

;; : (-> JsonHooks StringAdapter )
(define-type (methods.string<-json @ [] .json<- .<-json)
  .string<-: (compose string<-json .json<-)
  .<-string: (compose .<-json json<-string))

;; : (-> MarshalHooks BytesAdapter )
(define-type (methods.bytes<-marshal @ [] .marshal .unmarshal)
  .bytes<-: bytes<-marshal
  .<-bytes: marshal<-bytes)
