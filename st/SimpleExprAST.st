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

Object subclass: SimpleExprNode [
    <category: 'expression AST'>
    <comment: 'I describe a simple expression node'>

    SimpleExprNode class >> promote: arg [
	<category: 'instance creation'>
	(arg isKindOf: Integer) ifTrue: [^SimpleExprConstant newConstant: arg].
	(arg isKindOf: String) ifTrue: [^#SimpleExprIdentifier newIdentifier: arg].
	(arg isKindOf: self) ifTrue: [^arg].
	self error: 'Can promote %1, which is a %2' % {arg. arg class}
    ]

    optimize [
	<category: 'basic'>
	^self
    ]

    merge: op with: arg [
	<category: 'basic'>
	^nil
    ]

    + arg [
	<category: 'basic'>
	^SimpleAddExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    - arg [
	<category: 'basic'>
	^SimpleSubExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    * arg [
	<category: 'basic'>
	^SimpleMulExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    / arg [
	<category: 'basic'>
	^SimpleDivExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    % arg [
	<category: 'basic'>
	^SimpleModExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    << arg [
	<category: 'basic'>
	^SimpleLSExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    >> arg [
	<category: 'basic'>
	^SimpleRSExpr newBetween: self and: (SimpleExprNode promote: arg)
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: (self printStringStyle: #NONE)
    ]

    printStringStyle: style [
	<category: 'printing'>
	self subclassResponsibility
    ]
]

SimpleExprNode subclass: SimpleExprAST [
    | left right |
    <category: 'expression AST'>
    <comment: 'I describe a simple expression'>

    SimpleExprAST class >> newOps: os among: ps [
	<category: 'instance creation'>
	| factor op |
	ps size == (os size + 1) 
	    ifFalse: [self error: 'operators size must be one less than operand size'].
	factor := ps at: 1.
	1 to: os size do: [ :i | 
	    op := os at: i.
	    factor := self newOp: op between: factor and: (ps at: i + 1) ].
	^factor
    ]

    SimpleExprAST class >> newOp: op between: l and: r [
	<category: 'instance creation'>
	self subclassesDo: [ :each |
	    each op = op ifTrue: [ ^each newBetween: l and: r ]]
    ]

    SimpleExprAST class >> newBetween: l and: r [
	<category: 'instance creation'>
	^(super new)
	    left: l;
	    right: r
    ]

    op [
	<category: 'accessing'>
	self subclassResponsibility
    ]

    left [
	<category: 'accessing'>
	^left
    ]

    left: l [
	<category: 'accessing'>
	left := l
    ]

    right [
	<category: 'accessing'>
	^right
    ]

    right: r [
	<category: 'accessing'>
	right := r
    ]

    optimize [
	"optimize the expression by combining similiar structure"
	<category: 'optimizing'>
	| temp arg op |
	left := left optimize.
	right := right optimize.
	((left isKindOf: SimpleExprConstant) 
	    and: [right isKindOf: SimpleExprConstant]) 
		ifTrue: [^SimpleExprConstant newConstant: self value].
	(left isKindOf: SimpleExprConstant) ifTrue: [self trySwap].
	(right isKindOf: SimpleExprConstant) ifTrue: [
	    op := self class op.
	    arg := right value.
	    (arg == 0 and: [op = '+' | (op = '-') | (op = '<<') | (op = '>>')]) ifTrue: [ ^left ].
		(arg == 1 and: [op = '*' | (op = '/')]) ifTrue: [ ^left ].
		temp := left merge: self class op with: right value.
		temp isNil ifTrue: [ ^self ].
		^temp].
	^self
    ]

    trySwap [
	<category: 'optimizing'>
	^self
    ]

    printStringStyle: style [
	<category: 'printing'>
	^'(%1%2%3)' % 
	    {left printStringStyle: style. self class op. right printStringStyle: style}
    ]
]

SimpleExprAST subclass: SimpleMulExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleMulExpr class >> op [
	<category: 'accessing'>
	^'*'
    ]

    value [
	<category: 'accessing'>
	^left value * right value
    ]

    trySwap [
	<category: 'accessing'>
	| temp |
	temp := left.
	left := right.
	right := temp.
	^self
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifFalse: [^nil].
	op = '*' ifTrue: [
	    right value: right value * arg.
	    ^self ].
	^nil
    ]
]

SimpleExprAST subclass: SimpleAddExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleAddExpr class >> op [
	<category: 'accessing'>
	^'+'
    ]

    value [
	<category: 'accessing'>
	^left value + right value
    ]

    trySwap [
	<category: 'accessing'>
	| temp |
	temp := left.
	left := right.
	right := temp.
	^self
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifFalse: [ ^nil ].
	op = '+' ifTrue: [
	    right value: right value + arg.
	    ^right value == 0 ifTrue: [left] ifFalse: [ self ]].
	op = '-' ifTrue: [
	    right value: right value - arg.
	    ^right value == 0 ifTrue: [left] ifFalse: [self]].
	^nil
    ]
]

SimpleExprAST subclass: SimpleSubExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleSubExpr class >> op [
	<category: 'accessing'>
	^'-'
    ]

    value [
	<category: 'accessing'>
	^left value - right value
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifTrue: [
	    op = '+' ifTrue: [
		right value: right value - arg.
		^right value == 0 ifTrue: [left] ifFalse: [self]].
	    op = '-' ifTrue: [
		right value: right value + arg.
		^right value == 0 ifTrue: [left] ifFalse: [self]]].
	(left isKindOf: SimpleExprConstant) ifTrue: [
	    op = '+' ifTrue: [
		left value: left value + arg.
		^self].
	    op = '-' ifTrue: [
		left value: left value - arg.
		^self]].
	^nil
    ]
]

SimpleExprAST subclass: SimpleDivExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleDivExpr class >> op [
	<category: 'accessing'>
	^'/'
    ]

    value [
	<category: 'accessing'>
	^left value // right value
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifTrue: [
	    op = '/' ifTrue: [
		right value: right value * arg.
		^self ]].
	(left isKindOf: SimpleExprConstant) ifTrue: [
	    op = '*' ifTrue: [
		left value: left value * arg.
		^self]].
	^nil
    ]
]

SimpleExprAST subclass: SimpleModExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleModExpr class >> op [
	<category: 'accessing'>
	^'%'
    ]

    value [
	<category: 'accessing'>
	^left value \\ right value
    ]
]

SimpleExprAST subclass: SimpleRSExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleRSExpr class >> op [
	<category: 'accessing'>
	^'>>'
    ]

    value [
	<category: 'accessing'>
	^left value // (1 bitShift: right value)
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifFalse: [^nil].
	op = '>>' ifTrue: [
	    right value: right value + arg.
	    ^self].
	^nil
    ]
]

SimpleExprAST subclass: SimpleLSExpr [
    <category: 'expression AST'>
    <comment: nil>

    SimpleLSExpr class >> op [
	<category: 'accessing'>
	^'<<'
    ]

    value [
	<category: 'accessing'>
	^left value bitShift: right value
    ]

    merge: op with: arg [
	<category: 'accessing'>
	(right isKindOf: SimpleExprConstant) ifFalse: [^nil].
	op = '<<' ifTrue: [
	    right value: right value + arg.
	    ^self ].
	^nil
    ]
]

SimpleExprNode subclass: SimpleExprConstant [
    | value |    
    <category: 'expression AST'>
    <comment: 'I am AST node that contains an unsigned integer'>

    SimpleExprConstant class >> newConstant: v [
	<category: 'instance creation'>
	^super new value: v
    ]

    value [
	<category: 'accessing'>
	^value
    ]

    value: v [
	<category: 'accessing'>
	value := v
    ]

    printStringStyle: style [
	<category: 'printing'>
	^value printString
    ]
]

SimpleExprNode subclass: SimpleExprIdentifier [
    | identifier |
    <category: 'expression AST'>
    <comment: 'I am AST node that contains an unsigned integer'>

    SimpleExprIdentifier class >> newIdentifier: id [
	<category: 'instance creation'>
	^super new identifier: id
    ]

    value [
	<category: 'accessing'>
	| exp |
	exp := DANMCurrentDesign value parameter: identifier.
	(exp isKindOf: SimpleExprNode) ifTrue: [^exp value].
	^exp
    ]

    identifier [
	<category: 'accessing'>
	^identifier
    ]

    identifier: id [
	<category: 'accessing'>
	(DANMCurrentDesign value parameter: id) isNil ifTrue: [
	    self error: 'Identifier %1 not found in context %2' % 
		{id. DANMCurrentDesign value}].
	identifier := id
    ]

    printStringStyle: style [
	<category: 'printing'>
	^style == #HTML 
	    ifTrue: ['<a href="#PARAM_%1">%1</a>' % {identifier}]
	    ifFalse: [identifier]
    ]
]
