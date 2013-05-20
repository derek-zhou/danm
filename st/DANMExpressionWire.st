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

DANMWire subclass: #DANMExpressionWire
         instanceVariableNames: 'nextValue expression evOrder mask dirty'
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMExpressionWire comment: 'I am a wire with a expression of other wires. 
All connection on me should be loads; I am self-driven.'!

!DANMExpressionWire class methodsFor: 'instance creation'!

new
    ^super new setDirty!
!

!DANMExpressionWire methodsFor: 'accessing'!

expression 
    ^expression!

expression: newExpr
    expression == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #DIRECT ].
    expression := newExpr!

directFanins
    ^expression dependencies!
    
dependencies
    ^self directFanins!
    
evaluationOrder
    evOrder isNil ifTrue: [
        "avoid recursion"
        evOrder := 0.
        evOrder := self basicEvaluationOrder ].
    ^evOrder!

clearDerivedData
"some data is derived from more fundimental data; the derived ones are 
 kept mainly for performance reason. However, sometimes there is a need 
 to clear all that because structural change that make them stale"
    super clearDerivedData.
    self setDirty.
    evOrder := nil.
    nextValue := nil!

basicEvaluationOrder
    ^ 1+ (self dependencies uniquify inject: -1 into: [ :m :id | 
        m max: id evaluationOrder ])!

currentValue
    ^value!

nextValue
    nextValue isNil ifTrue: [ ^value ].
    ^nextValue!

nextValue: v
    mask isNil ifTrue: [ mask := (1 bitShift: self width) - 1 ].
    v notNil ifTrue: [ nextValue := v bitAnd: mask ]!

"If expression exists, evaluate it in the context. otherwise, use value from
 super class"
minWidth
    expression isNil ifTrue: [ ^super minWidth ].
    ^expression width!

isDrivenInternally
"expression wire is always driven"
    ^true!

driverCount
    ^super driverCount + 1!

isDirty
    "I am dirty when some of my dependencied changed. 0: clean 1: dirty"
    ^(dirty==1)!

setDirty
    "set to be dirty."
    dirty := 1!

resetDirty
    "set to be clean"
    dirty := 0!

printBinaryValueOn: fs
    |num cut|
    num := value.
    cut := mask+1.
    myWidth timesRepeat: [
        cut := cut/2.
        num >= cut 
            ifTrue: [
                fs nextPut: $1.
                num := num - cut ]
            ifFalse: [
                fs nextPut: $0 ]]!
!

!DANMExpressionWire methodsFor: 'basic'!

evaluate
    "evaluate self, set nextValue and return it if I am changing. otherwise
     return nil"
    ASTIdentifier useNextValue: true.
    self nextValue: expression evaluate.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

staticValue
    "evaluate self statically, set nextValue and return it if I am changing. 
     otherwise return nil"
    ASTIdentifier useNextValue: true.
    self nextValue: expression staticValue.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

flip
    value := nextValue!

optimize
    |e|
    e := expression optimize.
    e isNil ifTrue: [ 
        self destroy.
        ^nil ].
    (e isKindOf: ASTConstant) ifTrue: [ 
        self value: e evaluate ].  
    self expression: e!

destroy
    expression destroy.
    super destroy!

faninTreeInject: value into: block
    "treverse the fanin tree and call block for each. Block is a 2 input block,
     first one argument is the result of previous invocation and second is 
     myself"
    |result|
    result := value.
    self directFanins do: [ :each |
        each isSequential ifFalse: [ 
            result := each faninTreeInject: result into: block ].
        result := block value: result value: each ].
    ^result!

realUsage: lower
    "return 1 if the wire is only driven/loaded in lower. 2 if only 
     driven/loaded in higher. 3 both, 0 neither. Expression is always used
     in its current context"
    |result|
    result := super realUsage: lower.
    self context == lower 
        ifTrue:  [ result := result bitOr: 1 ]
        ifFalse: [ result := result bitOr: 2 ].
    ^result!

defaultTo: d
    ^(DANMDefaultWire newReplacementNamed: entityName 
                      inContext: self context) 
        expression: expression;
        default: d!
!

!DANMExpressionWire methodsFor: 'printing'!

nodeStyle
    ^'[shape=ellipse]'!

printOn: aStream
    aStream nextPutAll: ('(%1) ' % {expression})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">Expression wire %1</a></h3><ul><li>width is %2.</li>' 
                         % {entityName. self width});
        nl;
        nextPutAll: '<li>expression: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl!

printVerilogRegsOn: aStream
    |w|
    w := self width.
    w == 1 
        ifTrue: [  aStream nextPutAll: '    reg %1;' % {self verilogName}; nl]
        ifFalse: [ aStream nextPutAll: '    reg [%1:0] %2;' 
                       % {w - 1. self verilogName}; nl]!

basicPrintVerilogOn: aStream
    expression alias: (self verilogName).
    expression printAdditionalVerilogOn: aStream.
    expression printVerilogOn: aStream.
    expression clearAlias!
!

!DANMExpressionWire class methodsFor: 'verilog printing'!

printDependencies: deps on: aStream
    |first|
    first := true.
    aStream nextPutAll: '    always @('.
    deps asSortedCollection do: [ :each |
        (each isKindOf: DANMMacro) ifFalse: [ 
            first ifFalse: [ aStream nextPutAll: ' or ' ].
            aStream nextPutAll: each verilogName.
            first := false ]].
    aStream 
        nextPutAll: ')'; nl!
!

DANMExpressionWire subclass: #DANMMacro
         instanceVariableNames: ''
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMMacro comment: 'I am a macro, the only difference is I do not 
print myself and directly dereference to the expression in printing. The 
expression need to be inline printable though'!

!DANMMacro methodsFor: 'printing'!

basicPrintVerilogOn: aStream
    ^self!

verilogName
    ^expression basicPrintStringStyle: #VERILOG!
!

DANMExpressionWire subclass: #DANMDefaultWire
         instanceVariableNames: 'default'
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMDefaultWire comment: 'I am a wire with 2 expressions, if the main expression 
evaluate to nil I default to the default expression which cannot be nil'

!DANMDefaultWire methodsFor: 'accessing'!

default 
    ^default!

default: newExpr
    default == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #DIRECT ].
    default := newExpr!

directFanins
    ^default dependencies, expression dependencies!
!

!DANMDefaultWire methodsFor: 'basic'!

evaluate
    "evaluate self, set nextValue and return it if I am changing. otherwise
     return nil"
    |v|
    ASTIdentifier useNextValue: true.
    v := expression evaluate.
    v isNil ifTrue: [ v := default evaluate ].
    self nextValue: v.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

staticValue
    "evaluate self statically, set nextValue and return it if I am changing. 
     otherwise return nil"
    |v|
    ASTIdentifier useNextValue: true.
    v := expression staticValue.
    v isNil ifTrue: [ v := default staticValue ].
    self nextValue: v.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

destroy
    default destroy.
    super destroy!
!

!DANMDefaultWire methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: ('(%1|%2) ' % {expression. default})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">Expression wire %1</a></h3><ul><li>width is %2.</li>' 
                         % {entityName. self width});
        nl;
        nextPutAll: '<li>expression: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl;
        nextPutAll: '<li>default to: %1</li>' % 
            {default printStringStyle: #HTML};
        nl!

basicPrintVerilogOn: aStream
    default alias: (self verilogName).
    expression alias: (self verilogName).
    expression printAdditionalVerilogOn: aStream.
    default printAdditionalVerilogOn: aStream.
    self printVerilogRegsOn: aStream.
    DANMExpressionWire printDependencies: self dependencies uniquify on: aStream.
    aStream nextPutAll: '    begin'; nl.
    default printCoreVerilogOn: aStream indent: 8 blocking: true.
    expression printCoreVerilogOn: aStream indent: 8 blocking: true.
    default clearAlias.
    expression clearAlias.
    aStream nextPutAll: '    end'; nl!
!
