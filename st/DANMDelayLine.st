DANMExpressionWire subclass: #DANMDelayLine
    instanceVariableNames: 'delay stimuli fireTimes fireValues'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMDelayLine comment:
    'I am a delay line that model transport delay'!

!DANMDelayLine methodsFor: 'accessing'!

delay: d
    delay := d!

delay
    ^delay!

addValue: v
    fireTimes isNil ifTrue: [
        fireTimes := OrderedCollection new.
        fireValues := OrderedCollection new ].
    fireValues add: v.
    fireTimes add: context context currentTime + delay.
    stimuli isNil ifTrue: [
        stimuli := TimeSeries new.
        stimuli fireTime: fireTimes first.
        stimuli context: self type: #DIRECT.
        context context addStimuli: stimuli ]!

lastValue
    (fireValues isNil or: [ fireValues size == 0 ]) ifTrue: [
        ^value ].
    ^fireValues last!

shiftValue
    fireTimes removeFirst.
    fireTimes isEmpty 
        ifTrue: [
            stimuli fireTime: nil.
            stimuli := nil ]
        ifFalse: [
            stimuli fireTime: fireTimes first ].    
    ^fireValues removeFirst!
!

!DANMDelayLine methodsFor: 'basic'!

evaluate
    |v|
    (context context isKindOf: DANMSimulator) ifFalse: [
        ^super evaluate ].
    ASTIdentifier useNextValue: true.
    v := expression evaluate.
    v = self lastValue ifFalse: [ 
        self addValue: v ].
    (stimuli notNil and: [
        stimuli fireTime == context context currentTime]) ifTrue: [ 
            self nextValue: self shiftValue.
            nextValue ~= value ifTrue: [ ^nextValue ]].
    ^nil!

checkDesign
    expression isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: delayline %2 has no input'
            % {context name. entityName}; nl.
        ^false ].
    delay > 0 ifFalse: [ 
        Transcript nextPutAll: 'Check design error in %1: delayline %2 has invalid delay'
            % {context name. entityName}; nl.
        ^false ].
    ^super checkDesign!
!

!DANMDelayLine methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: ('(%1#%2) ' % {expression. delay})!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    expression printAdditionalVerilogOn: aStream.
    expression printVerilogOn: aStream withAlias: 'DelayLine'!

printBlockVerilogOn: aStream
    |w name|
    name := self verilogName.
    aStream 
        nl;
        nextPutAll: '    always @(%1)' 
        % {expression printStringStyle: #VERILOG}; nl;
        nextPutAll: '        %1 <= #%2 %3;' 
        % {name. delay. expression printStringStyle: #VERILOG. name}; nl.
    expression clearAlias!
!
