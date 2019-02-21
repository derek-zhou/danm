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

ExpressionAST subclass: ASTBinaryOp [
    | left right |
    <comment: nil>
    <category: 'expression AST'>

    ASTBinaryOp class >> newOps: os among: ps [
	<category: 'instance creation'>
	| factor |
        ps size == (os size + 1) ifFalse: [
	    self error: 'operators size must be one less than operand size'].
	factor := ps at: 1.
	1 to: os size do: [ :i | 
	    factor := self newOp: (os at: i)
			   between: factor
			   and: (ps at: i + 1)].
	^factor
    ]

    ASTBinaryOp class >> newOp: op between: l and: r [
	<category: 'instance creation'>
	self subclassesDo: [:each |
	    each op = op ifTrue: [^each newBetween: l and: r]]
    ]

    ASTBinaryOp class >> newBetween: l and: r [
	<category: 'instance creation'>
	^(super new)
	    left: l;
	    right: r
    ]

    ASTBinaryOp class >> hasValidOp: op [
	<category: 'accessing'>
	self subclassesDo: [:each | each op = op ifTrue: [^true]].
	^false
    ]

    ASTBinaryOp class >> op [
	<category: 'accessing'>
	self subclassResponsibility
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	left clearAlias.
	right clearAlias
    ]

    width [
	<category: 'accessing'>
	^left width max: right width
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

    dependencies [
	<category: 'accessing'>
	^left dependencies , right dependencies
    ]

    context: c type: t [
	<category: 'basic'>
	left context: c type: t.
	right context: c type: t
    ]

    checkDesign [
	<category: 'basic'>
	^left checkDesign & right checkDesign
    ]

    destroy [
	<category: 'basic'>
	left destroy.
	right destroy
    ]

    optimize [
	<category: 'basic'>
	left := left optimize.
	right := right optimize.
	^super optimize
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	left printAdditionalVerilogOn: aStream.
	right printAdditionalVerilogOn: aStream
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	^'(%1%2%3)' %
	    {left printStringStyle: style. self class op. right printStringStyle: style}
    ]
]

ASTBinaryOp subclass: ASTPlusOp [
    | mask |
    <comment: nil>
    <category: 'expression AST'>

    ASTPlusOp class >> op [
	<category: 'accessing'>
	^$+
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	mask isNil ifTrue: [
	    mask := (1 bitShift: (left width max: right width)) - 1].
	^vl + vr bitAnd: mask
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    ^vl + vr bitAnd: (1 bitShift: (left width max: right width)) - 1].
	^nil
    ]
]



ASTBinaryOp subclass: ASTMinusOp [
    | shift |
    <comment: nil>
    <category: 'expression AST'>

    ASTMinusOp class >> op [
	<category: 'accessing'>
	^$-
    ]

    evaluate [
	<category: 'basic'>
	| vl vr v |
	vl := left evaluate.
	vr := right evaluate.
	v := vl - vr.
	shift isNil ifTrue: [shift := 1 bitShift: (left width max: right width)].
	v < 0 ifTrue: [v := v + shift].
	^v
    ]

    staticValue [
	<category: 'basic'>
	| vl vr v |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    v := vl - vr.
	    v < 0 ifTrue: [v := v + (1 bitShift: (left width max: right width))].
	    ^v].
	^nil
    ]
]

ASTBinaryOp subclass: ASTEqualOp [
    
    <comment: nil>
    <category: 'expression AST'>

    ASTEqualOp class >> op [
	<category: 'accessing'>
	^'=='
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl == vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^vl == vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTNoLessThanOp [
    
    <comment: nil>
    <category: 'expression AST'>

    ASTNoLessThanOp class >> op [
	<category: 'accessing'>
	^'>='
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl >= vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr s |
	s := (1 bitShift: (left width max: right width)) - 1.
	vl := left staticValue.
	(vl notNil and: [vl == 0]) ifTrue: [^0].
	(vl notNil and: [vl == s]) ifTrue: [^1].
	vr := right staticValue.
	(vr notNil and: [vr == 0]) ifTrue: [^1].
	(vr notNil and: [vr == s]) ifTrue: [^0].
	vl notNil & vr notNil ifTrue: [^vl >= vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTNoGreaterThanOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTNoGreaterThanOp class >> op [
	<category: 'accessing'>
	^'<='
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl <= vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr s |
	s := (1 bitShift: (left width max: right width)) - 1.
	vl := left staticValue.
	(vl notNil and: [vl == 0]) ifTrue: [^1].
	(vl notNil and: [vl == s]) ifTrue: [^0].
	vr := right staticValue.
	(vr notNil and: [vr == 0]) ifTrue: [^0].
	(vr notNil and: [vr == s]) ifTrue: [^1].
	vl notNil & vr notNil ifTrue: [^vl <= vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTUnequalOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTUnequalOp class >> op [
	<category: 'accessing'>
	^'!='
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl ~= vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^vl ~= vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTLessThanOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTLessThanOp class >> op [
	<category: 'accessing'>
	^$<
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl < vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^vl < vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTGreaterThanOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTGreaterThanOp class >> op [
	<category: 'accessing'>
	^$>
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl > vr ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^vl > vr ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTLogicalAndOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTLogicalAndOp class >> op [
	<category: 'accessing'>
	^'&&'
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl > 0 & (vr > 0) ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	(vl notNil and: [vl = 0]) ifTrue: [^0].
	vr := right staticValue.
	(vr notNil and: [vr = 0]) ifTrue: [^0].
	vl notNil & vr notNil ifTrue: [
	    ^vl > 0 & (vr > 0) ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| vl vr |
	left := left optimize.
	right := right optimize.
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    ^ASTConstant newConstant: (vl > 0 & (vr > 0) ifTrue: [1] ifFalse: [0]) width: 1].
	vl notNil ifTrue: [
	    ^vl > 0 
		ifTrue: [ ASTUnaryOrOp newOn: right ]
		ifFalse: [
		    right destroy.
		    ASTConstant newConstant: 0 width: 1]].
	vr notNil ifTrue: [
	    left destroy.
	    ^vr > 0 
		ifTrue: [ ASTUnaryOrOp newOn: left]
		ifFalse: [
		    left destroy.
		    ASTConstant newConstant: 0 width: 1]]
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTLogicalOrOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTLogicalOrOp class >> op [
	<category: 'accessing'>
	^'||'
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl > 0 | (vr > 0) ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	(vl notNil and: [vl > 0]) ifTrue: [^1].
	vr := right staticValue.
	(vr notNil and: [vr > 0]) ifTrue: [^1].
	vl notNil & vr notNil ifTrue: [
	    ^vl > 0 | (vr > 0) ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| vl vr |
	left := left optimize.
	right := right optimize.
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    ^ASTConstant newConstant: (vl > 0 | (vr > 0) ifTrue: [1] ifFalse: [0]) width: 1].
	vl notNil ifTrue: [
	    ^vl > 0 
	        ifFalse: [ ASTUnaryOrOp newOn: right ]
		ifTrue: [
		    right destroy.
		    ASTConstant newConstant: 1 width: 1]].
	vr notNil ifTrue: [
	    ^vr > 0 
	        ifFalse: [ ASTUnaryOrOp newOn: left ]
		ifTrue: [
		    left destroy.
		    ASTConstant newConstant: 1 width: 1]]
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTLogicalXorOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTLogicalXorOp class >> op [
	<category: 'accessing'>
	^'^^'
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^(vl > 0 xor: vr > 0) ifTrue: [1] ifFalse: [0]
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    ^(vl > 0 xor: vr > 0) ifTrue: [1] ifFalse: [0]].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| vl vr r |
	left := left optimize.
	right := right optimize.
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [
	    ^ASTConstant newConstant: ((vl > 0 xor: vr > 0) ifTrue: [1] ifFalse: [0]) width: 1].
	vl notNil ifTrue: [
	    r := ASTUnaryOrOp newOn: right.
	    ^vl > 0 ifFalse: [r] ifTrue: [ASTLogicalNotOp newOn: r]].
	vr notNil ifTrue: [
	    r := ASTUnaryOrOp newOn: left.
	    ^vr > 0 ifFalse: [r] ifTrue: [ASTLogicalNotOp newOn: r]]
    ]

    width [
	<category: 'accessing'>
	^1
    ]
]

ASTBinaryOp subclass: ASTBitwiseAndOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTBitwiseAndOp class >> op [
	<category: 'accessing'>
	^$&
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl bitAnd: vr
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	(vl notNil and: [vl = 0]) ifTrue: [^0].
	vr := right staticValue.
	(vr notNil and: [vr = 0]) ifTrue: [^0].
	vl notNil & vr notNil ifTrue: [^vl bitAnd: vr].
	^nil
    ]
]

ASTBinaryOp subclass: ASTBitwiseOrOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTBitwiseOrOp class >> op [
	<category: 'accessing'>
	^$|
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl bitOr: vr
    ]

    staticValue [
	<category: 'basic'>
	| vl vr s |
	s := (1 bitShift: (left width max: right width)) - 1.
	vl := left staticValue.
	(vl notNil and: [vl = s]) ifTrue: [^s].
	vr := right staticValue.
	(vr notNil and: [vr = s]) ifTrue: [^s].
	vl notNil & vr notNil ifTrue: [^vl bitOr: vr].
	^nil
    ]
]

ASTBinaryOp subclass: ASTBitwiseXorOp [
    <comment: nil>
    <category: 'expression AST'>

    ASTBitwiseXorOp class >> op [
	<category: 'accessing'>
	^$^
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	^vl bitXor: vr
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^vl bitXor: vr].
	^nil
    ]
]

ASTBinaryOp subclass: ASTCommaOp [
    | rightWidth |
    <comment: nil>
    <category: 'expression AST'>

    ASTCommaOp class >> op [
	<category: 'accessing'>
	^$,
    ]

    evaluate [
	<category: 'basic'>
	| vl vr |
	vl := left evaluate.
	vr := right evaluate.
	rightWidth isNil ifTrue: [rightWidth := right width].
	^(vl bitShift: rightWidth) + vr
    ]

    staticValue [
	<category: 'basic'>
	| vl vr |
	vl := left staticValue.
	vr := right staticValue.
	vl notNil & vr notNil ifTrue: [^(vl bitShift: right width) + vr].
	^nil
    ]

    width [
	<category: 'accessing'>
	^left width + right width
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	style == #VERILOG ifFalse: [^super basicPrintStringStyle: style].
	^'{%1%2%3}' % 
	    {left printStringStyle: style. self class op. right printStringStyle: style}
    ]
]

ASTBinaryOp subclass: ASTLatchOp [
    <comment: 'I am a class to assist parsing of a latch, I am not really instanciated'>
    <category: 'expression AST'>

    ASTLatchOp class >> op [
	<category: 'accessing'>
	^$@
    ]

    ASTLatchOp class >> new [
	<category: 'instance creation'>
	self shouldNotImplement
    ]

    ASTLatchOp class >> newBetween: data and: clock [
	"I am instanciate an identifier instead, which point to a latch I made here"
	<category: 'instance creation'>
	| name latch sch |
	sch := DANMCurrentDesign value.
	name := sch uniqueWireNameLike: 'latch'.
	latch := (DANMLatch newNamed: name inContext: sch)
		    expression: data;
		    clock: clock.
	^ASTIdentifier basicNewIdentifier: latch
    ]
]

ASTBinaryOp subclass: ASTFlipflopOp [
    <comment: 'I am a class to assist parsing of a flipflop, I am not really instanciated'>
    <category: 'expression AST'>

    ASTFlipflopOp class >> op [
	<category: 'accessing'>
	^$$
    ]

    ASTFlipflopOp class >> new [
	<category: 'instance creation'>
	self shouldNotImplement
    ]

    ASTFlipflopOp class >> newBetween: data and: clock [
	"I am instanciate an identifier instead, which point to a flop I made here"
	<category: 'instance creation'>
	| name flop sch |
	sch := DANMCurrentDesign value.
	name := sch uniqueWireNameLike: 'flop'.
	flop := (DANMFlipflop newNamed: name inContext: sch)
		    expression: data;
		    clock: clock.
	^ASTIdentifier basicNewIdentifier: flop
    ]
]

