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

Object subclass: ExpressionAST [
    | alias |
    <category: 'expression AST'>
    <comment: 'I am a abstract class that describe a node in AST'>

    ExpressionAST class >> newFrom: e [
	<category: 'instance creation'>
	e isNil ifTrue: [^ASTDefault new].
	(e isKindOf: ExpressionAST) ifTrue: [^e].
	(e isKindOf: DANMWire) ifTrue: [^ASTIdentifier basicNewIdentifier: e].
	(e isKindOf: Array) ifTrue: [^ASTIfsOp newIfs: e].
	^(ExpressionParser newFromString: e asString) parse
    ]

    alias [
	"An alias is a name used in verilog generation. It is usually the wire name
	 if the expression is a wire directly, or a temporary name to denote the sub
	 expression"
	<category: 'accessing'>
	^alias
    ]

    alias: a [
	<category: 'accessing'>
	alias := a
    ]

    clearAlias [
	<category: 'accessing'>
	alias := nil
    ]

    dependencies [
	<category: 'accessing'>
	^#()
    ]

    isCombinatorial [
	"return whether the expression is fully dependent on all dependencies"
	<category: 'accessing'>
	^true
    ]

    genAliasLike: str [
	"genaerate an unique alias, unless i am an identifier already"
	<category: 'accessing'>
	(self isKindOf: ASTIdentifier) | alias notNil ifTrue: [^false].
	alias := ASTIdentifier uniqueIdentifierLike: str.
	ASTIdentifier addIdentifier: alias with: #DUMMY.
	^true
    ]

    width [
	<category: 'accessing'>
	self subclassResponsibility
    ]

    nonZeroWidth [
	<category: 'accessing'>
	"unknown width default to 32"
	self width = 0 ifTrue: [ ^32 ].
	^self width
    ]
    
    evaluate [
	"evaluate self and return the value. if nil then I am not changing."
	<category: 'basic'>
	^self subclassResponsibility
    ]

    staticValue [
	"If self evaluate to a static value, return it. Otherwise nil"
	<category: 'basic'>
	^self evaluate
    ]

    context: c type: t [
	<category: 'basic'>
	^self
    ]

    checkDesign [
	<category: 'basic'>
	^true
    ]

    destroy [
	<category: 'basic'>
	^self
    ]

    optimizeDependencies [
	<category: 'basic'>
	^self
    ]

    optimize [
	"optimize myself, and return another (simpler) expression if possible, or
	 self if no optimization can be found. Also if the result is not myself
	 the caller is responsible to discard any reference to myself and update
	 reference to use the returned result instead"
	<category: 'basic'>
	| v w |
	self optimizeDependencies.
	v := self staticValue.
	v notNil ifTrue: [
	    w := self width.
	    self destroy.
	    ^ASTConstant newConstant: v width: w ].
	^self
    ]

    printAdditionalVerilogOn: aStream [
	"This method print all prerequsite verilog code. It is usually overidden by
	 the composite expression AST subclasses to recurse down"
	<category: 'printing'>
	^self
    ]

    printVerilogOn: aStream withAlias: str [
	"This method assign an unique alias to the expression and print it when
	 necessary. It is used to break out sub expressions that need to be given a
	 name"
	<category: 'printing'>
	(self genAliasLike: str) ifTrue: [self printVerilogOn: aStream]
    ]

    printVerilogRegsOn: aStream [
	<category: 'printing'>
	self width = 1
	    ifTrue: [
		aStream nextPutAll: '    reg %1;' % {alias}; nl ]
	    ifFalse: [
		aStream nextPutAll: '    reg [%1:0] %2;' % {self nonZeroWidth - 1. alias}; nl ]
    ]

    printVerilogOn: aStream [
	"This method print myself in verilog. The inline style is defined here;
	 for complicated expression where inline style is not appropriate, you need to
	 override this method"
	<category: 'printing'>
	self width = 1
            ifTrue: [
		aStream nextPutAll: '    wire ']
	    ifFalse: [
		aStream nextPutAll: '    wire [%1:0] ' % {self nonZeroWidth - 1}].
	self 
	    printCoreVerilogOn: aStream
	    indent: 0
	    blocking: true
    ]

    printCoreVerilogOn: aStream indent: num blocking: blocking [
	<category: 'printing'>
	^self 
	    printCoreVerilogOn: aStream
	    indent: num
	    blocking: blocking
	    wrapping: false
    ]

    printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping [
	<category: 'printing'>
	| assign |
	assign := blocking ifTrue: ['='] ifFalse: ['<='].
	aStream 
	    next: num put: $ ;
	    nextPutAll: '%1 %2 %3;' % 
	    {alias. assign. self basicPrintStringStyle: #VERILOG}; nl
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: (self basicPrintStringStyle: #NONE)
    ]

    printStringStyle: style [
	"three styles are supported: #NONE, which is the plain version, #HTML,
	 which is plain verisn with hyper link, or #VERILOG. This method is not to be
	 overridden, please override basicPrintStringStyle: The implementation only
	 do alias substitution here; it that fails I will call the basic mathod. So
	 for verilog printing of a expression, you should call:
	 * alias for l-value
	 * basicPrintStringStyle: #VERILOG for top level r-value
	 * printStringStyle: #VERILOG for sub-expressions"
	<category: 'printing'>
	style == #VERILOG & alias notNil ifTrue: [^alias].
	^self basicPrintStringStyle: style
    ]

    basicPrintStringStyle: style [
	"three styles are supported: #NONE, which is the plain version, #HTML,
	 which is plain verisn with hyper link, or #VERILOG. To recurse down into
	 subexpressions please call printStringStyle: so alias substitution will work"
	<category: 'printing'>
	^self class printString
    ]
]

ExpressionAST subclass: ASTConstant [
    | width value |    
    <category: 'expression AST'>
    <comment: 'I am AST node that contains an unsigned value with width'>

    ASTConstant class >> newConstant: v [
	<category: 'instance creation'>
	^(super new)
	    width: 0;
	    value: v
    ]

    ASTConstant class >> newConstant: v width: w [
	<category: 'instance creation'>
	^(super new)
	    width: w;
	    value: (w == 0 ifTrue: [v] ifFalse: [v bitAnd: (1 bitShift: w) - 1])
    ]

    evaluate [
	<category: 'accessing'>
	^value
    ]

    optimize [
	<category: 'accessing'>
	^self
    ]

    value: v [
	<category: 'accessing'>
	value := v
    ]

    checkDesign [
	<category: 'accessing'>
	^value >= 0
    ]

    width [
	<category: 'accessing'>
	^width
    ]

    width: w [
	<category: 'accessing'>
	width := w
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	width == 0 ifTrue: [^value printString].
	^'%1''d%2' % {width. value}
    ]
]

ExpressionAST subclass: ASTDefault [
    <category: 'expression AST'>
    <comment: 'I am AST node that represent default in a case'>

    evaluate [
	<category: 'printing'>
	^nil
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	^'default'
    ]
]

ExpressionAST subclass: ASTDuplicator [
    | subject size subjectWidth |
    <category: 'expression AST'>
    <comment: 'I am either a duplicator like a*3'>

    ASTDuplicator class >> newDuplicatorOn: s by: n [
	<category: 'instance creation'>
	^(super new)
	    subject: s;
	    size: n
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	subject clearAlias
    ]

    width [
	<category: 'accessing'>
	^subject width * size
    ]

    subject [
	<category: 'accessing'>
	^subject
    ]

    subject: s [
	<category: 'accessing'>
	subject := s
    ]

    size [
	<category: 'accessing'>
	^size
    ]

    size: n [
	<category: 'accessing'>
	size := n
    ]

    dependencies [
	<category: 'accessing'>
	^subject dependencies
    ]

    context: c type: t [
	<category: 'basic'>
	subject context: c type: t
    ]

    checkDesign [
	<category: 'basic'>
	^subject checkDesign & (size >= 0)
    ]

    destroy [
	<category: 'basic'>
	subject destroy
    ]

    evaluate [
	<category: 'basic'>
	| v vr |
	vr := subject evaluate.
	v := 0.
	subjectWidth isNil ifTrue: [subjectWidth := subject width].
	size timesRepeat: [v := (v bitShift: subjectWidth) + vr].
	^v
    ]

    staticValue [
	<category: 'basic'>
	| vr v |
	vr := subject staticValue.
	vr notNil ifTrue: [
	    v := 0.
	    size timesRepeat: [v := (v bitShift: subject width) + vr].
	    ^v].
	^nil
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	subject printAdditionalVerilogOn: aStream
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	| aStream |
	aStream := WriteStream on: String new.
	style == #VERILOG
	    ifTrue: [
		aStream nextPutAll: '{%1{%2}}' % 
		    {size. subject printStringStyle: style}]
	    ifFalse: [
		aStream nextPutAll: '(%1*%2)' % 
		    {subject printStringStyle: style. size}].
	^aStream contents
    ]
]

ExpressionAST subclass: ASTExtractor [
    | subject msb lsb step |
    <category: 'expression AST'>
    <comment: 'I am a extractor like a[3:0:-2], which is {a[3], a[1]}'>

    ASTExtractor class >> newExtractorOn: s from: m to: l step: st [
	<category: 'instance creation'>
	st == -1 ifTrue: [
	    ^(ASTSimpleExtractor new)
		    subject: s;
		    msb: m;
		    lsb: l;
		    step: -1].
	^(super new)
	    subject: s;
	    msb: m;
	    lsb: l;
	    step: st
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	subject clearAlias
    ]

    width [
	<category: 'accessing'>
	^(lsb - msb) // step + 1
    ]

    subject [
	<category: 'accessing'>
	^subject
    ]

    subject: s [
	<category: 'accessing'>
	subject := s
    ]

    msb [
	<category: 'accessing'>
	^msb
    ]

    msb: n [
	<category: 'accessing'>
	msb := n
    ]

    lsb [
	<category: 'accessing'>
	^lsb
    ]

    lsb: n [
	<category: 'accessing'>
	lsb := n
    ]

    step [
	<category: 'accessing'>
	^step
    ]

    step: st [
	<category: 'accessing'>
	step := st
    ]

    dependencies [
	<category: 'accessing'>
	^subject dependencies
    ]

    context: c type: t [
	<category: 'basic'>
	subject context: c type: t
    ]

    checkDesign [
	<category: 'basic'>
	subject checkDesign ifFalse: [^false].
	step > 0 ifTrue: [^msb >= 0 & (lsb >= msb) & (lsb < subject width)].
	step < 0 ifTrue: [^lsb >= 0 & (msb >= lsb) & (msb < subject width)].
	^false
    ]

    destroy [
	<category: 'basic'>
	subject destroy
    ]

    evaluateWith: v [
	<category: 'basic'>
	| r |
	r := 0.
	msb to: lsb by: step do: [:i |
	    r := r * 2 + (v bitAt: i + 1)].
	^r
    ]

    evaluate [
	<category: 'basic'>
	^self evaluateWith: subject evaluate
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := subject staticValue.
	v notNil ifTrue: [^self evaluateWith: v].
	^nil
    ]

    printAdditionalVerilogOn: aStream [
	"for example, in (a&b)[3:0] (a&b) part need to be promoted to a wire itself"
	<category: 'printing'>
	subject printAdditionalVerilogOn: aStream.
	subject printVerilogOn: aStream withAlias: 'Expr'
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	| aStream |
	style == #VERILOG ifFalse: [
	    ^'%1[%2:%3:%4]' % 
		{subject printStringStyle: style. msb. lsb. step abs}].
	subject width == 1 ifTrue: [^subject printStringStyle: style].
	aStream := WriteStream on: String new.
	aStream nextPut: ${.
	msb to: lsb by: step do: [ :i | 
	    i == msb ifFalse: [aStream nextPutAll: ', '].
	    aStream nextPutAll: '%1[%2]' % 
		{subject printStringStyle: style. i}].
	aStream nextPut: $}.
	^aStream contents
    ]
]

ASTExtractor subclass: ASTSimpleExtractor [
    | lsbShift mask |
    <category: 'expression AST'>
    <comment: 'I am a simple extractor like a[3:0]'>

    evaluate [
	<category: 'basic'>
	| v |
	v := subject evaluate.
	lsbShift isNil ifTrue: [
	    lsbShift := 1 bitShift: lsb.
	    mask := (1 bitShift: msb - lsb + 1) - 1].
	^v // lsbShift bitAnd: mask
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := subject staticValue.
	v notNil ifTrue: [
	    ^v // (1 bitShift: lsb) bitAnd: (1 bitShift: msb - lsb + 1) - 1].
	^nil
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	subject width == 1 ifTrue: [^subject printStringStyle: style].
	msb ~= lsb 
	    ifTrue: [
		^'%1[%2:%3]' % {subject printStringStyle: style. msb. lsb}]
	    ifFalse: [
		^'%1[%2]' % {subject printStringStyle: style. msb}]
    ]
]

DynamicVariable subclass: CurrentIdentifierDirectory [    
    <category: ''>
    <comment: ''>
]

ExpressionAST subclass: ASTIdentifier [
    | identifier context type |
    <category: 'expression AST'>
    <comment: 'I am a identifier node in an AST'>
    useNextValue := nil.

    ASTIdentifier class >> uniqueIdentifierLike: str [
	<category: 'accessing'>
	^CurrentIdentifierDirectory value uniqueKeyLike: str
    ]

    ASTIdentifier class >> addIdentifier: i with: v [
	<category: 'accessing'>
	CurrentIdentifierDirectory value at: i put: v
    ]

    ASTIdentifier class >> useNextValue: u [
	<category: 'accessing'>
	useNextValue := u
    ]

    ASTIdentifier class >> initialize [
	<category: 'accessing'>
	self useNextValue: false
    ]

    ASTIdentifier class >> newIdentifier: id [
	<category: 'instance creation'>
	| value sch |
	(id isKindOf: DANMWire)
	    ifTrue: [ value := id ]
	    ifFalse: [
		sch := DANMCurrentDesign value.
		value := sch wires at: id ifAbsent: [nil].
		value isNil ifTrue: [value := DANMWire newNamed: id inContext: sch]].
	^self basicNewIdentifier: value
    ]

    ASTIdentifier class >> basicNewIdentifier: v [
	<category: 'instance creation'>
	| id |
	id := super new identifier: v.
	v addRef: id.
	^id
    ]

    width [
	<category: 'accessing'>
	^identifier fastWidth
    ]

    identifier [
	<category: 'accessing'>
	^identifier
    ]

    identifier: id [
	<category: 'accessing'>
	identifier := id
    ]

    dependencies [
	<category: 'accessing'>
	^{self identifier}
    ]

    context [
	"context is the wire that contains this expression. say A = b; then
	 the identifier that points to B has context of A"
	<category: 'accessing'>
	^context
    ]

    context: c type: t [
	<category: 'accessing'>
	context := c.
	type := t
    ]

    type [
	"There are 4 types of identifier: #CLOCK, which is used in an expression
	 for clock of a flop or latch; #DATA, which is used in an expression for
	 data of a flop, #LATCHDATA, which is used in the data of a latch, or
	 #DIRECT, which is used in an combinatorial expression"
	<category: 'accessing'>
	^type
    ]

    destroy [
	<category: 'basic'>
	identifier removeRef: self
    ]

    evaluate [
	<category: 'basic'>
	useNextValue 
	    ifTrue: [^identifier nextValue]
	    ifFalse: [^identifier currentValue]
    ]

    printAdditionalVerilogOn: aStream [
	"print the wire that identifier points to"
	<category: 'printing'>
	identifier printAdditionalVerilogOn: aStream
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	style == #HTML ifTrue: [
	    ^'<a href="#WIRE_%1">%1</a>' % {self identifier name}].
	style == #VERILOG ifTrue: [
	    ^identifier verilogName].
	^identifier name
    ]
]

Eval [
    ASTIdentifier initialize
]
