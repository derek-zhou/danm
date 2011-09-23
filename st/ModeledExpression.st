ExpressionAST subclass: #ModeledExpression
    instanceVariableNames: 'references block width'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

ModeledExpression comment:
    'I am a ExpressionAST modeled withan arbitrary block closure'!

!ModeledExpression class methodsFor: 'instance creation'!

with: args do: b
    ^self new
        references: (args collect: [ :each | 
            ExpressionAST newFrom: each ]);
        block: b;
        width: 1!

with: args width: w do: b
    ^self new
        references: (args collect: [ :each | 
            ExpressionAST newFrom: each ]);
        block: b;
        width: w!
!

!ModeledExpression methodsFor: 'accessing'!

references: r
    references := r!

block: b
    block := b!

width: w
    width := w!

width
    ^width!

clearAlias
    super clearAlias.
    references do: [ :each | each clearAlias ]!

dependencies
    ^references inject: #() into: [ :list :each |
        list, each dependencies ]!
!

!ModeledExpression methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    references do: [ :each |
        each printAdditionalVerilogOn: aStream ]!

basicPrintStringStyle: style
    |aStream|
    aStream := WriteStream on: String new.
    aStream nextPutAll: 'Function('.
    references do: [ :each |
        aStream nextPutAll: '%1, ' % {each printStringStyle: style} ].
    aStream nextPut: $).
    ^aStream contents!
!

!ModeledExpression methodsFor: 'basic'!

checkDesign
    ^ references inject: (block argumentCount == references size) 
                 into: [ :r :each | r & each checkDesign ]!

context: c type: t
    references do: [ :each | each context: c type: t ]!

destroy
    references do: [ :each | each destroy ]!

evaluate
    ^ block valueWithArguments: (references collect: [ :each |
        each evaluate ])!

staticValue
    ^[ self evaluate ] ifError: [ nil ]!
!

