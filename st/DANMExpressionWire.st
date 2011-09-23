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
    ^expression dependencies!
    
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


DANMExpressionWire subclass: #DANMFlipflop
         instanceVariableNames: 'clock'
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMFlipflop comment: 'I am a wire with a expression of other wires, with 
a flop at the end.'!

!DANMFlipflop methodsFor: 'accessing'!

isSequential
    ^true!

expression: newExpr
    expression == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #DATA ].
    expression := newExpr!

clock: newExpr
    clock == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #CLOCK ].
    clock := newExpr!

directFanins
    ^clock dependencies, expression dependencies!
    
dependencies
    ^clock dependencies!

isDirty
    "I am dirty when expression is dirty and clock is rising.
     0: clean 1: expression dirty but clock not rising yet. 2: expression
     dirty and clock is rising"
    ^(dirty>=2)!

setDirty
    dirty := 2!

setDataDirty
    "set expression to be dirty."
    dirty == 0 ifTrue: [ dirty := 1 ]!

setClockDirty
    "set clock is rising."
    dirty == 1 ifTrue: [ dirty := 2 ]!

resetDirty
    "set to clean."
    dirty := 0!
!

!DANMFlipflop methodsFor: 'basic'!

evaluate
    "evaluate self, set nextValue and return it if I am changing. otherwise
     return nil. The clock is ignored here because this method is invoked
     only when clock has a rise edge"
    ASTIdentifier useNextValue: false.
    self nextValue: expression evaluate.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

staticValue
    ASTIdentifier useNextValue: false.
    nextValue isNil ifTrue: [
        self nextValue: expression staticValue ].
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

optimize
    |e|
    e := expression optimize.
    (e isKindOf: ASTConstant) ifTrue: [
        clock destroy.
        ^(DANMExpressionWire newReplacementNamed: entityName 
                            inContext: self context) 
            expression: e; 
            value: e evaluate ]!

resetBy: reset to: resetTo
    ^(DANMResetFlop newReplacementNamed: entityName 
                    inContext: self context) 
        expression: expression;
        clock: clock;
        reset: reset;
        resetTo: resetTo!
    
destroy
    clock destroy.
    super destroy!

checkDesign
    clock isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: flop %2 has no clock'
            % {context name. entityName}; nl.
        ^false ].
    clock width ~=1 ifTrue: [ 
        Transcript nextPutAll: 'Check design error in %1: flop %2 clock is not single bit'
            % {context name. entityName}; nl.
        ^false ].
    (clock isKindOf: ASTIdentifier) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: flop %2 clock is not a wire'
            % {context name. entityName}; nl.
        ^false ].
    ^super checkDesign!
!

!DANMFlipflop methodsFor: 'printing'!

nodeStyle
    ^'[shape=box,peripheries=2]'!

printOn: aStream
    aStream nextPutAll: ('(%1)$(%2) ' % {expression. clock})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">Flipflop %1</a></h3><ul><li>width is %2.</li>' 
                         % {entityName. self width});
        nl;
        nextPutAll: '<li>clocked by: %1</li>' % 
            {clock printStringStyle: #HTML};
        nextPutAll: '<li>data: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    clock printAdditionalVerilogOn: aStream.
    clock printVerilogOn: aStream withAlias: 'Clock'.
    expression printAdditionalVerilogOn: aStream!

printBlockVerilogOn: aStream
    |w name|
    name := self verilogName.
    aStream nl.
    aStream 
        nextPutAll: '    always @(posedge %1)' 
            % {clock printStringStyle: #VERILOG}; 
        nl.
    expression alias: name.
    expression printCoreVerilogOn: aStream indent: 8 blocking: false.
    clock clearAlias.
    expression clearAlias!
!

DANMFlipflop subclass: #DANMLatch
         instanceVariableNames: ''
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMLatch comment: 'I am a wire with a expression of other wires, with 
a d-latch at the end.'!

!DANMLatch methodsFor: 'accessing'!

expression: newExpr
    expression == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #LATCHDATA ].
    expression := newExpr!

dependencies
    ^clock dependencies, expression dependencies!

isDirty
    "I am dirty when expression is dirty.
     0: clean 1: expression dirty but clock not rising yet. 2: expression
     dirty and clock is rising"
    ^(dirty>=1)!

resetDirty
    "from state 2 I go back to clean. However, state 1 is not reset because
     I could be still be dirty because I may be blocked by the clock"
    dirty isNil | (dirty == 2) ifTrue: [ dirty == 0 ]!
!

!DANMLatch methodsFor: 'basic'!

evaluate
    "evaluate self, set nextValue and return it if I am changing. otherwise
     return nil."
    ASTIdentifier useNextValue: true.
    clock evaluate > 0 ifTrue: [
        self nextValue: expression evaluate.
        nextValue ~= value ifTrue: [ ^nextValue ]].
    ^nil!

staticValue
    "evaluate self statically, set nextValue and return it if I am changing. 
     otherwise return nil"
    ASTIdentifier useNextValue: true.
    nextValue isNil ifTrue: [
        self nextValue: expression staticValue ].
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

optimize
    |e|
    e := expression optimize.
    (e isKindOf: ASTConstant) ifTrue: [
        clock destroy.
        ^(DANMExpressionWire newReplacementNamed: entityName 
                            inContext: self context) 
            expression: e; 
            value: e evaluate ]!
!

!DANMLatch methodsFor: 'printing'!

nodeStyle
    ^'[shape=box]'!

printOn: aStream
    aStream nextPutAll: ('(%1)@(%2) ' % {expression. clock})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">Latch %1</a></h3><ul><li>width is %2.</li>' 
                         % {entityName. self width});
        nl;
        nextPutAll: '<li>clocked by: %1</li>' % 
            {clock printStringStyle: #HTML};
        nextPutAll: '<li>data: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    clock printAdditionalVerilogOn: aStream.
    expression printAdditionalVerilogOn: aStream!

printBlockVerilogOn: aStream
    |name|
    name := self verilogName.
    aStream nl.
    DANMExpressionWire printDependencies: self dependencies uniquify on: aStream.
    aStream
        nextPutAll: '        if (%1)' % {clock printStringStyle: #VERILOG};
        nl.
    expression alias: name.
    expression printCoreVerilogOn: aStream indent: 12 blocking: false.
    clock clearAlias.
    expression clearAlias!
!

DANMFlipflop subclass: #DANMResetFlop
         instanceVariableNames: 'reset resetTo'
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMResetFlop comment: 'I am a flop with an asynchronous reset'!

!DANMResetFlop methodsFor: 'accessing'!

reset: newExpr
    reset == newExpr ifTrue: [ ^self ].
    newExpr notNil ifTrue: [ newExpr context: self type: #DIRECT ].
    reset := newExpr!

resetTo: newExpr
    reset == newExpr ifTrue: [ ^self ].
    resetTo := newExpr!

dependencies
    ^clock dependencies, reset dependencies!
!

!DANMResetFlop methodsFor: 'basic'!

resetDirty
    "set to be clean."
    dirty := (dirty == 3) ifTrue: [ 1 ] ifFalse: [0] !

setDirty
    "I am dirty when expression is dirty and clock is rising, or reset is 
     changing. 0: clean 1: expression dirty but clock not rising yet. 
     2: expression dirty and clock is rising, 3 reset changed"
    dirty := 3!

minWidth
    expression isNil ifTrue: [ ^super minWidth ].
    expression width > 0 ifTrue: [ ^expression width].
    resetTo isNil ifTrue: [ ^super minWidth ].
    ^resetTo width!

evaluate
    "evaluate self, set nextValue and return it if I am changing. otherwise
     return nil."
    ASTIdentifier useNextValue: true.
    "reset condition"
    reset evaluate == 0 ifTrue: [ 
        Transcript nextPutAll: 'reset %1' % {reset}; nl.
        self nextValue: resetTo evaluate.
        nextValue ~= value ifTrue: [ ^nextValue ] ifFalse: [ ^nil ]].
    "no reset, so it is just like a regular flop"
    (dirty ~= 3) ifTrue: [ ^super evaluate ].
    "reset deasserted. no-op, but clock edge aligned here is eaten"
    ^nil!

staticValue
    ASTIdentifier useNextValue: true.
    reset staticValue == 0 ifTrue: [ 
        nextValue isNil ifTrue: [
            self nextValue: resetTo staticValue ].
        nextValue ~= value ifTrue: [ ^nextValue ] ifFalse: [ ^nil ]].
    ^super staticValue!

optimize
    |e|
    e := reset optimize.
    (e isKindOf: ASTConstant) ifTrue: [
        e evaluate ~~ 0 
            ifTrue: [
                e destroy.
                resetTo destroy.
                ^(DANMFlipflop newReplacementNamed: entityName 
                               inContext: self context) 
                    expression: expression;
                    clock: clock;
                    optimize ]
            ifFalse: [
                clock destroy.
                expression destroy.
                ^(DANMExpressionWire newReplacementNamed: entityName 
                               inContext: self context) 
                    expression: resetTo;
                    optimize ]]!

destroy
    reset destroy.
    resetTo destroy.
    super destroy!

checkDesign
    Transcript nextPutAll: 'Check design warning in %1: inferring reset flop %2'
        % {context name. entityName}; nl.
    reset isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: reset flop %2 has no reset'
            % {context name. entityName}; nl.
        ^false ].
    reset width ~=1 ifTrue: [ 
        Transcript nextPutAll: 'Check design error in %1: flop %2 reset is not single bit'
            % {context name. entityName}; nl.
        ^false ].
    (reset isKindOf: ASTIdentifier) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: reset flop %2 reset is not a wire'
            % {context name. entityName}; nl.
        ^false ].
    (resetTo isKindOf: ASTConstant) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: reset value of %2 has to be a constant, got %3'
            % {context name. entityName. resetTo}; nl.
        ^false ].
    ^super checkDesign!
!

!DANMResetFlop methodsFor: 'printing'!

nodeStyle
    ^'[shape=box,peripheries=3]'!

printOn: aStream
    aStream nextPutAll: ('(%1)$(%2)_(%3)->(%4) ' % {expression. clock. reset. resetTo})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">ResetFlop %1</a></h3><ul><li>width is %2.</li>' 
                         % {entityName. self width});
        nl;
        nextPutAll: '<li>clocked by: %1</li>' % 
            {clock printStringStyle: #HTML};
        nextPutAll: '<li>resetted by: %1</li>' % 
            {reset printStringStyle: #HTML};
        nextPutAll: '<li>resetted to: %1</li>' % 
            {resetTo printStringStyle: #HTML};
        nextPutAll: '<li>data: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    clock printAdditionalVerilogOn: aStream.
    clock printVerilogOn: aStream withAlias: 'Clock'.
    reset printAdditionalVerilogOn: aStream.
    reset printVerilogOn: aStream withAlias: 'Reset'.
    expression printAdditionalVerilogOn: aStream!

printBlockVerilogOn: aStream
    |w name|
    name := self verilogName.
    aStream nl.
    aStream 
        nextPutAll: '    always @(posedge %1 or negedge %2)' 
            % {clock printStringStyle: #VERILOG.
               reset printStringStyle: #VERILOG}; 
        nl;
        nextPutAll: '        if (!%1)' % {reset printStringStyle: #VERILOG};
        nl;
        nextPutAll: '            %1 <= %2;' % {name. resetTo printStringStyle: #VERILOG};
        nl;
        nextPutAll: '        else'; nl.
    expression alias: name.
    expression printCoreVerilogOn: aStream indent: 12 blocking: false.
    clock clearAlias.
    expression clearAlias!
!
