DANMExpressionWire subclass: #DANMMonostable
    instanceVariableNames: 'delay stimuli'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMMonostable comment:
    'I am a monostable which goes back to 0 after certain delay'!

!DANMMonostable methodsFor: 'accessing'!

delay: d
    delay := d!

delay
    ^delay!
!

!DANMMonostable methodsFor: 'basic'!

staticValue
    self nextValue: 0.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

evaluate
    |v|
    stimuli notNil ifTrue: [
        (context context isKindOf: DANMSimulator) ifTrue: [ 
            stimuli fireTime == context context currentTime ifTrue: [ 
                stimuli fireTime: nil.
                stimuli := nil.
                self nextValue: 0.
                nextValue ~= value ifTrue: [ ^nextValue ]]].
        ^nil ].
    ^super evaluate!

flip
    (nextValue ~= 0 & (context context isKindOf: DANMSimulator)) ifTrue: [
        stimuli := TimeSeries new.
        stimuli fireTime: context context currentTime + delay.
        stimuli context: self type: #DIRECT.
        context context addStimuli: stimuli ].
    ^super flip!

checkDesign
    expression isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: monostable %2 has no input'
            % {context name. entityName}; nl.
        ^false ].
    expression width ~=1 ifTrue: [ 
        Transcript nextPutAll: 'Check design error in %1: monostable %2 input is not single bit'
            % {context name. entityName}; nl.
        ^false ].
    (expression isKindOf: ASTIdentifier) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: monostable %2 input is not a wire'
            % {context name. entityName}; nl.
        ^false ].
    ^super checkDesign!
!

!DANMMonostable methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: ('(%1\_%2) ' % {expression. delay})!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    expression printAdditionalVerilogOn: aStream.
    expression printVerilogOn: aStream withAlias: 'Monostable'!

printBlockVerilogOn: aStream
    |w name|
    name := self verilogName.
    aStream nl.
    aStream 
        nextPutAll: '    always @(posedge %1 or posedge %2)' 
            % {expression printStringStyle: #VERILOG. name}; nl;
        nextPutAll: '        if (%1)' % {name}; nl;
        nextPutAll: '            %1 <= #%2 0;' % {name. delay} ; nl;
        nextPutAll: '        else'; nl;
        nextPutAll: '            %1 <= %2;' 
            % {name. expression printStringStyle: #VERILOG. name}; nl.
    expression clearAlias!
!
