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

LineCountingStream subclass: Tokenizer [
    | docString marker |
    <comment: 'I am a stream tokenizer for c like languages; I recognize whitespace and 
c style comments'>
    <category: 'Streams-Files'>

    docString [
	<category: 'accessing'>
	docString isNil ifTrue: [^''].
	^docString
    ]

    clearDocString [
	<category: 'accessing'>
	docString := nil
    ]

    parseError: mesg [
	<category: 'basic'>
	| name |
	name := self name.
	name isNil ifTrue: [name := stream contents].
	self error: 'Parsing error at: %1:%2c%3, %4' % 
	    {name. self line. self column. mesg}
    ]

    expect: aToken [
	<category: 'basic'>
	self nextToken = aToken ifFalse: [
	    self pushBackLastToken.
	    self parseError: 'Expecting %1' % {aToken} ]
    ]

    expectKind: aClass [
	<category: 'basic'>
	| token |
	token := self nextToken.
	aClass = Integer & (token = $-) ifTrue: [
	    "special case, negative number"
	    token := self nextToken.
	    (token isKindOf: Integer) ifTrue: [token := 0 - token]].
	(token isKindOf: aClass) ifFalse: [
	    self parseError: 'Expecting %1, but get %2' % 
		{aClass. token} ].
	^token
    ]

    testNext: aToken [
	<category: 'basic'>
	self nextToken = aToken ifTrue: [^true].
	self pushBackLastToken.
	^false
    ]

    atEnd [
	<category: 'basic'>
	self skipToToken.
	^super atEnd
    ]

    nextToken [
	"return the next token. it could be a number, an identifier, an operator
	 or nil"
	<category: 'basic'>
	| c |
	self skipToToken.
	marker := self position.
	c := self peek.
	c isNil ifTrue: [^nil].
	c isLetter ifTrue: [^self nextIdentifier].
	c isDigit ifTrue: [^self nextNumber].
	^self next
    ]

    pushBackLastToken [
	"Push back the last token. stream pointer should not be updated from last
	 nextToken call"
	<category: 'basic'>
	marker isNil ifTrue: [self error: 'no token to push back'].
	self pushBack: self position - marker
    ]

    nextIdentifier [
	"return the next word"
	<category: 'basic'>
	| c s |
	s := WriteStream on: String new.
	
	[   c := self peek.
	    c notNil and: [ c = $_ | c isAlphaNumeric ]
	] whileTrue: [
	    s nextPut: self next ].
	^s contents
    ]

    nextNumber [
	"return the next word"
	<category: 'basic'>
	| c s |
	s := 0.
	[   c := self peek.
	    c notNil and: [c isDigit ]
	] whileTrue: [
	    c := self next.
	    s := s * 10 + c digitValue ].
	^s
    ]

    skipToToken [
	"skip whitespace and comment"
	<category: 'basic'>
	[self skipWhiteSpace.
	self skipComment] whileTrue
    ]

    skipWhiteSpace [
	"skip all white space at the begining"
	<category: 'basic'>
	| c |
	[   c := self peek.
	    c notNil and: [ c isSeparator ]
	] whileTrue: [ self next ].
	^self
    ]

    skipComment [
	"skip over comment or tick line, which is from verilog pre-processor"
	<category: 'basic'>
	| r |
	r := false.
	self peek = $/ ifTrue: [
	    r := self skipLineComment or: [self skipBlockComment ]].
	self peek = $` ifTrue: [
	    r := true.
	    [ self nextLine last = $\ ] whileTrue ].
	^r
    ]

    skipLineComment [
	"skip a line comment, return true if I did"
	<category: 'basic'>
	| str len |
	str := self peekAvailable: 2.
	len := str size.
	(len == 2 and: [str = '//']) ifTrue: [
	    self nextLine.
	    ^true ].
	^false
    ]

    skipBlockComment [
	"skip a block comment, return true if I did"
	<category: 'basic'>
	| str len shouldCapture ws |
	str := self peekAvailable: 2.
	len := str size.
	(len == 2 and: [str = '/*']) ifTrue: [
	    str := self next: 2.
	    (shouldCapture := self peek == $*) ifTrue: [
		self next.
		ws := WriteStream on: String new ].
	    "skip to */"
	    [   str := self peekAvailable: 2.
		len := str size.
		len == 2 and: [str ~= '*/']
	    ] whileTrue: [
		shouldCapture ifTrue: [ws nextPut: (str at: 1) ].
		self next ].
	    shouldCapture ifTrue: [docString := ws contents ].
	    self next: len.
	    ^true ].
	^false
    ]
]
