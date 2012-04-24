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

Object subclass: #ExpressionAST
       instanceVariableNames: 'alias'
       classVariableNames: ''
       poolDictionaries: ''
       category: 'expression AST'!

ExpressionAST comment: 
    'I am a abstract class that describe a node in AST'!

!ExpressionAST class methodsFor: 'instance creation'!

"either return e if it is already an expression or parse it as it was a string"
newFrom: e
    e isNil ifTrue: [ ^ASTDefault new ].
    (e isKindOf: ExpressionAST) ifTrue: [ ^ e ].
    (e isKindOf: DANMWire) ifTrue: [ ^ASTIdentifier basicNewIdentifier: e ].
    (e isKindOf: Array) ifTrue: [ ^ ASTIfsOp newIfs: e ].
    ^ (ExpressionParser newFromString: (
        (e isKindOf: String) ifTrue: [ e ] ifFalse: [ e printString ])) 
        parse!
!

!ExpressionAST methodsFor: 'accessing'!

alias
"An alias is a name used in verilog generation. It is usually the wire name 
if the expression is a wire directly, or a temporary name to denote the sub
expression"
    ^alias!

alias: a
    alias := a!

clearAlias
    alias := nil!

dependencies
    ^#()!

isCombinatorial
"return whether the expression is fully dependent on all dependencies"
    ^true!

genAliasLike: str
    "genaerate an unique alias, unless i am an identifier already"
    (self isKindOf: ASTIdentifier) | (alias notNil) ifTrue: [ ^false ].
    alias := ASTIdentifier uniqueIdentifierLike: str.
    ASTIdentifier addIdentifier: alias with: #DUMMY.
    ^true!

width
    self subclassResponsibility!
!

!ExpressionAST methodsFor: 'basic'!

evaluate
    "evaluate self and return the value. if nil then I am not changing."
    ^self subclassResponsibility!

staticValue
    "If self evaluate to a static value, return it. Otherwise nil"
    ^self evaluate!

context: c type: t
    ^self!
    
checkDesign 
    ^true!

destroy
    ^self!

optimize
    "optimize myself, and return another (simpler) expression if possible, or
     self if no optimization can be found. Also if the result is not myself
     the caller is responsible to discard any reference to myself and update
     reference to use the returned result instead"
    |v w|
    v := self staticValue.
    v notNil ifTrue: [
        w := self width.
        self destroy.
        ^ASTConstant newConstant: v width: w ].
    ^self!
!

!ExpressionAST methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
"This method print all prerequsite verilog code. It is usually overidden by 
the composite expression AST subclasses to recurse down"
    ^self!

printVerilogOn: aStream withAlias: str
"This method assign an unique alias to the expression and print it when 
necessary. It is used to break out sub expressions that need to be given a 
name"
    (self genAliasLike: str) 
        ifTrue: [ self printVerilogOn: aStream ]!

printVerilogRegsOn: aStream
    |w|
    w := self width.
    "unknown width default to 32"
    w == 0 ifTrue: [ w := 32 ].
    w == 1 
        ifTrue: [  aStream nextPutAll: '    reg %1;' % {alias}; nl]
        ifFalse: [ aStream nextPutAll: '    reg [%1:0] %2;' 
                       % {w - 1. alias}; nl]!

printVerilogOn: aStream
"This method print myself in verilog. The inline style is defined here; 
for complicated expression where inline style is not appropriate, you need to
override this method"
    |w|
    w := self width.
    "unknown width default to 32"
    w == 0 ifTrue: [ w := 32 ].
    w == 1 
        ifTrue: [  aStream nextPutAll: '    wire ' ]
        ifFalse: [ aStream nextPutAll: '    wire [%1:0] ' % {w - 1} ].
    self printCoreVerilogOn: aStream indent: 0 blocking: true!

printCoreVerilogOn: aStream indent: num blocking: blocking
    ^self printCoreVerilogOn: aStream indent: num 
          blocking: blocking wrapping: false!

printCoreVerilogOn: aStream indent: num blocking: blocking wrapping: wrapping
    |assign|
    assign := blocking ifTrue: [ '=' ] ifFalse: [ '<=' ].
    aStream 
        next: num put: $ ;
        nextPutAll: '%1 %2 %3;' % 
            {alias. assign. self basicPrintStringStyle: #VERILOG}; 
        nl!

printOn: aStream
    aStream nextPutAll: (self basicPrintStringStyle: #NONE)!

printStringStyle: style
"three styles are supported: #NONE, which is the plain version, #HTML, 
which is plain verisn with hyper link, or #VERILOG. This method is not to be
overridden, please override basicPrintStringStyle: The implementation only
do alias substitution here; it that fails I will call the basic mathod. So 
for verilog printing of a expression, you should call:
* alias for l-value
* basicPrintStringStyle: #VERILOG for top level r-value
* printStringStyle: #VERILOG for sub-expressions"
    (style == #VERILOG) & alias notNil ifTrue: [ ^alias ].
    ^self basicPrintStringStyle: style!

basicPrintStringStyle: style
"three styles are supported: #NONE, which is the plain version, #HTML, 
which is plain verisn with hyper link, or #VERILOG. To recurse down into 
subexpressions please call printStringStyle: so alias substitution will work"
    ^self class printString!
!

ExpressionAST subclass: #ASTConstant
              instanceVariableNames: 'width value'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTConstant comment:
    'I am AST node that contains an unsigned value with width'!

!ASTConstant class methodsFor: 'instance creation'!

newConstant: v
    ^super new
        width: 0;
        value: v!

newConstant: v width: w
    ^super new
        width: w;
        value: (w == 0 ifTrue: [ v ] 
                       ifFalse: [ v bitAnd: (1 bitShift: w) - 1] )!
!

!ASTConstant methodsFor: 'accessing'!

evaluate
    ^value!

optimize
    ^self!

value: v
    value := v!

checkDesign
    ^ value >= 0!

width
    ^width!

width: w
    width := w!
!

!ASTConstant methodsFor: 'printing'!

basicPrintStringStyle: style
    width == 0 ifTrue: [ ^value printString ].
    ^'%1''d%2' % {width. value}!
!

ExpressionAST subclass: #ASTDefault
              instanceVariableNames: ''
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTDefault comment:
    'I am AST node that represent default in a case'!

!ASTDefault methodsFor: 'printing'!

evaluate
    ^nil!

basicPrintStringStyle: style
    ^'default'!
!

ExpressionAST subclass: #ASTDuplicator
              instanceVariableNames: 'subject size subjectWidth'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTDuplicator comment: 
    'I am either a duplicator like a*3'!

!ASTDuplicator class methodsFor: 'instance creation'!

newDuplicatorOn: s by: n
    ^super new
        subject: s;
        size: n!
!

!ASTDuplicator methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    subject clearAlias!

width
    ^(subject width)*size!

subject
    ^subject!

subject: s
    subject := s!

size
    ^size!

size: n
    size := n!

dependencies
    ^subject dependencies!
!

!ASTDuplicator methodsFor: 'basic'!

context: c type: t
    subject context: c type: t!

checkDesign
    ^ subject checkDesign & (size >= 0)!

destroy
    subject destroy!

evaluate
    |v vr|
    vr := subject evaluate.
    v := 0.
    subjectWidth isNil ifTrue: [ subjectWidth := subject width ].
    size timesRepeat: [ v := (v bitShift: subjectWidth) + vr ].
    ^ v!
    
staticValue
    |vr v|
    vr := subject staticValue.
    vr notNil ifTrue: [
        v := 0.
        size timesRepeat: [ v := (v bitShift: subject width) + vr ].
        ^ v ].
    ^nil!
!

!ASTDuplicator methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    subject printAdditionalVerilogOn: aStream!

basicPrintStringStyle: style
    |aStream|
    aStream := WriteStream on: String new.
    style == #VERILOG 
        ifTrue: [ 
            aStream nextPutAll: '{%1{%2}}' % 
                {size. subject printStringStyle: style} ]
        ifFalse: [ 
            aStream nextPutAll: '(%1*%2)' % 
                {subject printStringStyle: style. size} ].
    ^aStream contents!
!

ExpressionAST subclass: #ASTExtractor
              instanceVariableNames: 'subject msb lsb step'
              classVariableNames: ''
              poolDictionaries: ''
              category: 'expression AST'!

ASTExtractor comment: 
    'I am a extractor like a[3:0:-2], which is {a[3], a[1]}'!

!ASTExtractor class methodsFor: 'instance creation'!

newExtractorOn: s from: m to: l step: st
    |step|
    m == l ifTrue: [ step := -1 ].
    m > l ifTrue: [ step := 0 - st ].
    step == -1 ifTrue: [
        ^ ASTSimpleExtractor new
            subject: s;
            msb: m;
            lsb: l;
            step: -1 ].
    ^super new
        subject: s;
        msb: m;
        lsb: l;
        step: step!
!

!ASTExtractor methodsFor: 'accessing'!

clearAlias
    super clearAlias.
    subject clearAlias!

width
    ^(lsb - msb) //step + 1!

subject
    ^subject!

subject: s
    subject := s!

msb
    ^msb!

msb: n
    msb := n!

lsb
    ^lsb!

lsb: n
    lsb := n!

step
    ^step!

step: st
    step:= st!

dependencies
    ^subject dependencies!
!

!ASTExtractor methodsFor: 'basic'!

context: c type: t
    subject context: c type: t!

checkDesign
    subject checkDesign ifFalse: [ ^false ].
    step > 0 ifTrue: [ ^ (msb >= 0) & (lsb >= msb) & (lsb < subject width) ].
    step < 0 ifTrue: [ ^ (lsb >= 0) & (msb >= lsb) & (msb < subJect width) ].
    ^false!

destroy
    subject destroy!

evaluateWith: v
    |r|
    r := 0.
    msb to: lsb by: step do: [ :i |
        r := r * 2 + (v bitAt: i + 1) ].
    ^r!
    
evaluate
    ^self evaluateWith: subject evaluate!

staticValue
    |v|
    v := subject staticValue.
    v notNil ifTrue: [ ^ self evaluateWith: v ].
    ^nil!
!

!ASTExtractor methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
"for example, in (a&b)[3:0] (a&b) part need to be promoted to a wire itself"
    subject printAdditionalVerilogOn: aStream.
    subject printVerilogOn: aStream withAlias: 'Expr'!

basicPrintStringStyle: style
    |aStream|
    style == #VERILOG ifFalse: [ 
        ^'%1[%2:%3:%4]' % 
            {subject printStringStyle: style. msb. lsb. step abs}].
    subject width == 1 ifTrue: [ ^subject printStringStyle: style ].
    aStream := WriteStream on: String new.
    aStream nextPut: ${.
    msb to: lsb by: step do: [ :i |
        i == msb ifFalse: [ aStream nextPutAll: ', ' ]. 
        aStream nextPutAll: '%1[%2]' %{subject printStringStyle: style. i} ].
    aStream nextPut: $}.
    ^aStream contents!
!

ASTExtractor subclass: #ASTSimpleExtractor
             instanceVariableNames: 'lsbShift mask'
             classVariableNames: ''
             poolDictionaries: ''
             category: 'expression AST'!

ASTSimpleExtractor comment: 
    'I am a simple extractor like a[3:0]'!

!ASTSimpleExtractor methodsFor: 'basic'!

evaluate
    |v|
    v := subject evaluate.
    lsbShift isNil ifTrue: [
        lsbShift := 1 bitShift: lsb.
        mask := (1 bitShift: msb - lsb + 1) - 1 ].
    ^v // lsbShift bitAnd: mask!

staticValue
    |v|
    v := subject staticValue.
    v notNil ifTrue: [
        ^ v // (1 bitShift: lsb) bitAnd: (1 bitShift: msb - lsb + 1) - 1 ].
    ^nil!
!

!ASTSimpleExtractor methodsFor: 'printing'!

basicPrintStringStyle: style
    subject width == 1 ifTrue: [ ^subject printStringStyle: style ].
    msb ~= lsb 
        ifTrue: [^'%1[%2:%3]' % {subject printStringStyle: style. msb. lsb}]
        ifFalse: [^'%1[%2]' % {subject printStringStyle: style. msb}]!
!

DynamicVariable subclass: #CurrentIdentifierDirectory
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

CurrentIdentifierDirectory comment:
    ''!

ExpressionAST subclass: #ASTIdentifier
    instanceVariableNames: 'identifier context type'
    classVariableNames: 'useNextValue'
    poolDictionaries: ''
    category: 'expression AST'!

ASTIdentifier comment:
    'I am a identifier node in an AST'!

!ASTIdentifier class methodsFor: 'accessing'!

uniqueIdentifierLike: str
    ^CurrentIdentifierDirectory value uniqueKeyLike: str!

addIdentifier: i with: v
    CurrentIdentifierDirectory value at: i put: v!

useNextValue: u
    useNextValue := u!

initialize
    self useNextValue: false!
!

ASTIdentifier initialize!

!ASTIdentifier class methodsFor: 'instance creation'!

newIdentifier: id
    |value sch|
    sch := DANMCurrentDesign value.
    value := sch wires at: id ifAbsent: [ nil ].
    value isNil ifTrue: [
        value := DANMWire newNamed: id inContext: sch ].
    ^ self basicNewIdentifier: value!

basicNewIdentifier: v
    |id|
    id := super new identifier: v.
    v addRef: id.
    ^id!

!ASTIdentifier methodsFor: 'accessing'!

width
    ^identifier fastWidth!

identifier
    ^identifier!

identifier: id
    identifier := id!

dependencies
    ^{self identifier}!

context
    "context is the wire that contains this expression. say A = b; then 
     the identifier that points to B has context of A"
    ^context!

context: c type: t
    context := c.
    type := t!

type
    "There are 4 types of identifier: #CLOCK, which is used in an expression 
     for clock of a flop or latch; #DATA, which is used in an expression for 
     data of a flop, #LATCHDATA, which is used in the data of a latch, or 
     #DIRECT, which is used in an combinatorial expression"
    ^type!
!

!ASTIdentifier methodsFor: 'basic'!

destroy
    identifier removeRef: self!

evaluate
    useNextValue 
        ifTrue: [ ^identifier nextValue ]
        ifFalse: [ ^identifier currentValue ]! 
!

!ASTIdentifier methodsFor: 'printing'!

printAdditionalVerilogOn: aStream
    "print the wire that identifier points to"
    identifier printAdditionalVerilogOn: aStream!

basicPrintStringStyle: style
    style == #HTML ifTrue: [ ^'<a href="#WIRE_%1">%1</a>' % 
                                 {self identifier name} ].
    style == #VERILOG ifTrue: [ ^identifier verilogName ].
    ^identifier name!
!
