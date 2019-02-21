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

DANMExpressionWire subclass: DANMFlipflop [
    | clock |
    <comment: 'I am a wire with a expression of other wires, with 
a flop at the end.'>
    <category: 'DANM'>

    isSequential [
	<category: 'accessing'>
	^true
    ]

    expression: newExpr [
	<category: 'accessing'>
	expression == newExpr ifTrue: [^self].
	newExpr notNil ifTrue: [newExpr context: self type: #DATA].
	expression := newExpr
    ]

    clock: newExpr [
	<category: 'accessing'>
	clock == newExpr ifTrue: [^self].
	newExpr notNil ifTrue: [newExpr context: self type: #CLOCK].
	clock := newExpr
    ]

    directFanins [
	<category: 'accessing'>
	^clock dependencies , expression dependencies
    ]

    dependencies [
	<category: 'accessing'>
	^clock dependencies
    ]

    isDirty [
	"I am dirty when expression is dirty and clock is rising.
	 0: clean 1: expression dirty but clock not rising yet. 2: expression
	 dirty and clock is rising"
	<category: 'accessing'>
	^dirty >= 2
    ]

    setDirty [
	<category: 'accessing'>
	dirty := 2
    ]

    setDataDirty [
	"set expression to be dirty."
	<category: 'accessing'>
	dirty == 0 ifTrue: [dirty := 1]
    ]

    setClockDirty [
	"set clock is rising."
	<category: 'accessing'>
	dirty == 1 ifTrue: [dirty := 2]
    ]

    resetDirty [
	"set to clean."
	<category: 'accessing'>
	dirty := 0
    ]

    evaluate [
	"evaluate self, set nextValue and return it if I am changing. otherwise
	 return nil. The clock is ignored here because this method is invoked
	 only when clock has a rise edge"
	<category: 'basic'>
	ASTIdentifier useNextValue: false.
	self nextValue: expression evaluate.
	nextValue ~= value ifTrue: [^nextValue].
	^nil
    ]

    staticValue [
	<category: 'basic'>
	ASTIdentifier useNextValue: false.
	nextValue isNil ifTrue: [self nextValue: expression staticValue].
	nextValue ~= value ifTrue: [^nextValue].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| e |
	e := expression optimize.
	e isNil ifTrue: [
	    self destroy.
	    ^nil].
	(e isKindOf: ASTConstant) ifTrue: [
	    clock destroy.
	    ^(DANMExpressionWire newReplacementNamed: entityName
				 inContext: self context)
		expression: e;
		value: e evaluate ]
    ]

    resetBy: reset to: resetTo [
	<category: 'basic'>
	^(DANMResetFlop newReplacementNamed: entityName inContext: self context)
	    expression: expression;
	    clock: clock;
	    reset: reset;
	    resetTo: resetTo
    ]

    destroy [
	<category: 'basic'>
	clock destroy.
	super destroy
    ]

    nodeStyle [
	<category: 'printing'>
	^'[shape=box,peripheries=2]'
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '(%1)$(%2) ' % {expression.	clock}
    ]

    printHTMLHeadOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: '<h3><a name="WIRE_%1">Flipflop %1</a></h3><ul><li>width is %2.</li>' % 
	    {entityName. self width}; nl;
	    nextPutAll: '<li>clocked by: %1</li>' % {clock printStringStyle: #HTML};
	    nextPutAll: '<li>data: %1</li>' % {expression printStringStyle: #HTML}; nl
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	self tag notNil ifFalse: [^self].
	self tag: nil.
	self printVerilogRegsOn: aStream
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	self tag notNil ifTrue: [self printVerilogRegsOn: aStream].
	self tag: nil.
	self basicPrintVerilogOn: aStream
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	clock printAdditionalVerilogOn: aStream.
	clock printVerilogOn: aStream withAlias: 'Clock'.
	expression printAdditionalVerilogOn: aStream
    ]

    printBlockVerilogOn: aStream [
	<category: 'printing'>
	| w name |
	name := self verilogName.
	aStream nl.
	aStream nextPutAll: '    always @(posedge %1)' %
	    {clock printStringStyle: #VERILOG}; nl.
	expression alias: name.
	expression 
	    printCoreVerilogOn: aStream
	    indent: 8
	    blocking: false.
	clock clearAlias.
	expression clearAlias
    ]
]

DANMFlipflop subclass: DANMLatch [
    <comment: 'I am a wire with a expression of other wires, with 
a d-latch at the end.'>
    <category: 'DANM'>

    expression: newExpr [
	<category: 'accessing'>
	expression == newExpr ifTrue: [^self].
	newExpr notNil ifTrue: [newExpr context: self type: #LATCHDATA].
	expression := newExpr
    ]

    dependencies [
	<category: 'accessing'>
	^clock dependencies , expression dependencies
    ]

    isDirty [
	"I am dirty when expression is dirty.
	 0: clean 1: expression dirty but clock not rising yet. 2: expression
	 dirty and clock is rising"
	<category: 'accessing'>
	^dirty >= 1
    ]

    resetDirty [
	"from state 2 I go back to clean. However, state 1 is not reset because
	 I could be still be dirty because I may be blocked by the clock"
	<category: 'accessing'>
	dirty isNil | (dirty == 2) ifTrue: [dirty == 0]
    ]

    evaluate [
	"evaluate self, set nextValue and return it if I am changing. otherwise
	 return nil."
	<category: 'basic'>
	ASTIdentifier useNextValue: true.
	clock evaluate > 0 ifTrue: [
	    self nextValue: expression evaluate.
	    nextValue ~= value ifTrue: [^nextValue]].
	^nil
    ]

    staticValue [
	"evaluate self statically, set nextValue and return it if I am changing.
	 otherwise return nil"
	<category: 'basic'>
	ASTIdentifier useNextValue: true.
	nextValue isNil ifTrue: [self nextValue: expression staticValue].
	nextValue ~= value ifTrue: [^nextValue].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| e |
	e := expression optimize.
	e isNil ifTrue: [
	    self destroy.
	    ^nil].
	(e isKindOf: ASTConstant) ifTrue: [
	    clock destroy.
	    ^(DANMExpressionWire newReplacementNamed: entityName
				 inContext: self context)
		expression: e;
		value: e evaluate]
    ]

    nodeStyle [
	<category: 'printing'>
	^'[shape=box]'
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '(%1)@(%2) ' % {expression. clock}
    ]

    printHTMLHeadOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: '<h3><a name="WIRE_%1">Latch %1</a></h3><ul><li>width is %2.</li>' % 
	    {entityName. self width}; nl;
	    nextPutAll: '<li>clocked by: %1</li>' % {clock printStringStyle: #HTML};
	    nextPutAll: '<li>data: %1</li>' % {expression printStringStyle: #HTML}; nl
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	clock printAdditionalVerilogOn: aStream.
	expression printAdditionalVerilogOn: aStream
    ]

    printBlockVerilogOn: aStream [
	<category: 'printing'>
	| name |
	name := self verilogName.
	aStream nl.
	DANMExpressionWire printDependencies: self dependencies uniquify on: aStream.
	aStream nextPutAll: '        if (%1)' % {clock printStringStyle: #VERILOG}; nl.
	expression alias: name.
	expression 
	    printCoreVerilogOn: aStream
	    indent: 12
	    blocking: true.
	clock clearAlias.
	expression clearAlias
    ]
]

DANMFlipflop subclass: DANMResetFlop [
    | reset resetTo |
    <comment: 'I am a flop with an asynchronous reset'>
    <category: 'DANM'>

    reset: newExpr [
	<category: 'accessing'>
	reset == newExpr ifTrue: [^self].
	newExpr notNil ifTrue: [newExpr context: self type: #DIRECT].
	reset := newExpr
    ]

    resetTo: newExpr [
	<category: 'accessing'>
	reset == newExpr ifTrue: [^self].
	resetTo := newExpr
    ]

    directFanins [
	<category: 'accessing'>
	^super directFanins , reset dependencies , resetTo dependencies
    ]

    dependencies [
	<category: 'accessing'>
	^clock dependencies , reset dependencies
    ]

    resetDirty [
	"set to be clean."
	<category: 'basic'>
	dirty := dirty == 3 ifTrue: [1] ifFalse: [0]
    ]

    setDirty [
	"I am dirty when expression is dirty and clock is rising, or reset is
	 changing. 0: clean 1: expression dirty but clock not rising yet.
	 2: expression dirty and clock is rising, 3 reset changed"
	<category: 'basic'>
	dirty := 3
    ]

    minWidth [
	<category: 'basic'>
	expression isNil ifTrue: [^super minWidth].
	expression width > 0 ifTrue: [^expression width].
	resetTo isNil ifTrue: [^super minWidth].
	^resetTo width
    ]

    evaluate [
	"evaluate self, set nextValue and return it if I am changing. otherwise
	 return nil."
	<category: 'basic'>
	ASTIdentifier useNextValue: true.
	"reset condition"
	reset evaluate == 0 ifTrue: [
	    self nextValue: resetTo evaluate.
	    nextValue ~= value ifTrue: [^nextValue] ifFalse: [^nil]].
	"no reset, so it is just like a regular flop"
	dirty ~= 3 ifTrue: [^super evaluate].
	"reset deasserted. no-op, but clock edge aligned here is eaten"
	^nil
    ]

    staticValue [
	<category: 'basic'>
	ASTIdentifier useNextValue: true.
	self nextValue: resetTo staticValue.
	nextValue ~= value ifTrue: [^nextValue].
	^super staticValue
    ]

    optimize [
	<category: 'basic'>
	| e |
	e := reset optimize.
	e isNil ifTrue: [
	    self destroy.
	    ^nil].
	(e isKindOf: ASTConstant) ifTrue: [
	    e evaluate ~= 0 
		ifTrue:	[
		    e destroy.
		    resetTo destroy.
		    ^(DANMFlipflop newReplacementNamed: entityName inContext: self context)
			expression: expression;
			clock: clock;
			optimize]
		ifFalse: [
		    clock destroy.
		    expression destroy.
		    ^(DANMExpressionWire newReplacementNamed: entityName
					 inContext: self context)
			expression: resetTo;
			optimize]]
    ]

    destroy [
	<category: 'basic'>
	reset destroy.
	resetTo destroy.
	super destroy
    ]

    nodeStyle [
	<category: 'printing'>
	^'[shape=box,peripheries=3]'
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '(%1)$(%2)_(%3)->(%4) ' % {expression. clock. reset. resetTo}
    ]

    printHTMLHeadOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: '<h3><a name="WIRE_%1">ResetFlop %1</a></h3><ul><li>width is %2.</li>' % 
	    {entityName. self width}; nl;
	    nextPutAll: '<li>clocked by: %1</li>' % {clock printStringStyle: #HTML};
	    nextPutAll: '<li>resetted by: %1</li>' % {reset printStringStyle: #HTML};
	    nextPutAll: '<li>resetted to: %1</li>' % {resetTo printStringStyle: #HTML};
	    nextPutAll: '<li>data: %1</li>' % {expression printStringStyle: #HTML}; nl
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	clock printAdditionalVerilogOn: aStream.
	clock printVerilogOn: aStream withAlias: 'Clock'.
	reset printAdditionalVerilogOn: aStream.
	reset printVerilogOn: aStream withAlias: 'Reset'.
	expression printAdditionalVerilogOn: aStream
    ]

    printBlockVerilogOn: aStream [
	<category: 'printing'>
	| w name |
	name := self verilogName.
	aStream nl.
	aStream
	    nextPutAll: '    always @(posedge %1 or negedge %2)' % 
	    {clock printStringStyle: #VERILOG. reset printStringStyle: #VERILOG}; nl;
	    nextPutAll: '        if (!%1)' % {reset printStringStyle: #VERILOG}; nl;
	    nextPutAll: '            %1 <= %2;' % 
	    {name. resetTo printStringStyle: #VERILOG}; nl;
	    nextPutAll: '        else'; nl.
	expression alias: name.
	expression 
	    printCoreVerilogOn: aStream
	    indent: 12
	    blocking: false
	    wrapping: true.
	clock clearAlias.
	expression clearAlias
    ]
]
