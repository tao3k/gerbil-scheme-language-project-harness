;;; -*- Gerbil -*-
(package: sample/poo-defgeneric)

(.defgeneric (location x) slot: location from: type default: 'unknown)
(.defgeneric (factory type) compute-default: default-factory)
