"
    Copyright (c) 2008-2012 Derek Zhou (derekzhou@gmail.com)

    This file is part of DANM: Design Automation aNd Manipulation.

    DANM is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    DANM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with DANM.  If not, see <http://www.gnu.org/licenses/>.
"

Object subclass: ExpressionParser [
    | stream |
    <category: 'expression parsing'>
    <comment: 'I am a parser that parse a string to construct a expression AST'>

    ExpressionParser class >> newFrom: o [
	<category: 'instance creation'>
	o isNil ifTrue: [^super new].
	(o isKindOf: String) ifTrue: [^self newFromString: o].
	^self newFromString: o printString
    ]

    ExpressionParser class >> newFromString: str [
	<category: 'instance creation'>
	^super new stream: (Tokenizer on: (ReadStream on: str))
    ]

    stream [
	<category: 'accessing'>
	^stream
    ]

    stream: s [
	<category: 'accessing'>
	stream := s
    ]

    parse [
	<category: 'parsing'>
	| e |
	stream isNil ifTrue: [^ASTDefault new].
	e := self parseExpression.
	stream atEnd ifFalse: [stream parseError: 'garbage at the end'].
	^e
    ]

    parseExpression [
	<category: 'parsing'>
	| condition choices |
	condition := self parseSegment.
	(stream testNext: $?) 
	    ifFalse: [ ^condition ]
	    ifTrue: [
		choices := OrderedCollection new.
		choices add: self parseSegment.
		[ stream testNext: $: ] whileTrue: [
		    choices add: self parseSegment ]].
	^ASTChoiceOp newChoice: condition among: choices asArray
    ]

    parseSegmentOrder1 [
	<category: 'parsing'>
	| os ps op |
	ps := OrderedCollection new.
	os := OrderedCollection new.
	ps add: self parseTerm.
	[   op := self tryParseDoubleBinaryOp.
	    op == nil ] whileFalse: [
	    os add: op.
	    ps add: self parseTerm ].
	^ASTBinaryOp newOps: os among: ps
    ]

    parseSegment [
	<category: 'parsing'>
	| os ps op |
	ps := OrderedCollection new.
	os := OrderedCollection new.
	ps add: self parseSegmentOrder1.
	[   op := self tryParseBinaryOp.
	    op == nil ] whileFalse: [
	    os add: op.
	    ps add: self parseSegmentOrder1 ].
	^ASTBinaryOp newOps: os among: ps
    ]

    parseTerm [
	<category: 'parsing'>
	| ops factor op |
	ops := OrderedCollection new.	
	[   op := self tryParseUnaryOp.
	    op == nil ] whileFalse: [
	    ops add: op ].
	factor := self parseModTerm.
	^ASTUnaryOp newOps: ops on: factor
    ]

    parseModTerm [
	<category: 'parsing'>
	| factor size msb lsb step |
	factor := self parseFactor.
	(stream testNext: $*) ifTrue: [
	    size := stream expectKind: Integer.
	    ^ASTDuplicator newDuplicatorOn: factor by: size ].
	(stream testNext: $[) ifTrue: [
	    msb := stream expectKind: Integer.
	    lsb := msb.
	    step := -1.
	    (stream testNext: $:) ifTrue: [lsb := stream expectKind: Integer].
	    (stream testNext: $:) ifTrue: [step := stream expectKind: Integer].
	    stream expect: $].
	    ^ASTExtractor newExtractorOn: factor from: msb to: lsb step: step ].
	^factor
    ]

    parseFactor [
	<category: 'parsing'>
	| c exp |
	(stream testNext: $() ifTrue: [
	    exp := self parseExpression.
	    stream expect: $).
	    ^exp ].
	c := self tryParseConstant.
	c == nil ifFalse: [^c].
	^ASTIdentifier newIdentifier: (stream expectKind: String)
    ]

    tryParseConstant [
	<category: 'parsing'>
	| width radix value |
	width := stream nextToken.
	(width isKindOf: Integer) ifFalse: [
	    stream pushBackLastToken.
	    ^nil ].
	stream testNext: $'.
	radix := self tryParseRadix.
	radix isNil ifTrue: [^ASTConstant newConstant: width].
	value := self parseDigitsWithRadix: radix.
	^ASTConstant newConstant: value width: width
    ]

    tryParseRadix [
	<category: 'parsing'>
	| ch |
	ch := stream next.
	ch isNil ifTrue: [^nil].
	ch := ch asLowercase.
	ch == $b ifTrue: [^2].
	ch == $o ifTrue: [^8].
	ch == $d ifTrue: [^10].
	ch == $h ifTrue: [^16].
	stream pushBack: 1.
	^nil
    ]

    parseDigitsWithRadix: r [
	<category: 'parsing'>
	| oldPos ch value |
	value := 0.
	[   oldPos := stream position.
	    ch := stream next.
	    ch notNil and: [ ch == $_ or: [ ch asUppercase isDigit: r]]] whileTrue: [
	    ch == $_ ifFalse: [ value := value * r + ch asUppercase digitValue ]].
	stream position: oldPos.
	^value
    ]

    tryParseUnaryOp [
	<category: 'parsing'>
	| token |
	token := stream nextToken.
	(ASTUnaryOp hasValidOp: token) ifFalse: [
	    stream pushBackLastToken.
	    ^nil ].
	^token
    ]

    tryParseBinaryOp [
	<category: 'parsing'>
	| token |
	token := stream nextToken.
	(ASTBinaryOp hasValidOp: token) ifFalse: [
	    stream pushBackLastToken.
	    ^nil ].
	^token
    ]

    tryParseDoubleBinaryOp [
	<category: 'parsing'>
	| oldPos str |
	oldPos := stream position.
	str := stream nextAvailable: 2.
	(ASTBinaryOp hasValidOp: str) ifFalse: [
	    stream position: oldPos.
	    ^nil ].
	^str
    ]
]

