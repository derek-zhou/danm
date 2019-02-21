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

ExpressionAST subclass: ASTUnaryOp [
    | operand |
    <comment: nil>
    <category: 'expression AST'>

    ASTUnaryOp class >> newOps: os on: e [
	<category: 'instance creation'>
	| factor |
	factor := e.
	os reverseDo: [:op | factor := self newOp: op on: factor].
	^factor
    ]

    ASTUnaryOp class >> newOp: op on: e [
	<category: 'instance creation'>
	self subclassesDo: [:each | each op = op ifTrue: [^each newOn: e]]
    ]

    ASTUnaryOp class >> newOn: e [
	<category: 'instance creation'>
	^super new operand: e
    ]

    ASTUnaryOp class >> hasValidOp: op [
	<category: 'accessing'>
	self subclassesDo: [:each | each op = op ifTrue: [^true]].
	^false
    ]

    ASTUnaryOp class >> op [
	<category: 'accessing'>
	self subclassResponsibility
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	operand clearAlias
    ]

    width [
	<category: 'accessing'>
	^1
    ]

    operand [
	<category: 'accessing'>
	^operand
    ]

    operand: e [
	<category: 'accessing'>
	operand := e
    ]

    dependencies [
	<category: 'accessing'>
	^operand dependencies
    ]

    optimize [
	<category: 'basic'>
	operand := operand optimize.
	^super optimize
    ]

    context: c type: t [
	<category: 'basic'>
	operand context: c type: t
    ]

    checkDesign [
	<category: 'basic'>
	^operand checkDesign
    ]

    destroy [
	<category: 'basic'>
	operand destroy
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	operand printAdditionalVerilogOn: aStream
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	^'(%1%2)' % 
		{self class op.
		operand printStringStyle: style}
    ]
]

ASTUnaryOp subclass: ASTBitwiseNotOp [
    | max |
    <comment: nil>
    <category: 'expression AST'>

    ASTBitwiseNotOp class >> op [
	<category: 'accessing'>
	^$~
    ]

    width [
	<category: 'accessing'>
	^operand width
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := operand evaluate.
	max isNil ifTrue: [max := (1 bitShift: operand width) - 1].
	^max - v
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := operand staticValue.
	v notNil ifTrue: [^(1 bitShift: operand width) - v - 1].
	^nil
    ]
]



ASTUnaryOp subclass: ASTNegateOp [
    | max |
    <comment: nil>
    <category: 'expression AST'>

    ASTNegateOp class >> op [
	<category: 'accessing'>
	^$-
    ]

    width [
	<category: 'accessing'>
	^operand width
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := operand evaluate.
	max isNil ifTrue: [max := 1 bitShift: operand width].
	^max - v
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := operand staticValue.
	v notNil ifTrue: [^(1 bitShift: operand width) - v].
	^nil
    ]
]

ASTUnaryOp subclass: ASTLogicalNotOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTLogicalNotOp class >> op [
	<category: 'accessing'>
	^$!
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := operand evaluate.
	^v > 0 ifTrue: [0] ifFalse: [1]
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := operand staticValue.
	v notNil ifTrue: [^v > 0 ifTrue: [0] ifFalse: [1]].
	^nil
    ]
]

ASTUnaryOp subclass: ASTUnaryAndOp [
    | max |
    <comment: nil>
    <category: 'expression AST'>

    ASTUnaryAndOp class >> op [
	<category: 'accessing'>
	^$&
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := operand evaluate.
	max isNil ifTrue: [max := (1 bitShift: operand width) - 1].
	^v == max ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := operand staticValue.
	v notNil 
	    ifTrue: [^v == ((1 bitShift: operand width) - 1) ifTrue: [1] ifFalse: [0]].
	^nil
    ]
]

ASTUnaryOp subclass: ASTUnaryOrOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTUnaryOrOp class >> op [
	<category: 'accessing'>
	^$|
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := operand evaluate.
	^v == 0 ifTrue: [0] ifFalse: [1]
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := operand staticValue.
	v notNil ifTrue: [^v == 0 ifTrue: [0] ifFalse: [1]].
	^nil
    ]
]

ASTUnaryOp subclass: ASTUnaryXorOp [
    | operandWidth |
    <comment: nil>
    <category: 'expression AST'>

    ASTUnaryXorOp class >> op [
	<category: 'accessing'>
	^$^
    ]

    evaluate [
	<category: 'basic'>
	| v s r |
	v := operand evaluate.
	s := 0.
	operandWidth isNil ifTrue: [operandWidth := operand width].
	operandWidth timesRepeat: [
	    r := v \\ 2.
	    v := v // 2.
	    s := (s + r) \\ 2 ].
	^s
    ]

    staticValue [
	<category: 'basic'>
	| v s r |
	v := operand staticValue.
	v notNil ifTrue: [
	    s := 0.
	    operand width timesRepeat: [
		r := v \\ 2.
		v := v // 2.
		s := (s + r) \\ 2 ].
	    ^s ].
	^nil
    ]
]
