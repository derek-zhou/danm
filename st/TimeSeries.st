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

ExpressionAST subclass: TimeSeries [
    | context value width fireTime tsCC simCC |
    <comment: 'I model a time series, which yield a value every once in a while.'>
    <category: 'simulation'>

    TimeSeries class >> on: aBlock width: w [
	"return a TimeSeries and pass it the block. when evaluate is sent the block is ran until a yield: wait: method is called"
	<category: 'instance creation'>
	^(self new)
	    width: w;
	    forkOn: aBlock;
	    yourself
    ]

    TimeSeries class >> on: aBlock [
	<category: 'instance creation'>
	^(self new)
	    width: 1;
	    forkOn: aBlock
    ]

    TimeSeries class >> clockInit: v0 wait: w0 wait: w1 wait: w2 [
	"this is a infinite clock, with initial value (0/1) in v0 and w0 long. next phase is ~v0(w1) then v0(w2), ~v0(w1),  ..."
	<category: 'instance creation'>
	^DANMClock 
	    startAs: v0
	    wait: w0
	    wait: w1
	    wait: w2
    ]

    context: c type: t [
	<category: 'accessing'>
	context := c
    ]

    context [
	<category: 'accessing'>
	^context
    ]

    width [
	<category: 'accessing'>
	^width
    ]

    width: w [
	<category: 'accessing'>
	width := w
    ]

    fireTime [
	"Should be fired at this time. If it is nil then the TimeSeries is ended and should not evaluate it again"
	<category: 'accessing'>
	^fireTime
    ]

    fireTime: t [
	<category: 'accessing'>
	fireTime := t
    ]

    <= anotherTS [
	<category: 'accessing'>
	^fireTime <= anotherTS fireTime
    ]

    evaluate [
	<category: 'generating'>
	tsCC := tsCC callCC.
	^value
    ]

    staticValue [
	"I don't have a static value"
	<category: 'generating'>
	^nil
    ]

    value: v [
	<category: 'generating'>
	value := v
    ]

    yield: v wait: d [
	<category: 'generating'>
	value := v.
	self wait: d
    ]

    wait: d [
	<category: 'generating'>
	d isNil ifTrue: [fireTime := nil] ifFalse: [fireTime := fireTime + d].
	self sleep
    ]

    waitFor: anotherTs [
	<category: 'generating'>
	fireTime := anotherTs fireTime.
	self sleep
    ]

    sleep [
	<category: 'generating'>
	simCC := simCC callCC.
	"protection against reentrance"
	tsCC := nil
    ]

    forkOn: aBlock [
	"similiar to generator's forkOn"
	<category: 'generating'>
	fireTime := 0.
	simCC := Continuation escapeDo: [:cc | 
	    tsCC := cc.
	    ^self ].
	value := nil.
	tsCC := nil.
	aBlock value: self.
	fireTime := nil.
	simCC oneShotValue
    ]

    test: n [
	<category: 'testing'>
	n timesRepeat: [
	    Transcript nextPutAll: 'At: %1, %2' % {fireTime. self evaluate}; nl.
	    fireTime isNil ifTrue: [
		Transcript nextPutAll: 'Aborting'; nl.
		^self ]]
    ]
]

TimeSeries subclass: DANMClock [
    | initWait firstPhase secondPhase phase |
    <comment: 'I am a simple clock'>
    <category: ''>

    DANMClock class >> startAs: v0 wait: w0 wait: w1 wait: w2 [
	<category: 'instance creation'>
	^self new 
	    init: v0
	    wait: w0
	    wait: w1
	    wait: w2
    ]

    init: v0 wait: w0 wait: w1 wait: w2 [
	<category: 'accessing'>
	value := v0.
	fireTime := 0.
	initWait := w0.
	firstPhase := w1.
	secondPhase := w2.
	phase := 0
    ]

    width [
	<category: 'accessing'>
	^1
    ]

    evaluate [
	<category: 'accessing'>
	phase == 0 ifTrue: [
	    phase := 1.
	    fireTime := initWait.
	    ^value ].
	phase == 1 ifTrue: [
	    phase := 2.
	    fireTime := fireTime + firstPhase.
	    value := value == 0 ifTrue: [1] ifFalse: [0].
	    ^value ].
	phase == 2 ifTrue: [
	    phase := 1.
	    fireTime := fireTime + secondPhase.
	    value := value == 0 ifTrue: [1] ifFalse: [0].
	    ^value ]
    ]
]
