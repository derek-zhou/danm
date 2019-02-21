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

DANMExpressionWire subclass: DANMAssertion [
    <comment: 'I am an assertion in simulation, the value has to be 
as expected, otherwise simulation will abort'>
    <category: 'DANM'>

    isLoaded [
	"supress unloaded warning for assertion"
	<category: 'basic'>
	^true
    ]

    flip [
	<category: 'basic'>
	super flip.
	value == 0 ifTrue: [
	    Transcript nextPutAll: 'Assertion %1 failed in %2!' % 
		{entityName. self context fullPath}; nl.
	    "in simulation the design is flattened, so context context is the
	     simulator"
	    (context context isKindOf: DANMSimulator) ifTrue: [
		context context stop: self ]]
    ]

    nodeStyle [
	<category: 'printing'>
	^'[shape=diamond]'
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '<%1> ' % {expression}
    ]

    printHTMLHeadOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: '<h3><a name="WIRE_%1">Assertion %1</a></h3><ul>' % {entityName}; nl;
	    nextPutAll: '<li>condition: %1</li>' % {expression printStringStyle: #HTML}; nl
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	super basicPrintVerilogOn: aStream.
	aStream
	    nextPutAll: '// synopsys translate_off'; nl;
	    nextPutAll: '`ASSERT(%1)' % {self verilogName}; nl;
	    nextPutAll: '// synopsys translate_on'; nl
    ]
]
