;;; -*- Gerbil -*-    
;;; Boundary: exactness, radix, rational, complex, infinities, and nan.    

(import :gerbil/gambit)    

(export numeric-literals)    

(def numeric-literals
  '(#e1.0
    #i3
    1/3
    -10
    +10
    #b101010
    #o52
    #d42
    #x2a
    3+4i
    -2.0-5.0i
    +inf.0
    -inf.0
    +nan.0))    

