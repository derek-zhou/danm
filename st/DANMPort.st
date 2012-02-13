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

DANMEntity subclass: #DANMPort
           instanceVariableNames: 'context'
           classVariableNames: 'ValidDirections'
           poolDictionaries: ''
           category: 'DANM'!

DANMPort comment: 'I represent a port of a module'!

!DANMPort class methodsFor: 'initialization'!

initialize
    ValidDirections := IdentitySet new
        add: #input;
        add: #output;
        add: #inout;
        yourself.
    ^self!
!

DANMPort initialize!

!DANMPort methodsFor: 'accessing'!

"My context is the module that includes me"
context
    ^context!

context: newContext
    context := newContext!

widthHTMLString
    |w|
    w := self basicWidth.
    (w isKindOf: Integer) ifTrue: [ ^w printString ].
    ^w printStringStyle: #HTML!

width
    |myWidth expression|
    expression := self basicWidth.
    (expression isKindOf: Integer) ifTrue: [ ^expression ].
    DANMCurrentDesign use: self context during: [
        myWidth := expression value ].
    (myWidth isInteger and: [myWidth > 0]) ifFalse: [
        self error: ('Ilegal width: %1' % {myWidth}) ].
    ^myWidth!

basicWidth
    ^self attribute: #WIDTH!

direction
    ^self attribute: #DIRECTION!

isInput
    ^(self direction == #input)!

isOutput
    ^(self direction == #output)!

isInout
    ^(self direction == #inout)!    

width: newWidth
    self setAttribute: #WIDTH to: newWidth!

direction: newDirection
    (ValidDirections includes: newDirection) ifFalse: [
        self error: ('Ilegal direction: %1' bindWith: newDirection)].
    self setAttribute: #DIRECTION to: newDirection!

<= anotherPort
   (((anotherPort isKindOf: self class) not) or: [
       self direction = anotherPort direction]) ifTrue: [
       ^ super <= anotherPort ].
   ^ self direction <= anotherPort direction!
!

!DANMPort class methodsFor: 'instance creation'!

newNamed: aName width: w direction: d 
    ^ (super newNamed: aName)
        width: w; direction: d!

newInputPort: aName
    ^self newNamed: aName width: 1 direction: #input!

newOutputPort: aName
    ^self newNamed: aName width: 1 direction: #output!

newInputPort: aName width: w
    ^self newNamed: aName width: w direction: #input!

newOutputPort: aName width: w
    ^self newNamed: aName width: w direction: #output!
!

!DANMPort methodsFor: 'printing'!

msbString
    ^(self width - 1) printString!

printOn: aStream
    (self isInput) ifTrue: [ aStream nextPut: $< ].
    (self isOutput) ifTrue: [ aStream nextPut: $> ].
    ((self width) == 1) 
        ifTrue: [
            aStream nextPutAll: ('%1' % {entityName})]
        ifFalse: [
            aStream nextPutAll: '%1[%2:0]' % 
                {entityName. self msbString}]!

printHTMLOn: aStream
    aStream 
        nextPutAll: ('<h3>%1 port <a name="WIRE_%2">%2</a>, width is %3</h3>' 
                         % {self direction asString. entityName. 
                            self width});
        nl;
      nextPutAll: ('<p>%1</p>' % {self comment});
        nl!

printVerilogOn: aStream
    |w|
    w := self width.
    self width == 1 
        ifTrue: [ 
            aStream nextPutAll: '    %1 %2;' 
                % {self direction asString. entityName}; nl]
        ifFalse: [ 
            aStream nextPutAll: '    %1 [%2:0] %3;' 
                % {self direction asString. w - 1. entityName}; nl]!
!

DANMPort subclass: #DANMSchematicPort
    instanceVariableNames: 'wire'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'DANM'!

DANMSchematicPort comment:
    'I represent a port of a schematic'!

!DANMSchematicPort class methodsFor: 'instance creation'!

newFromWire: w
    ^super new 
        wire: w; 
        name: w name!
!

!DANMSchematicPort methodsFor: 'accessing'!

wire
    ^wire!

wire: newWire
    wire := newWire!

basicWidth
    ^wire width!

direction
    wire isDrivenInternally ifTrue: [ ^#output ].
    wire isTriState ifTrue: [ ^#inout ].
    ^#input!
!
