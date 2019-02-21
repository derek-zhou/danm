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

Object subclass: DANMEntity [
    | attrs entityName tag |
    <category: 'DANM'>
    <comment: 'I represent an entity, which has a name and a bunch of 
attributes'>

    DANMEntity class >> newNamed: aName [
	<category: 'instance creation'>
	^self new name: aName
    ]

    DANMEntity class >> castFrom: anotherEntity [
	"construct an entity from an instance of one of its subclasses.
	 all instance variable is copyed and old one becomes new one"
	<category: 'instance creation'>
	| newEntity |
	    (anotherEntity isKindOf: self) ifFalse: [
		self error: 'Can not cast from an unrelated entity' ].
	newEntity := self new.
	1 to: self instSize do: [:i |
	    newEntity instVarAt: i put: (anotherEntity instVarAt: i) ].
	^anotherEntity become: newEntity
    ]

    name [
	<category: 'accessing'>
	^entityName
    ]

    verilogName [
	"name escaped with verilog convention. We need to do this for the flattened
	 name that can possibly contain '/'."
	<category: 'accessing'>
	| vName |
	vName := entityName.
	(vName includes: $/) ifTrue: [vName := '\' , vName , ' '].
	^vName
    ]

    comment [
	<category: 'accessing'>
	(self hasAttribute: #COMMENT) ifTrue: [^self attribute: #COMMENT].
	^self class comment
    ]

    comment: str [
	<category: 'accessing'>
	self setAttribute: #COMMENT to: str
    ]

    name: aName [
	<category: 'accessing'>
	entityName := aName
    ]

    tag [
	<category: 'accessing'>
	^tag
    ]

    tag: t [
	<category: 'accessing'>
	tag := t
    ]

    setAttribute: anAssociation [
	<category: 'accessing'>
	attrs isNil ifTrue: [attrs := IdentityDictionary new].
	attrs add: anAssociation
    ]

    unsetAttribute: attrName [
	<category: 'accessing'>
	attrs isNil ifTrue: [^self].
	attrs removeKey: attrName ifAbsent: [nil]
    ]

    setAttribute: attrName to: attrValue [
	<category: 'accessing'>
	attrs isNil ifTrue: [attrs := IdentityDictionary new].
	attrs at: attrName put: attrValue
    ]

    hasAttribute: attrName [
	<category: 'accessing'>
	attrs isNil ifTrue: [^false].
	^attrs includesKey: attrName
    ]

    attribute: attrName [
	<category: 'accessing'>
	attrs isNil ifTrue: [^nil].
	^attrs at: attrName ifAbsent: [nil]
    ]

    <= anotherEntity [
	<category: 'accessing'>
	self class = anotherEntity class 
	    ifTrue: [^entityName <= anotherEntity name].
	(self isKindOf: anotherEntity class) ifTrue: [^false].
	(anotherEntity isKindOf: self class) ifTrue: [^true].
	^self class printString <= anotherEntity class printString
    ]

    printOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '%1(%2)' % {entityName. self class}
    ]
]

