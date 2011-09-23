Object subclass: #SimpleExprNode
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: 'expression AST'!

SimpleExprNode comment:
    'I describe a simple expression node'!

!SimpleExprNode class methodsFor: 'instance creation'!

promote: arg
    (arg isKindOf: Integer) ifTrue: [ 
        ^SimpleExprConstant newConstant: arg ].
    (arg isKindOf: String) ifTrue: [
        ^#SimpleExprIdentifier newIdentifier: arg ].
    (arg isKindOf: self) ifTrue: [ ^arg ].
    self error: 'Can promote %1, which is a %2' % {arg. arg class}!
!

!SimpleExprNode methodsFor: 'basic'!

optimize
    ^self!

merge: op with: arg
    ^nil!

+ arg
    ^SimpleAddExpr newBetween: self and: (SimpleExprNode promote: arg)!

- arg
    ^SimpleSubExpr newBetween: self and: (SimpleExprNode promote: arg)!

* arg
    ^SimpleMulExpr newBetween: self and: (SimpleExprNode promote: arg)!

/ arg
    ^SimpleDivExpr newBetween: self and: (SimpleExprNode promote: arg)!

% arg
    ^SimpleModExpr newBetween: self and: (SimpleExprNode promote: arg)!

<< arg
    ^SimpleLSExpr newBetween: self  and: (SimpleExprNode promote: arg)!

>> arg
    ^SimpleRSExpr newBetween: self  and: (SimpleExprNode promote: arg)!
!

!SimpleExprNode methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: (self printStringStyle: #NONE)!

printStringStyle: style
    self subclassResponsibility!
!

SimpleExprNode subclass: #SimpleExprAST
               instanceVariableNames: 'left right'
               classVariableNames: ''
               poolDictionaries: ''
               category: 'expression AST'!

SimpleExprAST comment: 
    'I describe a simple expression'!

!SimpleExprAST class methodsFor: 'instance creation'!

newOps: os among: ps
    |factor op|
    ps size == (os size + 1) ifFalse: [
        self error: 'operators size must be one less than operand size' ].
    factor := ps at: 1.
    1 to: os size do: [ :i |
        op := os at: i.
        factor := self newOp: op between: factor and: (ps at: i + 1) ].
    ^factor!

newOp: op between: l and: r
    self subclassesDo: [ :each | 
        each op = op ifTrue: [
            ^each newBetween: l and: r]]!

newBetween: l and: r
    ^super new
        left: l;
        right: r!
!

!SimpleExprAST methodsFor: 'accessing'!

op
    self subclassResponsibility!

left
    ^left!

left: l
    left := l!

right
    ^right!

right: r 
    right := r!
!

!SimpleExprAST methodsFor: 'optimizing'!
optimize
    "optimize the expression by combining similiar structure"
    |temp arg op|
    left := left optimize.
    right := right optimize.
    ((left isKindOf: SimpleExprConstant) and: [ 
        right isKindOf: SimpleExprConstant ]) ifTrue: [ 
            ^SimpleExprConstant newConstant: self value ].
    (left isKindOf: SimpleExprConstant) ifTrue: [ self trySwap ].
    (right isKindOf: SimpleExprConstant) ifTrue: [
        op := self class op.
        arg := right value.
        (arg == 0 and: [ (op='+')|(op='-')|(op ='<<')|(op='>>')]) 
            ifTrue: [ ^left ].
        (arg == 1 and: [ (op='*')|(op='/')]) ifTrue: [ ^left ].
        temp := left merge: self class op with: right value.
        temp isNil ifTrue: [ ^ self ].
        ^temp ].
    ^self!

trySwap
    ^self!
!

!SimpleExprAST methodsFor: 'printing'!

printStringStyle: style
    ^'(%1%2%3)' % {left printStringStyle: style. 
                   self class op. 
                   right printStringStyle: style}!
!

SimpleExprAST subclass: #SimpleMulExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!


!SimpleMulExpr class methodsFor: 'accessing'!
op
    ^'*'!
!

!SimpleMulExpr methodsFor: 'accessing'!
value
    ^(left value) * (right value)!

trySwap
    |temp|
    temp := left.
    left := right.
    right := temp.
^self!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifFalse: [ ^nil ].
    op = '*' ifTrue: [
        right value: right value * arg.
        ^self ].
    ^nil!
!

SimpleExprAST subclass: #SimpleAddExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!SimpleAddExpr class methodsFor: 'accessing'!
op
    ^'+'!
!

!SimpleAddExpr methodsFor: 'accessing'!
value
    ^(left value) + (right value)!

trySwap
    |temp|
    temp := left.
    left := right.
    right := temp.
^self!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifFalse: [ ^nil ].
    op = '+' ifTrue: [
        right value: right value + arg.
        ^(right value == 0) 
            ifTrue: [ left ]
            ifFalse: [ self ]].
    op = '-' ifTrue: [
        right value: right value - arg.
        ^(right value == 0) 
            ifTrue: [ left ]
            ifFalse: [ self ]].
    ^nil!
!

SimpleExprAST subclass: #SimpleSubExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!


!SimpleSubExpr class methodsFor: 'accessing'!
op
    ^'-'!
!

!SimpleSubExpr methodsFor: 'accessing'!
value
    ^(left value) - (right value)!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifTrue: [
        op = '+' ifTrue: [
            right value: right value - arg.
            ^(right value == 0) 
                ifTrue: [ left ]
                ifFalse: [ self ]].
        op = '-' ifTrue: [
            right value: right value + arg.
            ^(right value == 0) 
                ifTrue: [ left ]
                ifFalse: [ self ]]].
    (left isKindOf: SimpleExprConstant) ifTrue: [
        op = '+' ifTrue: [
            left value: left value + arg.
            ^self ].
        op = '-' ifTrue: [
            left value: left value - arg.
            ^ self ]].
    ^nil!
!

SimpleExprAST subclass: #SimpleDivExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!SimpleDivExpr class methodsFor: 'accessing'!
op
    ^'/'!
!

!SimpleDivExpr methodsFor: 'accessing'!
value
    ^(left value) // (right value)!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifTrue: [
        op = '/' ifTrue: [
            right value: right value * arg.
            ^ self ]].
    (left isKindOf: SimpleExprConstant) ifTrue: [
        op = '*' ifTrue: [
            left value: left value * arg.
            ^ self ]].
    ^nil!
!

SimpleExprAST subclass: #SimpleModExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!


!SimpleModExpr class methodsFor: 'accessing'!
op
    ^'%'!
!

!SimpleModExpr methodsFor: 'accessing'!
value
    ^(left value) \\ (right value)!
!

SimpleExprAST subclass: #SimpleRSExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!


!SimpleRSExpr class methodsFor: 'accessing'!
op
    ^'>>'!
!

!SimpleRSExpr methodsFor: 'accessing'!
value
    ^(left value) // (1 bitShift: right value)!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifFalse: [ ^nil ].
    op = '>>' ifTrue: [
        right value: right value + arg.
        ^ self ].
    ^nil!
!

SimpleExprAST subclass: #SimpleLSExpr
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!SimpleMulExpr methodsFor: 'accessing'!

!SimpleLSExpr class methodsFor: 'accessing'!
op
    ^'<<'!
!

!SimpleLSExpr methodsFor: 'accessing'!
value
    ^left value bitShift: right value!

merge: op with: arg
    (right isKindOf: SimpleExprConstant) ifFalse: [ ^nil ].
    op = '<<' ifTrue: [
        right value: right value + arg.
        ^ self ].
    ^nil!
!

SimpleExprNode subclass: #SimpleExprConstant
               instanceVariableNames: 'value'
               classVariableNames: ''
               poolDictionaries: ''
               category: 'expression AST'!

SimpleExprConstant comment:
    'I am AST node that contains an unsigned integer'!

!SimpleExprConstant class methodsFor: 'instance creation'!

newConstant: v
    ^super new
        value: v!
!

!SimpleExprConstant methodsFor: 'accessing'!

value
    ^value!

value: v
    value := v!
!

!SimpleExprConstant methodsFor: 'printing'!

printStringStyle: style
    ^value printString!
!

SimpleExprNode subclass: #SimpleExprIdentifier
               instanceVariableNames: 'identifier'
               classVariableNames: ''
               poolDictionaries: ''
               category: 'expression AST'!

SimpleExprIdentifier comment:
    'I am AST node that contains an unsigned integer'!

!SimpleExprIdentifier class methodsFor: 'instance creation'!

newIdentifier: id
    ^super new
        identifier: id!
!

!SimpleExprIdentifier methodsFor: 'accessing'!

value
    |exp|
    exp := DANMCurrentDesign value parameter: identifier.
    (exp isKindOf: SimpleExprNode) ifTrue: [ ^exp value ].
    ^exp!

identifier
    ^identifier!

identifier: id
    (DANMCurrentDesign value parameter: id) isNil ifTrue: [
        self error: 'Identifier %1 not found in context %2' % {id. DANMCurrentDesign value} ].
    identifier := id!
!

!SimpleExprIdentifier methodsFor: 'printing'!

printStringStyle: style
    ^style == #HTML
        ifTrue: ['<a href="#PARAM_%1">%1</a>' % {identifier}]
        ifFalse: [identifier]!
!
