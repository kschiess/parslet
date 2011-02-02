[ :some | |a b c|
  "A method to illustrate some syntax"
  true & false not & (nil isNil) ifFalse: [self halt; yourself].
  b := self size + super size + super class GlobalVariable.
]

