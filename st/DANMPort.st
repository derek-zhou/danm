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

DANMEntity subclass: DANMPort [
    | context |
    <comment: 'I represent a port of a module'>
    <category: 'DANM'>
    ValidDirections := nil.

    DANMPort class >> initialize [
	<category: 'initialization'>
	ValidDirections := (IdentitySet new)
	    add: #input;
	    add: #output;
	    add: #inout;
	    yourself.
	^self
    ]

    DANMPort class >> newNamed: aName width: w direction: d [
	<category: 'instance creation'>
	^(super newNamed: aName)
	    width: w;
	    direction: d
    ]

    DANMPort class >> newInputPort: aName [
	<category: 'instance creation'>
	^self 
	    newNamed: aName
	    width: 1
	    direction: #input
    ]

    DANMPort class >> newOutputPort: aName [
	<category: 'instance creation'>
	^self 
	    newNamed: aName
	    width: 1
	    direction: #output
    ]

    DANMPort class >> newInputPort: aName width: w [
	<category: 'instance creation'>
	^self 
	    newNamed: aName
	    width: w
	    direction: #input
    ]

    DANMPort class >> newOutputPort: aName width: w [
	<category: 'instance creation'>
	^self 
	    newNamed: aName
	    width: w
	    direction: #output
    ]

    context [
	<category: 'accessing'>
	^context
    ]

    context: newContext [
	<category: 'accessing'>
	context := newContext
    ]

    widthHTMLString [
	<category: 'accessing'>
	| w |
	w := self basicWidth.
	(w isKindOf: Integer) ifTrue: [^w printString].
	^w printStringStyle: #HTML
    ]

    width [
	<category: 'accessing'>
	| myWidth expression |
	expression := self basicWidth.
	(expression isKindOf: Integer) ifTrue: [^expression].
	DANMCurrentDesign use: self context during: [myWidth := expression value].
	(myWidth isInteger and: [myWidth > 0]) ifFalse: [
	    self error: 'Ilegal width: %1' % {myWidth}].
	^myWidth
    ]

    basicWidth [
	<category: 'accessing'>
	^self attribute: #WIDTH
    ]

    direction [
	<category: 'accessing'>
	^self attribute: #DIRECTION
    ]

    isInput [
	<category: 'accessing'>
	^self direction == #input
    ]

    isOutput [
	<category: 'accessing'>
	^self direction == #output
    ]

    isInout [
	<category: 'accessing'>
	^self direction == #inout
    ]

    width: newWidth [
	<category: 'accessing'>
	self setAttribute: #WIDTH to: newWidth
    ]

    direction: newDirection [
	<category: 'accessing'>
	(ValidDirections includes: newDirection) ifFalse: [
	    self error: ('Ilegal direction: %1' bindWith: newDirection)].
	self setAttribute: #DIRECTION to: newDirection
    ]

    <= anotherPort [
	<category: 'accessing'>
	((anotherPort isKindOf: self class) not 
	    or: [self direction = anotherPort direction]) 
		ifTrue: [^super <= anotherPort].
	^self direction <= anotherPort direction
    ]

    msbString [
	<category: 'printing'>
	^(self width - 1) printString
    ]

    printOn: aStream [
	<category: 'printing'>
	self isInput ifTrue: [aStream nextPut: $<].
	self isOutput ifTrue: [aStream nextPut: $>].
	self width == 1 
	    ifTrue: [
		aStream nextPutAll: '%1' % {entityName}]
	    ifFalse: [
		aStream nextPutAll: '%1[%2:0]' % 
		    {entityName. self msbString}]
    ]

    printHTMLOn: aStream [
	<category: 'printing'>
	aStream
	    nextPutAll: '<h3>%1 port <a name="WIRE_%2">%2</a>, width is %3</h3>' % 
	    {self direction asString. entityName. self width}; nl;
	    nextPutAll: '<p>%1</p>' % {self comment}; nl
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	| w |
	w := self width.
	self width == 1
            ifTrue: [
		aStream nextPutAll: '    %1 %2;' % 
		    {self direction asString. self verilogName}; nl ]
	    ifFalse: [
		aStream nextPutAll: '    %1 [%2:0] %3;' % 
		    {self direction asString. w - 1. self verilogName}; nl ]
    ]
]

Eval [
    DANMPort initialize
]

DANMPort subclass: DANMSchematicPort [
    | wire |
    <comment: 'I represent a port of a schematic'>
    <category: 'DANM'>

    DANMSchematicPort class >> newFromWire: w [
	<category: 'instance creation'>
	^(super new)
	    wire: w;
	    name: w name
    ]

    wire [
	<category: 'accessing'>
	^wire
    ]

    wire: newWire [
	<category: 'accessing'>
	wire := newWire
    ]

    basicWidth [
	<category: 'accessing'>
	^wire width
    ]

    direction [
	<category: 'accessing'>
	wire isDrivenInternally ifTrue: [^#output].
	wire isTriState ifTrue: [^#inout].
	^#input
    ]

    copy [
	"copy into a vanila port"
	<category: 'accessing'>
	| clone |
	clone := DANMPort newNamed: self name.
	clone width: self width.
	clone direction: self direction.
	^clone
    ]
]

