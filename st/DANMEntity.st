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

Object subclass: #DANMEntity
       instanceVariableNames: 'attrs entityName tag'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'DANM'!

DANMEntity comment: 'I represent an entity, which has a name and a bunch of 
attributes'!

!DANMEntity methodsFor: 'accessing'!

name
    ^entityName!

verilogName
"name escaped with verilog convention. We need to do this for the flattened
name that can possibly contain '/'. "
    |vName|
    vName := entityName.
    (vName includes: $/) ifTrue: [ vName := '\', vName, ' ' ].
    ^vName!

comment
    (self hasAttribute: #COMMENT) ifTrue: [ ^self attribute: #COMMENT ].
    ^self class comment!

comment: str
    self setAttribute: #COMMENT to: str!

name: aName
    entityName := aName!

tag
    ^tag!

tag: t
    tag := t!

setAttribute: anAssociation
    attrs isNil ifTrue: [ attrs := IdentityDictionary new ].
    attrs add: anAssociation!

unsetAttribute: attrName
    attrs isNil ifTrue: [ ^self ].
    attrs removeKey: attrName ifAbsent: [nil]!
    
setAttribute: attrName to: attrValue
    attrs isNil ifTrue: [ attrs := IdentityDictionary new ].
    attrs at: attrName put: attrValue!

hasAttribute: attrName
    attrs isNil ifTrue: [ ^false ].
    ^attrs includesKey: attrName!

attribute: attrName
    attrs isNil ifTrue: [ ^nil ].
    ^attrs at: attrName ifAbsent: [nil]!

<= anotherEntity
    self class = anotherEntity class ifTrue: [
        ^ entityName <= anotherEntity name ].
    (self isKindOf: anotherEntity class) ifTrue: [ ^false ].
    (anotherEntity isKindOf: self class) ifTrue: [ ^true ].
    ^ self class printString <= anotherEntity class printString!
!

!DANMEntity class methodsFor: 'instance creation'!

newNamed: aName
    ^self new 
        name: aName!

castFrom: anotherEntity
    "construct an entity from an instance of one of its subclasses.
     all instance variable is copyed and old one becomes new one"
    |newEntity|
    (anotherEntity isKindOf: self) ifFalse: [
        self error: 'Can not cast from an unrelated entity' ].
    newEntity := self new.
    1 to: self instSize do: [ :i |
        newEntity instVarAt: i put: (anotherEntity instVarAt: i) ].
    ^anotherEntity become: newEntity!
!

!DANMEntity methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: ('%1(%2)' % {entityName. self class})!        
!
