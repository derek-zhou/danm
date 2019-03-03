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

DANMSchematic subclass: DANMAssertion [
    <comment: 'I am an assertion in simulation. the input din has to be 1,
 otherwise simulation will abort'>
    <category: 'DANM'>

    reference [
	<category: 'accessing'>
	^nil
    ]

    referenceName [
	<category: 'accessing'>
	^'ASSERT'
    ]

    referencePath [
	<category: 'accessing'>
	^context referencePath
    ]

    type [
	<category: 'accessing'>
	^'assertion'
    ]

    canBeSynthesized [
	"I cannot be synthesized"
	<category: 'accessing'>
	^false
    ]

    canBeFlatten [
	"I cannot be flatten"
	<category: 'accessing'>
	^false
    ]

    silentTime [
	<category: 'accessing'>
	^100
    ]

    elaborate [
	<category: 'accessing'>
	wires notNil ifTrue: [^self].
	DANMCurrentDesign use: self during: [
	    self
		clearInstances;
		clearWires;
		init]
    ]

    destroy [
	<category: 'accessing'>
	context removeInstance: self.
	context := nil
    ]

    postProcess [
	<category: 'accessing'>
	"destory myself for synthesis"
	self destroy
    ]

    init [
	<category: 'init'>
	"I have just have one port"
	self createPort: 'din'.
	"this illegal has to be 0"
	self let: 'illegal' be: '~din'
    ]

    printVerilogCoreOn: aStream [
	"print the verilog meat for simple assertion"
	<category: 'printing'>
	self printWiresInVerilogOn: aStream.
	aStream
            nextPutAll: 'always @(illegal)'; nl;
	    nextPutAll: '    if (($stime > %1)&&illegal) begin' %
	    {self silentTime}; nl;
	    nextPutAll: '        $display("Assertion %1 failed at %%d", $stime);' %
	    {self fullPath}; nl;
	    nextPutAll: '        $finish;'; nl
    ]

]

DANMAssertion subclass: DANMAssertionOneHot [
    <comment: 'the input din has to contains at most one 1,
 otherwise simulation will abort'>
    <category: 'DANM'>

    referenceName [
	<category: 'accessing'>
	^'ASSERT_one_hot'
    ]

    width [
	(self hasParameter: 'width') ifFalse: [ ^2 ].
	^self parameterValue: 'width'
    ]

    init [
	<category: 'init'>
	self width > 1 ifFalse: [
	    self error: 'Width has to be more than 1' ].
	"I have just have one port"
	self createPort: 'din' width: self width.
	self let: 'din_except0'
	     be: 'din[%1:1]' % {self width - 1}.
	self let: 'din_except%1' % {self width - 1}
	     be: 'din[%1:0]' % {self width - 2}.
	1 to: self width - 2 do: [ :i |
	    self let: 'din_except%1' % {i} be: 'din[%1:%2],din[%3:0]' %
		{self width - 1. i+1. i-1} ].
	self let: 'illegal'
	     beOneHotChoices: ((self width - 1 to: 0 by: -1) collect: [ :i |
		 '|din_except%1' % {i} ])
		 on: 'din'
    ]

]

DANMAssertion subclass: DANMAssertionNoBitPattern [
    <comment: 'the one bit input din cannot have a pattern as givven,
 otherwise simulation will abort'>
    <category: 'DANM'>

    referenceName [
	<category: 'accessing'>
	^'ASSERT_no_bit_pattern'
    ]

    width [
	(self hasParameter: 'width') ifFalse: [ ^3 ].
	^self parameterValue: 'width'
    ]

    init [
	<category: 'init'>
	self
	     createPort: 'clk';
	     createPort: 'din';
	     createPort: 'pattern' width: self width.

	self let: 'shifter'
	     beClocked: 'shift[%1:0],din' % {self width - 2}.
	self let: 'illegal' be: '((shifter,din)==pattern)$clk'
    ]

]
