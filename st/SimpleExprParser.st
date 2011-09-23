Object subclass: #SimpleExprParser
       instanceVariableNames: 'stream'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'expression parsing'!
    
SimpleExprParser comment:
    'I am a parser that parse a string to construct a expression AST'!

!SimpleExprParser class methodsFor: 'instance creation'!

newFromString: str
    ^super new
        stream: (Tokenizer on: (ReadStream on: str))!

on: aTokenizer
    ^super new stream: aTokenizer!
!

!SimpleExprParser methodsFor: 'accessing'!

stream
    ^stream!

stream: s
    stream := s!
!

!SimpleExprParser methodsFor: 'parsing'!

parse
    |e|
    e := self parseOrder1.
    stream atEnd ifFalse: [
        stream parseError: 'garbage at the end' ].
    ^e!

parseExpression
    ^self parseOrder1!

parseOrder1
    "parse a binary op at lowest order: <<, >>"
    |os ps op|
    ps := OrderedCollection new.
    os := OrderedCollection new.
    ps add: self parseOrder2.
    [op := self tryParseOrder1BinaryOp.
     op == nil] whileFalse: [
         os add: op.
         ps add: self parseOrder2 ].
    ^SimpleExprAST newOps: os among: ps!

parseOrder2
    "parse a binary op at second lowest order: +, -"
    |os ps op|
    ps := OrderedCollection new.
    os := OrderedCollection new.
    ps add: self parseOrder3.
    [op := self tryParseOrder2BinaryOp.
     op == nil] whileFalse: [
         os add: op.
         ps add: self parseOrder3 ].
    ^SimpleExprAST newOps: os among: ps!

parseOrder3
    "parse a binary op at third lowest order: *, /, %"
    |os ps op|
    ps := OrderedCollection new.
    os := OrderedCollection new.
    ps add: self parseFactor.
    [op := self tryParseOrder3BinaryOp.
     op == nil] whileFalse: [
         os add: op.
         ps add: self parseFactor ].
    ^SimpleExprAST newOps: os among: ps!

parseFactor
    |token exp|
    (stream testNext: $() ifTrue: [
            exp := self parseOrder1.
            stream expect: $).
            ^exp ].
    token := stream nextToken.
    (token isKindOf: Integer) ifTrue: [ 
        ^SimpleExprConstant newConstant: token ].
    (token isKindOf: String) ifTrue: [
        ^SimpleExprIdentifier newIdentifier: token ].
    stream parseError: 'Expecting number or identifier, but get %1' 
        % {token}!

tryParseOrder1BinaryOp
    |oldPos str|
    oldPos := stream position.
    str := stream nextAvailable: 2. 
    (str = '<<' or: [str = '>>']) ifFalse: [
        stream position: oldPos.
        ^nil ].
    ^str!

tryParseOrder2BinaryOp
    |oldPos char|
    oldPos := stream position.
    char := stream nextToken. 
    (char == $+ or: [char == $-]) ifFalse: [
        stream position: oldPos.
        ^nil ].
    ^char asString!

tryParseOrder3BinaryOp
    |oldPos char|
    oldPos := stream position.
    char := stream nextToken. 
    ((char == $* or: [char == $/]) or: [char == $%]) ifFalse: [
        stream position: oldPos.
        ^nil ].
    ^char asString!
!
