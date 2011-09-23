ExpressionAST subclass: #ASTUnaryOp
              instanceVariableNames: 'operand'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTUnaryOp class methodsFor: 'instance creation'!

newOps: os on: e
    |factor|
    factor := e.
    os reverseDo: [ :op | factor := self newOp: op on: factor ].
    ^factor!

newOp: op on: e
    self subclassesDo: [ :each |
            each op = op ifTrue: [ ^each newOn: e ]]!

newOn: e
    ^super new
        operand: e!
!

!ASTUnaryOp class methodsFor: 'accessing'!

hasValidOp: op
    self subclassesDo: [ :each | 
        each op = op ifTrue: [ ^true ]].
    ^false!

op
    self subclassResponsibility!
!

!ASTUnaryOp methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    operand clearAlias!

width
    ^1!

operand
    ^operand!

operand: e
    operand := e!

dependencies
    ^operand dependencies!
!

!ASTUnaryOp methodsFor: 'basic'!

optimize
    operand := operand optimize.
    ^super optimize!

context: c type: t
    operand context: c type: t!

checkDesign
    ^ operand checkDesign!

destroy
    operand destroy!
!

!ASTUnaryOp methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    operand printAdditionalVerilogOn: aStream!

basicPrintStringStyle: style
    ^'(%1%2)' % {self class op. operand printStringStyle: style}!
!

ASTUnaryOp subclass: #ASTBitwiseNotOp
              instanceVariableNames: 'max'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTBitwiseNotOp methodsFor: 'accessing'!
width
    ^operand width!
!

!ASTBitwiseNotOp methodsFor: 'basic'!

evaluate
    |v|
    v := operand evaluate.
    max isNil ifTrue: [ max := (1 bitShift: operand width) - 1 ].
    ^max - v!

staticValue
    |v|
    v := operand staticValue.
    v notNil ifTrue: [ ^(1 bitShift: operand width) - v - 1 ].
    ^nil!
!

!ASTBitwiseNotOp class methodsFor: 'accessing'!
op
    ^$~!
!

ASTUnaryOp subclass: #ASTNegateOp
              instanceVariableNames: 'max'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTNegateOp methodsFor: 'accessing'!
width
    ^operand width!
!

!ASTNegateOp methodsFor: 'basic'!

evaluate
    |v|
    v := operand evaluate.
    max isNil ifTrue: [ max := 1 bitShift: operand width ].
    ^max - v!

staticValue
    |v|
    v := operand staticValue.
    v notNil ifTrue: [ ^(1 bitShift: operand width) - v ].
    ^nil!
!

!ASTNegateOp class methodsFor: 'accessing'!
op
    ^$-!
!

ASTUnaryOp subclass: #ASTLogicalNotOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTLogicalNotOp methodsFor: 'basic'!

evaluate
    |v|
    v := operand evaluate.
    ^ (v > 0 ifTrue: [ 0 ] ifFalse: [ 1 ])!

staticValue
    |v|
    v := operand staticValue.
    v notNil ifTrue: [ ^ (v > 0 ifTrue: [ 0 ] ifFalse: [ 1 ]) ].
    ^nil!
!

!ASTLogicalNotOp class methodsFor: 'accessing'!
op
    ^$!!
!

ASTUnaryOp subclass: #ASTUnaryAndOp
              instanceVariableNames: 'max'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTUnaryAndOp methodsFor: 'basic'!

evaluate
    |v|
    v := operand evaluate.
    max isNil ifTrue: [ max := (1 bitShift: operand width) - 1 ].
    ^ v == max ifTrue: [ 1 ] ifFalse: [ 0 ]!

staticValue
    |v|
    v := operand staticValue.
    v notNil ifTrue: [
        ^ (v == ((1 bitShift: operand width) - 1) 
               ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTUnaryAndOp class methodsFor: 'accessing'!
op
    ^$&!
!

ASTUnaryOp subclass: #ASTUnaryOrOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTUnaryOrOp methodsFor: 'basic'!

evaluate
    |v|
    v := operand evaluate.
    ^ (v == 0 ifTrue: [ 0 ] ifFalse: [ 1 ])!

staticValue
    |v|
    v := operand staticValue.
    v notNil ifTrue: [ ^ (v == 0 ifTrue: [ 0 ] ifFalse: [ 1 ]) ].
    ^nil!
!

!ASTUnaryOrOp class methodsFor: 'accessing'!
op
    ^$|!
!

ASTUnaryOp subclass: #ASTUnaryXorOp
              instanceVariableNames: 'operandWidth'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTUnaryXorOp methodsFor: 'basic'!

evaluate
    |v s r|
    v := operand evaluate.
    s := 0.
    operandWidth isNil ifTrue: [ operandWidth := operand width ].
    operandWidth timesRepeat: [
        r := v \\ 2.
        v := v // 2.
        s := (s + r) \\ 2 ]. 
    ^ s!

staticValue
    |v s r|
    v := operand staticValue.
    v notNil ifTrue: [
        s := 0.
        operand width timesRepeat: [
            r := v \\ 2.
            v := v // 2.
            s := (s + r) \\ 2 ]. 
        ^ s ].
    ^nil!
!

!ASTUnaryXorOp class methodsFor: 'accessing'!
op
    ^$^!
!

