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

ExpressionAST subclass: #ModeledExpression
    instanceVariableNames: 'references block width'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

ModeledExpression comment:
    'I am a ExpressionAST modeled withan arbitrary block closure'!

!ModeledExpression class methodsFor: 'instance creation'!

with: args do: b
    ^self new
        references: (args collect: [ :each | 
            ExpressionAST newFrom: each ]);
        block: b;
        width: 1!

with: args width: w do: b
    ^self new
        references: (args collect: [ :each | 
            ExpressionAST newFrom: each ]);
        block: b;
        width: w!
!

!ModeledExpression methodsFor: 'accessing'!

references: r
    references := r!

block: b
    block := b!

width: w
    width := w!

width
    ^width!

clearAlias
    super clearAlias.
    references do: [ :each | each clearAlias ]!

dependencies
    ^references inject: #() into: [ :list :each |
        list, each dependencies ]!
!

!ModeledExpression methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    references do: [ :each |
        each printAdditionalVerilogOn: aStream ]!

basicPrintStringStyle: style
    |aStream|
    aStream := WriteStream on: String new.
    aStream nextPutAll: 'Function('.
    references do: [ :each |
        aStream nextPutAll: '%1, ' % {each printStringStyle: style} ].
    aStream nextPut: $).
    ^aStream contents!
!

!ModeledExpression methodsFor: 'basic'!

checkDesign
    ^ references inject: (block argumentCount == references size) 
                 into: [ :r :each | r & each checkDesign ]!

context: c type: t
    references do: [ :each | each context: c type: t ]!

destroy
    references do: [ :each | each destroy ]!

evaluate
    ^ block valueWithArguments: (references collect: [ :each |
        each evaluate ])!

staticValue
    ^[ self evaluate ] ifError: [ nil ]!
!

