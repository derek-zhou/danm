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

DANMExpressionWire subclass: DANMDelayLine [
    | delay stimuli fireTimes fireValues |
    <comment: 'I am a delay line that model transport delay'>
    <category: ''>

    delay: d [
	<category: 'accessing'>
	delay := d
    ]

    delay [
	<category: 'accessing'>
	^delay
    ]

    addValue: v [
	<category: 'accessing'>
	fireTimes isNil ifTrue: [
	    fireTimes := OrderedCollection new.
	    fireValues := OrderedCollection new ].
	fireValues add: v.
	fireTimes add: context context currentTime + delay.
	stimuli isNil ifTrue: [
	    stimuli := TimeSeries new.
	    stimuli fireTime: fireTimes first.
	    stimuli context: self type: #DIRECT.
	    context context addStimuli: stimuli ]
    ]

    lastValue [
	<category: 'accessing'>
	(fireValues isNil or: [fireValues size == 0]) ifTrue: [^value].
	^fireValues last
    ]

    shiftValue [
	<category: 'accessing'>
	fireTimes removeFirst.
	fireTimes isEmpty
	    ifTrue: [
		stimuli fireTime: nil.
		stimuli := nil ]
	    ifFalse: [
		stimuli fireTime: fireTimes first ].
	^fireValues removeFirst
    ]

    evaluate [
	<category: 'basic'>
	| v |
	(context context isKindOf: DANMSimulator) ifFalse: [^super evaluate].
	ASTIdentifier useNextValue: true.
	v := expression evaluate.
	v = self lastValue ifFalse: [self addValue: v].
	(stimuli notNil and: [stimuli fireTime == context context currentTime]) 
	    ifTrue: [
		self nextValue: self shiftValue.
		nextValue ~= value ifTrue: [^nextValue ]].
	^nil
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '(%1#%2) ' % {expression. delay}
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	self printVerilogRegsOn: aStream.
	expression printAdditionalVerilogOn: aStream.
	expression printVerilogOn: aStream withAlias: 'DelayLine'
    ]

    printBlockVerilogOn: aStream [
	<category: 'printing'>
	| w name |
	name := self verilogName.
	aStream nl;
	    nextPutAll: '    always @(%1)' %
	    {expression printStringStyle: #VERILOG}; nl;
	    nextPutAll: '        %1 <= #%2 %3;' % 
	    {name. delay. expression printStringStyle: #VERILOG. name}; nl.
	expression clearAlias
    ]
]
