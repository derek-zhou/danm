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

ExpressionAST subclass: ASTChoiceOp [
    | condition choices |
    <comment: 'I model a mux, can be 2^n choices, n from 1 to many'>
    <category: 'expression AST'>

    ASTChoiceOp class >> newChoice: c among: cs [
	<category: 'instance creation'>
	^(super new)
	    condition: c;
	    choices: cs
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	condition clearAlias.
	choices do: [:each | each clearAlias]
    ]

    width [
	<category: 'accessing'>
	^choices inject: 0 into: [:m :c | m max: c width]
    ]

    condition [
	<category: 'accessing'>
	^condition
    ]

    condition: c [
	<category: 'accessing'>
	condition := c
    ]

    choices [
	<category: 'accessing'>
	^choices
    ]

    choices: cs [
	<category: 'accessing'>
	choices := cs
    ]

    dependencies [
	<category: 'accessing'>
	^choices inject: condition dependencies into: [ :list :each |
	    list , each dependencies]
    ]

    checkDesign [
	<category: 'basic'>
	| result w |
	result := choices size == (1 bitShift: condition width).
	result := result & condition checkDesign.
	w := self width.
	^choices inject: result into: [ :r :each | 
	    | ew |
	    ew := each width.
	    r & each checkDesign & (ew == 0 | (ew == w))]
    ]

    context: c type: t [
	<category: 'basic'>
	condition context: c type: t.
	choices do: [:each | each context: c type: t]
    ]

    destroy [
	<category: 'basic'>
	condition destroy.
	choices do: [:each | each destroy]
    ]

    evaluate [
	<category: 'basic'>
	| v |
	v := condition evaluate.
	^(choices at: choices size - v) evaluate
    ]

    staticValue [
	<category: 'basic'>
	| v |
	v := condition staticValue.
	v notNil ifTrue: [^(choices at: choices size - v) staticValue].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| v result r |
	condition := condition optimize.
	choices := choices collect: [:each | each optimize].
	v := condition staticValue.
	v notNil ifTrue: [
	    1 to: choices size do: [:i | 
		r := choices at: i.
		i == (choices size - v) ifTrue: [result := r] ifFalse: [r destroy]].
	    result notNil ifTrue: [^result]]
    ]

    printAdditionalVerilogOn: aStream [
	"a?b:c can be inlined. However, the extension a[1:0]?b:c:d:e must be treat
	 differently"
	<category: 'printing'>
	condition printAdditionalVerilogOn: aStream.
	choices do: [:c | c printAdditionalVerilogOn: aStream].
	choices size > 2 ifTrue: [
	    self printVerilogOn: aStream withAlias: 'Choice']
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	| deps |
	choices size > 2 
	    ifFalse: [^super printVerilogOn: aStream]
	    ifTrue: [self printVerilogRegsOn: aStream].
	deps := self dependencies.
	DANMExpressionWire printDependencies: deps uniquify on: aStream.
	self 
	    printCoreVerilogOn: aStream
	    indent: 8
	    blocking: true
    ]

    printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping [
	<category: 'printing'>
	| s w e |
	s := choices size.
	s > 2 ifFalse: [
	    ^super printCoreVerilogOn: aStream
		   indent: num
		   blocking: blocking
		   wrapping: wrapping].
	w := condition width.
	aStream
	    next: num put: $ ;
	    nextPutAll: 'case (%1)' % {condition printStringStyle: #VERILOG}; nl.
	0 to: s - 1 do: [ :i | 
	    aStream
		next: num + 4 put: $ ;
		nextPutAll: '%1''d%2: ' % {w. i}; nl.
		e := choices at: s - i.
		e alias: alias.
		e printCoreVerilogOn: aStream
		  indent: num + 8
		  blocking: blocking
		  wrapping: false].
	aStream
	    next: num put: $ ;
	    nextPutAll: 'endcase'; nl
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	| aStream |
	aStream := WriteStream on: String new.
	aStream nextPutAll: '(%1?' % {condition printStringStyle: style}.
	1 to: choices size do: [ :i | 
	    i == 1 
		ifTrue: [
		    aStream nextPutAll: '%1' % {(choices at: i) printStringStyle: style}]
		ifFalse: [
		    aStream nextPutAll: ':%1' % {(choices at: i) printStringStyle: style}]].
	aStream nextPut: $).
	^aStream contents
    ]
]

ExpressionAST subclass: ASTIfsOp [
    | conditions choices |
    <comment: 'I model a priority encoded mux, like 
    if () 
        a=b; 
    else () 
        a=c; 
    else 
        a=d;
I cannot be sub expression to some other expression though. '>
    <category: 'expression AST'>

    ASTIfsOp class >> newIfs: ifs [
	<category: 'instance creation'>
	| conditions choices |
	conditions := OrderedCollection new.
	choices := OrderedCollection new.
	ifs do: [:each | 
	    | c v |
	    c := ExpressionAST newFrom: each key.
	    v := ExpressionAST newFrom: each value.
	    conditions add: c.
	    choices add: v ].
	^self newConditions: conditions choices: choices
    ]

    ASTIfsOp class >> newConditions: cs choices: vs [
	<category: 'instance creation'>
	cs size == vs size ifFalse: [
	    self error: 'conditions size must the same as the choices size'].
	^(super new)
	    conditions: cs;
	    choices: vs
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	conditions do: [:each | each clearAlias].
	choices do: [:each | each clearAlias]
    ]

    width [
	<category: 'accessing'>
	^choices inject: 0 into: [:m :c | m max: c width]
    ]

    conditions [
	<category: 'accessing'>
	^conditions
    ]

    conditions: cs [
	<category: 'accessing'>
	conditions := cs
    ]

    choices [
	<category: 'accessing'>
	^choices
    ]

    choices: vs [
	<category: 'accessing'>
	choices := vs
    ]

    dependencies [
	<category: 'accessing'>
	| all |
        all := conditions inject: #() into: [ :list :each |
	    list , each dependencies].
	^choices inject: all into: [:list :each | list , each dependencies]
    ]

    isCombinatorial [
	"return whether the expression is fully dependent on all dependencies"
	<category: 'accessing'>
	| v |
	choices do: [:each | each isCombinatorial ifFalse: [^false]].
	v := conditions last staticValue.
	^v notNil and: [v > 0]
    ]

    checkDesign [
	<category: 'basic'>
	| w result c cw |
	w := self width.
	1 to: choices size do: [:i | 
	    c := choices at: i.
	    cw := c width.
	    result := c checkDesign & (conditions at: i) checkDesign.
	    cw == 0 | (cw == w) ifFalse: [result := false].
	    result ifFalse: [^false]].
	^true
    ]

    context: c type: t [
	<category: 'basic'>
	conditions do: [:each | each context: c type: t].
	choices do: [:each | each context: c type: t]
    ]

    destroy [
	<category: 'basic'>
	conditions do: [:each | each destroy].
	choices do: [:each | each destroy]
    ]

    evaluate [
	<category: 'basic'>
	1 to: conditions size do: [:i |
	    (conditions at: i) evaluate > 0 ifTrue: [^(choices at: i) evaluate]].
	^nil
    ]

    staticValue [
	<category: 'basic'>
	| v |
	1 to: conditions size do: [ :i | 
	    v := (conditions at: i) staticValue.
	    v isNil ifTrue: [^nil].
	    v > 0 ifTrue: [^(choices at: i) staticValue]].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| w last text c v ch |
	text := self printString.
	choices := choices collect: [:each | each optimize].
	conditions := conditions collect: [:each | each optimize].
	w := self width.
	last := false.
	1 to: conditions size do: [:i | 
	    c := conditions at: i.
	    ch := choices at: i.
	    v := c staticValue.
	    (last or: [v notNil and: [v = 0]]) ifTrue: [
		c destroy.
		ch destroy.
		conditions at: i put: nil.
		choices at: i put: nil].
	    (v notNil and: [v > 0]) ifTrue: [last := true]].
	choices := choices select: [:each | each notNil].
	conditions := conditions select: [:each | each notNil].
	choices size == 0 ifTrue: [^nil].
	choices size == 1 ifTrue: [
	    v := (conditions at: 1) staticValue.
	    (v notNil and: [v > 0]) ifTrue: [
		ch := choices at: 1.
		^ch]]
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	conditions do: [:c | c printAdditionalVerilogOn: aStream].
	choices do: [:c | c printAdditionalVerilogOn: aStream]
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	| deps |
	self printVerilogRegsOn: aStream.
	deps := conditions inject: #() into: [:list :each |
	    list , each dependencies].
	deps := choices inject: deps into: [:list :each |
	    list , each dependencies].
	DANMExpressionWire printDependencies: deps uniquify on: aStream.
	self printCoreVerilogOn: aStream
	     indent: 8
	     blocking: true
    ]

    printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping [
	<category: 'printing'>
	| e c v |
	wrapping ifTrue: [
	    aStream
		next: num - 2 put: $ ;
		nextPutAll: 'begin'; nl].
	1 to: conditions size do: [ :i | 
	    c := conditions at: i.
	    aStream next: num put: $ .
	    i = 1
		ifTrue: [
		    aStream nextPutAll: 'if (%1)' % {c printStringStyle: #VERILOG}; nl]
		ifFalse: [
		    v := c staticValue.
		    (v notNil and: [v > 0])
                        ifTrue: [
			    aStream nextPutAll: 'else'; nl ]
			ifFalse: [
			    aStream nextPutAll: 'else if (%1)' %
				{(conditions at: i) printStringStyle: #VERILOG}; nl]].
	    e := choices at: i.
	    e alias: alias.
	    e printCoreVerilogOn: aStream
	      indent: num + 4
	      blocking: blocking
	      wrapping: true].
	wrapping ifTrue: [
	    aStream
		next: num - 2 put: $ ;
		nextPutAll: 'end'; nl]
    ]

    basicPrintStringStyle: style [
	"verilog style is covered in printVerilogOn: so I assume html and none
	 style"
	<category: 'printing'>
	| aStream |
	aStream := WriteStream on: String new.
	style == #HTML ifTrue: [
	    aStream nextPutAll: 'Ifs:<br/><table  border="1"><tr><th>condition</th><th>value</th></tr>'; nl.
	    1 to: conditions size do: [:i | 
		aStream nextPutAll: '<tr><td>%1</td><td>%2</td></tr>' % 
		    {(conditions at: i) basicPrintStringStyle: #HTML.
		     (choices at: i) basicPrintStringStyle: #HTML}].
	    aStream nextPutAll: '</table>'; nl].
	style == #NONE ifTrue: [
	    aStream nextPutAll: 'Ifs{'.
	    1 to: conditions size do: [ :i | 
		aStream nextPutAll: '%1->%2.' % 
		    {(conditions at: i) basicPrintStringStyle: #NONE.
		     (choices at: i) basicPrintStringStyle: #NONE}].
	    aStream nextPutAll: '}'].
	^aStream contents
    ]
]

ExpressionAST subclass: ASTCasesOp [
    | subject cases choices |
    <comment: 'I model a mux in a switch-case statement, like 
    case (a) 
        1: b = d;
        c: b = f;
    endcase
I cannot be sub expression to some other expression though. '>
    <category: 'expression AST'>

    ASTCasesOp class >> newCases: table on: subject [
	<category: 'instance creation'>
	| e cases choices |
	cases := OrderedCollection new.
	choices := OrderedCollection new.
	e := ExpressionAST newFrom: subject.
	table do: [ :each | 
	    | c v |
	    c := ExpressionAST newFrom: each key.
	    v := ExpressionAST newFrom: each value.
	    cases add: c.
	    choices add: v.
	    (c isKindOf: ASTDefault) ifTrue: [
		^self newSubject: e
		      cases: cases
		      choices: choices]].
	^self newSubject: e
	      cases: cases
	      choices: choices
    ]

    ASTCasesOp class >> newSubject: s cases: cs choices: vs [
	<category: 'instance creation'>
	cs size = vs size ifFalse: [
	    self error: 'cases size must the same as the choices size'].
	^(super new)
	    subject: s;
	    cases: cs;
	    choices: vs
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	subject clearAlias.
	cases do: [:each | each clearAlias].
	choices do: [:each | each clearAlias]
    ]

    width [
	<category: 'accessing'>
	^choices inject: 0 into: [:m :c | m max: c width]
    ]

    subject [
	<category: 'accessing'>
	^subject
    ]

    subject: s [
	<category: 'accessing'>
	subject := s
    ]

    cases [
	<category: 'accessing'>
	^cases
    ]

    cases: cs [
	<category: 'accessing'>
	cases := cs
    ]

    choices [
	<category: 'accessing'>
	^choices
    ]

    choices: vs [
	<category: 'accessing'>
	choices := vs
    ]

    dependencies [
	<category: 'accessing'>
	| all |
	all := cases inject: subject dependencies into: [:list :each |
	    list , each dependencies].
	^choices inject: all into: [:list :each |
	    list , each dependencies]
    ]

    isCombinatorial [
	"return whether the expression is fully dependent on all dependencies"
	<category: 'accessing'>
	choices do: [:each | each isCombinatorial ifFalse: [^false]].
	^(cases last isKindOf: ASTDefault) | (cases size = (1 bitShift: subject width))
    ]

    checkDesign [
	<category: 'basic'>
	| w result c cw |
	subject checkDesign ifFalse: [^false].
	w := self width.
	1 to: choices size do: [:i | 
	    c := choices at: i.
	    cw := c width.
	    result := c checkDesign & (cases at: i) checkDesign.
	    cw == 0 | (cw == w) ifFalse: [result := false].
	    result ifFalse: [^false]].
	^true
    ]

    context: c type: t [
	<category: 'basic'>
	subject context: c type: t.
	cases do: [:each | each context: c type: t].
	choices do: [:each | each context: c type: t]
    ]

    destroy [
	<category: 'basic'>
	subject destroy.
	cases do: [:each | each destroy].
	choices do: [:each | each destroy]
    ]

    evaluate [
	<category: 'basic'>
	| v c vc |
	v := subject evaluate.
	1 to: cases size do: [ :i | 
	    c := cases at: i.
	    vc := c evaluate.
	    vc isNil | (vc == v) ifTrue: [^(choices at: i) evaluate]].
	^nil
    ]

    staticValue [
	<category: 'basic'>
	| v c vc |
	v := subject staticValue.
	v isNil ifTrue: [^nil].
	1 to: cases size do: [ :i | 
	    c := cases at: i.
	    (c isKindOf: ASTDefault) ifTrue: [^(choices at: i) staticValue].
	    vc := c staticValue.
	    vc isNil ifTrue: [^nil].
	    vc == v ifTrue: [^(choices at: i) staticValue]].
	^nil
    ]

    optimize [
	<category: 'basic'>
	| v w last result c ch |
	w := self width.
	subject := subject optimize.
	v := subject staticValue.
	last := false.
	"it is possible that some choice is optimized to nil"
	1 to: cases size do: [ :i | 
	    c := (cases at: i) optimize.
	    ch := (choices at: i) optimize.
	    cases at: i put: c.
	    choices at: i put: ch.
	    ch isNil ifTrue: [cases at: i put: nil]].
	choices := choices select: [:each | each notNil].
	cases := cases select: [:each | each notNil].
	cases size == 0 ifTrue: [^nil].
	v isNil ifTrue: [^self].
	1 to: cases size do: [ :i | 
	    c := cases at: i.
	    ch := choices at: i.
	    last ifTrue: [
		c destroy.
		ch destroy].
	    (c isKindOf: ASTDefault) | (c staticValue = v) ifTrue: [
		result := ch.
		last := true]].
	result notNil ifTrue: [^result]
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	subject printAdditionalVerilogOn: aStream.
	cases do: [:c | c printAdditionalVerilogOn: aStream].
	choices do: [:c | c printAdditionalVerilogOn: aStream]
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	| deps |
	self printVerilogRegsOn: aStream.
	deps := cases inject: subject dependencies into: [:list :each |
	    list , each dependencies].
	deps := choices inject: deps into: [:list :each |
	    list , each dependencies].
	DANMExpressionWire printDependencies: deps uniquify on: aStream.
	self printCoreVerilogOn: aStream
	     indent: 8
	     blocking: true
    ]

    printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping [
	<category: 'printing'>
	| e |
	aStream
	    next: num put: $ ;
	    nextPutAll: 'case (%1)' % {subject printStringStyle: #VERILOG}; nl.
	1 to: cases size do: [ :i | 
	    aStream
		next: num + 4 put: $ ;
		nextPutAll: '%1: ' % {(cases at: i) printStringStyle: #VERILOG}; nl.
	    e := choices at: i.
	    e alias: alias.
	    e printCoreVerilogOn: aStream
	      indent: num + 8
	      blocking: blocking
	      wrapping: false].
	aStream
	    next: num put: $ ;
	    nextPutAll: 'endcase'; nl
    ]

    basicPrintStringStyle: style [
	"plain style does not make much sense for me and verilog style is covered
	 in printVerilogOn: so I assume html style"
	<category: 'printing'>
	| aStream |
	aStream := WriteStream on: String new.
	style == #HTML ifTrue: [
	    aStream
		nextPutAll: 'Cases on %1:<br/><table  border="1"><tr><th>case</th><th>value</th></tr>' %
		{subject basicPrintStringStyle: #HTML}; nl.
		1 to: cases size do: [ :i | 
		    aStream nextPutAll: '<tr><td>%1</td><td>%2</td></tr>' % 
			{(cases at: i) basicPrintStringStyle: #HTML.
			 (choices at: i) basicPrintStringStyle: #HTML}].
		aStream nextPutAll: '</table>'; nl].
	style == #NONE ifTrue: [
	    aStream nextPutAll: 'Cases(%1){' % {subject basicPrintStringStyle: #NONE}.
	    1 to: cases size do: [ :i | 
		aStream nextPutAll: '%1->%2.' % 
		    {(cases at: i) basicPrintStringStyle: #NONE.
		     (choices at: i) basicPrintStringStyle: #NONE}].
	    aStream nextPutAll: '}'].
	^aStream contents
    ]
]
