!SystemExceptions.UserInterrupt methodsFor: 'exception description'!

isResumable
"override so ctl-c is resumable"
    ^true!
!

Object subclass: #DANMSimulator
    instanceVariableNames: 
        'sch stimuli evSets changeSet currentTime callbacks 
stepCount evCount changeCount shouldContinue stopper trigger triggeringValue'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMSimulator comment:
    'I am a simulator that simulates a discrate time system described by a
schematic. At each (varying) time step one or more stimuli fire and trigger
cascading changes for a set of wires in the schematic. All affect wires then 
change to new value together then wait for the next time step'!

!DANMSimulator class methodsFor: 'instance creation'!

on: dut
    ^ self new 
        initWith: dut!
!

!DANMSimulator methodsFor: 'initialize'!

initWith: dut
    sch := dut.
    sch context: self.
    changeSet := OrderedCollection new.
    currentTime := 0.
    stepCount := 0.
    evCount := 0.
    changeCount := 0.
    shouldContinue := true.
    stimuli := SortedCollection new.
    callbacks := IdentityDictionary new.
    sch wires do: [ :w |
        (w expression notNil and: [ w expression isKindOf: TimeSeries ])
            ifTrue: [ stimuli add: w expression ]]!
!

!DANMSimulator methodsFor: 'accessing'!

dut 
    ^sch!

changeSet
    ^changeSet!

currentTime
    ^currentTime!

wires
    ^sch wires!

context
    "simulator is the top level"
    ^self!

fullPath
    "for reporting"
    ^''!
finish
    "shutdown the simulator, cannot resume"
    self postEvent: #SimulationEnded.
    Transcript nextPutAll: 'Simulation finished at: %1' % {currentTime}; nl!

setCallbackFrom: obj on: event do: aBlock
    |dic|
    dic := callbacks at: event ifAbsent: [ nil ].
    dic isNil ifTrue: [ 
        dic := IdentityDictionary new.
        callbacks at: event put: dic ].
    dic at: obj put: aBlock!

unsetCallbackFrom: obj on: event
    (callbacks at: event) removeKey: obj! 
!

!DANMWire methodsFor: 'simulating'!

trySettleTo: v
    value isNil ifTrue: [ 
        Transcript nextPutAll: 'Warning: wire %1 is undriven, set to %2 now for simulation' 
            % {self name. v}; nl.
        value := v ]!

settleTo: v
    ^self!

forceTo: v
    "force me to some new value and trigger all down stream. 
     This should only be called inside simulation"
    self value: v.
    context context addTriggerOn: self!
!

!DANMExpressionWire methodsFor: 'simulating'!

trySettleTo: v
    ^self!
!

!DANMFlipflop methodsFor: 'simulating'!

settleTo: v
    value isNil ifTrue: [
        Transcript nextPutAll: 'Warning: flop %1 fails to reach quiescent, set to %2 now for simulation' 
            % {self name. v}; nl.
        self nextValue: v.
        context context addStaticTriggerOn: self ]!
!

!DANMSimulator methodsFor: 'simulating'!
 
settle
    "Settle the system for time 0. All stimuli fire once and value propagate
through out the schematic"
    evSets := sch buildEvaluationOrderSet.
    "faster this way"
    evSets do: [ :each | each become: each asArray ].
    self settleStimuli.
    "then settle all undriven wire"
    sch wires do: [ :w | w trySettleTo: 0 ].
    "then settle all other"
    sch calculateQuiescentState: evSets.
    "settle all non-quiescent flop then try again"
    sch wires do: [ :w | w settleTo: 0 ].
    sch calculateQuiescentState: evSets.
    "everything should be settled by now"
    sch wires do: [ :w |
        w currentValue isNil ifTrue: [ 
            self error: 'Error: %1 still not settled' % {w name}; nl ]].
    changeSet empty.
    self postEvent: #SimulationSettled!

runUntil: w is: v
    "run until the wire become v"
    ^self runUntil: w is: v timeout: SmallInteger largest!

runUntil: w is: v timeout: t
    "run until the wire become v, or timeout"
    |ret wire|
    (w isKindOf: DANMWire) 
        ifTrue: [ wire := w ]
        ifFalse: [ wire := sch wireByName: w ].
    trigger := wire.
    triggeringValue := v.
    ret := self runUpto: currentTime + t.
    trigger := nil.
    triggeringValue := nil.
    ^ret!

valueOf: w
    (w isKindOf: DANMWire) 
        ifTrue: [ ^w currentValue ]
        ifFalse: [ ^(sch wireByName: w) currentValue ]!

widthOf: w
    (w isKindOf: DANMWire) 
        ifTrue: [ ^w width ]
        ifFalse: [ ^(sch wireByName: w) width ]!

force: w to: v
    (w isKindOf: DANMWire) 
        ifTrue: [ w forceTo: v ]
        ifFalse: [ (sch wireByName: w) forceTo: v ]!
    
run
    "run until all stimuli go out"
    ^self runUpto: SmallInteger largest!

stop: source
    "stop the simulation from eg. an error condition happened within, 
at the end of the current timestep"
    stopper := source.
    shouldContinue := false!

isFinished
    ^shouldContinue!

runUpto: limit
    "run until all stimuli go out, or timeout, return the time
     * intertupt signal; return the signal
     * assertion fired, return the assertion
     * triggering wire triggered. return the wire.
     in the last case the simulator is expected to resume shortly so
     some clean up is not done. If you do not want to resume you need to
     call -finish"
    shouldContinue ifFalse: [
        (stopper isKindOf: DANMWire) ifFalse: [
            self postEvent: #SimulationResumed ].
        stopper := nil.
        shouldContinue := true.
        "outside might have changed something"
        self reEvaluate ].
    [ 
        [(currentTime < limit) & (stimuli size > 0) & 
             shouldContinue ] whileTrue: [ 
                 self runOnce.
                 self heartBeat ]] 
        on: SystemExceptions.UserInterrupt
        do: [ :sig |
            self stop: sig.
            sig resume ].
    shouldContinue ifTrue: [ self stop: currentTime ].
    (stopper isKindOf: DANMWire) ifFalse: [
        self postEvent: #SimulationEnded.
        Transcript nextPutAll: 'Simulation stopped at: %1' % {currentTime}; 
            nl ].
    (stopper isKindOf: DANMAssertion) ifTrue: [
        self error: 'assertion triggered, cannot continue' ].
    ^stopper!
    
runOnce 
    "run one time step"
    currentTime := stimuli first fireTime.
    self fireStimuli.
    self reEvaluate!

reEvaluate
    evSets do: [ :s | self runOneSet: s ].
    changeSet do: [ :w | 
        w dataRefSet do: [ :each | each setDataDirty ].
        (w == trigger and: [ w nextValue == triggeringValue ]) ifTrue: [
            self stop: w ].
        w flip ].
    changeCount := changeCount + changeSet size.
    stepCount := stepCount + 1.
    self postEvent: #SimulationStepEnded.
    changeSet empty!
    
heartBeat
    evCount > 100000 ifTrue: [
        Transcript nextPutAll: 'Info: at %1: %2 steps, %3 evaluations and %4 changes since last log' 
            % {currentTime. stepCount. evCount. changeCount}; nl.
        stepCount := 0.
        changeCount := 0.
        evCount := 0 ]!
    
runOneSet: s
    s do: [ :w |
        w isDirty ifTrue: [
            w evaluate notNil ifTrue: [ self addTriggerOn: w ].
            evCount := evCount + 1.
            w resetDirty ]]!

fireStimuli
    |s w|
    [ stimuli size > 0 and: [ 
        stimuli first fireTime == currentTime ]] whileTrue: [
            s := stimuli first.
            w := s context.
            stimuli removeFirst.
            w evaluate notNil ifTrue: [ self addTriggerOn: w ].
            s fireTime notNil ifTrue: [ 
                s fireTime <= currentTime ifTrue: [
                    self error: 'stimuli %1 did not advance time at %2.'
                        % {w. currentTime}; nl ].
                stimuli add: s ]]!

addStimuli: s
    stimuli add: s!
    
settleStimuli
    |sc|
    sc := stimuli asArray.
    stimuli empty.
    sc do: [ :s |
        s context evaluate.
        s fireTime notNil ifTrue: [ stimuli add: s ]]!

addTriggerOn: w
    changeSet add: w.
    w directRefSet do: [ :each | each setDirty ].
    (w fastWidth == 1) & (w nextValue == 1) ifTrue: [   
        "clock rising"
        w clockRefSet do: [ :each | each setClockDirty ]]!

addStaticTriggerOn: w
    "a static trigger triggers all loads, including D pin of a flop"
    w flip.
    w directRefSet do: [ :each | each setDirty ].
    w dataRefSet do: [ :each |
        each setDataDirty; setClockDirty ]!

postEvent: event
    |hooks|
    hooks := callbacks at: event ifAbsent: [ nil ].
    hooks isNil ifTrue: [ ^self ].
    hooks do: [ :block | block value: self ]! 
!
