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

ExpressionAST subclass: ModeledExpression [
    | references block width |
    <comment: 'I am a ExpressionAST modeled withan arbitrary block closure'>
    <category: ''>

    ModeledExpression class >> with: args do: b [
	<category: 'instance creation'>
	^(self new)
	    references: (args collect: [:each | ExpressionAST newFrom: each]);
	    block: b;
	    width: 1
    ]

    ModeledExpression class >> with: args width: w do: b [
	<category: 'instance creation'>
	^(self new)
	    references: (args collect: [:each | ExpressionAST newFrom: each]);
	    block: b;
	    width: w
    ]

    references: r [
	<category: 'accessing'>
	references := r
    ]

    block: b [
	<category: 'accessing'>
	block := b
    ]

    width: w [
	<category: 'accessing'>
	width := w
    ]

    width [
	<category: 'accessing'>
	^width
    ]

    clearAlias [
	<category: 'accessing'>
	super clearAlias.
	references do: [:each | each clearAlias]
    ]

    dependencies [
	<category: 'accessing'>
	^references inject: #() into: [:list :each | list , each dependencies]
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	references do: [:each | each printAdditionalVerilogOn: aStream]
    ]

    basicPrintStringStyle: style [
	<category: 'printing'>
	| aStream |
	aStream := WriteStream on: String new.
	aStream nextPutAll: 'Function('.
	references do: [
	    :each | aStream nextPutAll: '%1, ' % {each printStringStyle: style} ].
	aStream nextPut: $).
	^aStream contents
    ]

    checkDesign [
	<category: 'basic'>
	^references inject: block argumentCount == references size into: [:r :each |
	    r & each checkDesign]
    ]

    context: c type: t [
	<category: 'basic'>
	references do: [:each | each context: c type: t]
    ]

    destroy [
	<category: 'basic'>
	references do: [:each | each destroy]
    ]

    evaluate [
	<category: 'basic'>
	^block valueWithArguments: (references collect: [:each | each evaluate])
    ]

    staticValue [
	<category: 'basic'>
	^[self evaluate] ifError: [nil]
    ]
]

