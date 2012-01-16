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

ExpressionAST subclass: #ASTBinaryOp
              instanceVariableNames: 'left right'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTBinaryOp class methodsFor: 'instance creation'!

newOps: os among: ps
    |factor|
    ps size == (os size + 1) ifFalse: [
        self error: 'operators size must be one less than operand size' ].
    factor := ps at: 1.
    1 to: os size do: [ :i |
        factor := self newOp: (os at: i) between: factor 
                       and: (ps at: i + 1) ].
    ^factor!

newOp: op between: l and: r
    self subclassesDo: [ :each |
            each op = op ifTrue: [ ^each newBetween: l and: r ]]!

newBetween: l and: r
    ^super new
        left: l;
        right: r!
!

!ASTBinaryOp class methodsFor: 'accessing'!

hasValidOp: op
    self subclassesDo: [ :each | 
        each op = op ifTrue: [ ^true ]].
    ^false!

op
    self subclassResponsibility!
!

!ASTBinaryOp methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    left clearAlias.
    right clearAlias!

width 
    ^left width max: right width!

left
    ^left!

left: l
    left := l!

right
    ^right!

right: r
    right := r!

dependencies
    ^left dependencies, right dependencies!
!

!ASTBinaryOp methodsFor: 'basic'!

context: c type: t
    left context: c type: t.
    right context: c type: t!

checkDesign
    ^left checkDesign & right checkDesign!

destroy
    left destroy.
    right destroy!

optimize
    left := left optimize.
    right := right optimize.
    ^super optimize!
!

!ASTBinaryOp methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    left printAdditionalVerilogOn: aStream.
    right printAdditionalVerilogOn: aStream!

basicPrintStringStyle: style
    ^'(%1%2%3)' % {left printStringStyle: style . self class op. 
                   right printStringStyle: style}!
!

ASTBinaryOp subclass: #ASTPlusOp
              instanceVariableNames: 'mask'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTPlusOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    mask isNil ifTrue: [ 
        mask := (1 bitShift: (left width max: right width)) - 1 ].
    ^vl + vr bitAnd: mask!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ vl + vr  bitAnd: (1 bitShift: (left width max: right width)) - 1 ].
    ^nil!
!

!ASTPlusOp class methodsFor: 'accessing'!
op
    ^$+!
!

ASTBinaryOp subclass: #ASTMinusOp
              instanceVariableNames: 'shift'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTMinusOp methodsFor: 'basic'!

evaluate
    |vl vr v|
    vl := left evaluate.
    vr := right evaluate.
    v := vl - vr.
    shift isNil ifTrue: [ 
        shift := 1 bitShift: (left width max: right width) ].
    v < 0 ifTrue: [ v := v + shift ].
    ^ v!

staticValue
    |vl vr v|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        v := vl - vr.
        v < 0 ifTrue: [ v := v + (1 bitShift: (left width max: right width)) ].
        ^ v ].
    ^nil!
!

!ASTMinusOp class methodsFor: 'accessing'!
op
    ^$-!
!

ASTBinaryOp subclass: #ASTEqualOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTEqualOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl == vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [ 
        ^ (vl == vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTEqualOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTEqualOp class methodsFor: 'accessing'!
op
    ^'=='!
!

ASTBinaryOp subclass: #ASTNoLessThanOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTNoLessThanOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl >= vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr s|
    s := (1 bitShift: (left width max: right width)) - 1.
    vl := left staticValue.
    (vl notNil and: [vl == 0]) ifTrue: [ ^0 ].
    (vl notNil and: [vl == s]) ifTrue: [ ^1 ].
    vr := right staticValue.
    (vr notNil and: [vr == 0]) ifTrue: [ ^1 ].
    (vr notNil and: [vr == s]) ifTrue: [ ^0 ].
    vl notNil & vr notNil ifTrue: [
        ^ (vl >= vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTNoLessThanOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTNoLessThanOp class methodsFor: 'accessing'!
op
    ^'>='!
!

ASTBinaryOp subclass: #ASTNoGreaterThanOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTNoGreaterThanOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl <= vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr s|
    s := (1 bitShift: (left width max: right width)) - 1.
    vl := left staticValue.
    (vl notNil and: [vl == 0]) ifTrue: [ ^1 ].
    (vl notNil and: [vl == s]) ifTrue: [ ^0 ].
    vr := right staticValue.
    (vr notNil and: [vr == 0]) ifTrue: [ ^0 ].
    (vr notNil and: [vr == s]) ifTrue: [ ^1 ].
    vl notNil & vr notNil ifTrue: [
        ^ (vl <= vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTNoGreaterThanOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTNoGreaterThanOp class methodsFor: 'accessing'!
op
    ^'<='!
!

ASTBinaryOp subclass: #ASTUnequalOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTUnequalOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl ~= vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ (vl ~= vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTUnequalOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTUnequalOp class methodsFor: 'accessing'!
op
    ^'!='!
!

ASTBinaryOp subclass: #ASTLessThanOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTLessThanOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl < vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ (vl < vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTLessThanOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTLessThanOp class methodsFor: 'accessing'!
op
    ^$<!
!

ASTBinaryOp subclass: #ASTGreaterThanOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTGreaterThanOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (vl > vr ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ (vl > vr ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!
!

!ASTGreaterThanOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTGreaterThanOp class methodsFor: 'accessing'!
op
    ^$>!
!

ASTBinaryOp subclass: #ASTLogicalAndOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTLogicalAndOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ ((vl > 0) & (vr > 0) ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    (vl notNil and: [vl = 0]) ifTrue: [ ^ 0 ].
    vr := right staticValue.
    (vr notNil and: [vr = 0]) ifTrue: [ ^ 0 ].
    vl notNil & vr notNil ifTrue: [
        ^ ((vl > 0) & (vr > 0) ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!

optimize
    |vl vr|
    left := left optimize.
    right := right optimize.
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ ASTConstant newConstant: ((vl > 0) & (vr > 0) 
                                        ifTrue: [ 1 ] ifFalse: [ 0 ])
                      width: 1 ].
    vl notNil ifTrue: [
        ^ vl > 0 ifTrue: [ ASTUnaryOrOp newOn: right ]
                 ifFalse: [   
                     right destroy.
                     ASTConstant newConstant: 0 width: 1 ]].
    vr notNil ifTrue: [
        left destroy.
        ^ vr > 0 ifTrue: [ ASTUnaryOrOp newOn: left ]
                 ifFalse: [ 
                     left destroy.
                     ASTConstant newConstant: 0 width: 1 ]]!
!

!ASTLogicalAndOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTLogicalAndOp class methodsFor: 'accessing'!
op
    ^'&&'!
!

ASTBinaryOp subclass: #ASTLogicalOrOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTLogicalOrOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ ((vl > 0) | (vr > 0) ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    (vl notNil and: [vl > 0]) ifTrue: [ ^ 1 ].
    vr := right staticValue.
    (vr notNil and: [vr > 0]) ifTrue: [ ^ 1 ].
    vl notNil & vr notNil ifTrue: [
        ^ ((vl > 0) | (vr > 0) ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!

optimize
    |vl vr|
    left := left optimize.
    right := right optimize.
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ ASTConstant newConstant: ((vl > 0) | (vr > 0) 
                                        ifTrue: [ 1 ] ifFalse: [ 0 ])
                      width: 1 ].
    vl notNil ifTrue: [
        ^ vl > 0 ifFalse: [ ASTUnaryOrOp newOn: right ]
                 ifTrue: [ 
                     right destroy.
                     ASTConstant newConstant: 1 width: 1 ]].
    vr notNil ifTrue: [
        ^ vr > 0 ifFalse: [ ASTUnaryOrOp newOn: left ]
                 ifTrue: [ 
                     left destroy.
                     ASTConstant newConstant: 1 width: 1 ]]!
!

!ASTLogicalOrOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTLogicalOrOp class methodsFor: 'accessing'!
op
    ^'||'!
!

ASTBinaryOp subclass: #ASTLogicalXorOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTLogicalXorOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ (((vl > 0) xor: (vr > 0)) ifTrue: [ 1 ] ifFalse: [ 0 ])!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ (((vl > 0) xor: (vr > 0)) ifTrue: [ 1 ] ifFalse: [ 0 ]) ].
    ^nil!

optimize
    |vl vr r|
    left := left optimize.
    right := right optimize.
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ ASTConstant newConstant: (((vl > 0) xor: (vr > 0)) 
                                        ifTrue: [ 1 ] ifFalse: [ 0 ])
                      width: 1 ].
    vl notNil ifTrue: [
        r := ASTUnaryOrOp newOn: right.
        ^ vl > 0 ifFalse: [ r ]
                 ifTrue: [ ASTLogicalNotOp newOn: r ]].
    vr notNil ifTrue: [
        r := ASTUnaryOrOp newOn: left.
        ^ vr > 0 ifFalse: [ r ]
                 ifTrue: [ ASTLogicalNotOp newOn: r ]]!
!

!ASTLogicalXorOp methodsFor: 'accessing'!
width
    ^1!
!
!ASTLogicalXorOp class methodsFor: 'accessing'!
op
    ^'^^'!
!

ASTBinaryOp subclass: #ASTBitwiseAndOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTBitwiseAndOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ vl bitAnd: vr!

staticValue
    |vl vr|
    vl := left staticValue.
    (vl notNil and: [ vl = 0 ]) ifTrue: [ ^ 0 ].
    vr := right staticValue.
    (vr notNil and: [ vr = 0 ]) ifTrue: [ ^ 0 ].
    vl notNil & vr notNil ifTrue: [ ^(vl bitAnd: vr) ].
    ^nil!
!

!ASTBitwiseAndOp class methodsFor: 'accessing'!
op
    ^$&!
!

ASTBinaryOp subclass: #ASTBitwiseOrOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTBitwiseOrOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ vl bitOr: vr!

staticValue
    |vl vr s|
    s := (1 bitShift: (left width max: right width)) - 1.
    vl := left staticValue.
    (vl notNil and: [ vl = s ]) ifTrue: [ ^ s ].
    vr := right staticValue.
    (vr notNil and: [ vr = s ]) ifTrue: [ ^ s ].
    vl notNil & vr notNil ifTrue: [ ^(vl bitOr: vr) ].
    ^nil!
!

!ASTBitwiseOrOp class methodsFor: 'accessing'!
op
    ^$|!
!

ASTBinaryOp subclass: #ASTBitwiseXorOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTBitwiseXorOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    ^ vl bitXor: vr!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [ ^(vl bitXor: vr) ].
    ^nil!
!

!ASTBitwiseXorOp class methodsFor: 'accessing'!
op
    ^$^!
!

ASTBinaryOp subclass: #ASTCommaOp
              instanceVariableNames: 'rightWidth'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

!ASTCommaOp class methodsFor: 'accessing'!
op
    ^$,!
!

!ASTCommaOp methodsFor: 'basic'!

evaluate
    |vl vr|
    vl := left evaluate.
    vr := right evaluate.
    rightWidth isNil ifTrue: [ rightWidth := right width ].
    ^ (vl bitShift: rightWidth) + vr!

staticValue
    |vl vr|
    vl := left staticValue.
    vr := right staticValue.
    vl notNil & vr notNil ifTrue: [
        ^ (vl bitShift: right width) + vr ].
    ^nil!
!

!ASTCommaOp methodsFor: 'accessing'!
width
    ^left width + right width!
!

!ASTCommaOp methodsFor: 'printing'!
basicPrintStringStyle: style
    style == #VERILOG ifFalse: [ ^super basicPrintStringStyle: style ].
    ^'{%1%2%3}' % {left printStringStyle: style . self class op. 
                   right printStringStyle: style}!
!

ASTBinaryOp subclass: #ASTLatchOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTLatchOp comment:
    'I am a class to assist parsing of a latch, I am not really instanciated'!

!ASTLatchOp class methodsFor: 'accessing'!
op
    ^$@!
!

!ASTLatchOp class methodsFor: 'instance creation'!

new
    self shouldNotImplement!

newBetween: data and: clock
"I am instanciate an identifier instead, which point to a latch I made here"
    |name latch sch|
    sch := DANMCurrentDesign value.
    name := sch uniqueWireNameLike: 'latch'.
    latch := (DANMLatch newNamed: name inContext: sch)
        expression: data;
        clock: clock.
    ^ASTIdentifier basicNewIdentifier: latch!
!

ASTBinaryOp subclass: #ASTFlipflopOp
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTFlipflopOp comment:
    'I am a class to assist parsing of a flipflop, I am not really instanciated'!

!ASTFlipflopOp class methodsFor: 'accessing'!
op
    ^$$!
!

!ASTFlipflopOp class methodsFor: 'instance creation'!

new
    self shouldNotImplement!

newBetween: data and: clock
"I am instanciate an identifier instead, which point to a flop I made here"
    |name flop sch|
    sch := DANMCurrentDesign value.
    name := sch uniqueWireNameLike: 'flop'.
    flop := (DANMFlipflop newNamed: name inContext: sch)
        expression: data;
        clock: clock.
    ^ASTIdentifier basicNewIdentifier: flop!
!
