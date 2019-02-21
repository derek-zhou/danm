SystemExceptions.UserInterrupt extend [

    isResumable [
	"override so ctl-c is resumable"
	<category: 'exception description'>
	^true
    ]

]

Object subclass: DANMSimulator [
    | sch stimuli evSets changeSet currentTime callbacks stepCount evCount changeCount shouldContinue stopper trigger triggeringValue |
    <category: ''>
    <comment: 'I am a simulator that simulates a discrate time system described by a
schematic. At each (varying) time step one or more stimuli fire and trigger
cascading changes for a set of wires in the schematic. All affect wires then 
change to new value together then wait for the next time step'>

    DANMSimulator class >> on: dut [
	<category: 'instance creation'>
	^self new initWith: dut
    ]

    initWith: dut [
	<category: 'initialize'>
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
	sch wires do: [:w | 
	    (w expression notNil and: [w expression isKindOf: TimeSeries]) ifTrue: [
		stimuli add: w expression ]]
    ]

    dut [
	<category: 'accessing'>
	^sch
    ]

    changeSet [
	<category: 'accessing'>
	^changeSet
    ]

    currentTime [
	<category: 'accessing'>
	^currentTime
    ]

    wires [
	<category: 'accessing'>
	^sch wires
    ]

    context [
	"simulator is the top level"
	<category: 'accessing'>
	^self
    ]

    fullPath [
	"for reporting"
	<category: 'accessing'>
	^''
    ]

    finish [
	"shutdown the simulator, cannot resume"
	<category: 'accessing'>
	self postEvent: #SimulationEnded.
	Transcript nextPutAll: 'Simulation finished at: %1' % {currentTime}; nl
    ]

    setCallbackFrom: obj on: event do: aBlock [
	<category: 'accessing'>
	| dic |
	dic := callbacks at: event ifAbsent: [nil].
	dic isNil ifTrue: [
	    dic := IdentityDictionary new.
	    callbacks at: event put: dic ].
	dic at: obj put: aBlock
    ]

    unsetCallbackFrom: obj on: event [
	<category: 'accessing'>
	(callbacks at: event) removeKey: obj
    ]

    settle [
	"Settle the system for time 0. All stimuli fire once and value propagate
	 through out the schematic"
	<category: 'simulating'>
	evSets := sch buildEvaluationOrderSet.
	"faster this way"
	evSets do: [:each | each become: each asArray].
	self settleStimuli.
	"then settle all undriven wire"
	sch wires do: [:w | w trySettleTo: 0].
	"then settle all other"
	sch calculateQuiescentState: evSets.
	"settle all non-quiescent flop then try again"
	sch wires do: [:w | w settleTo: 0].
	sch calculateQuiescentState: evSets.
	"everything should be settled by now"
	sch wires do: [:w | 
	    w currentValue isNil ifTrue: [
		self error: 'Error: %1 still not settled' % {w name}; nl ]].
	changeSet empty.
	self postEvent: #SimulationSettled
    ]

    runUntil: w is: v [
	"run until the wire become v"
	<category: 'simulating'>
	^self runUntil: w is: v timeout: SmallInteger largest
    ]

    runUntil: w is: v timeout: t [
	"run until the wire become v, or timeout"
	<category: 'simulating'>
	| ret wire |
	(w isKindOf: DANMWire) 
	    ifTrue: [wire := w]
	    ifFalse: [wire := sch wireByName: w].
	trigger := wire.
	triggeringValue := v.
	ret := self runUpto: currentTime + t.
	trigger := nil.
	triggeringValue := nil.
	^ret
    ]

    valueOf: w [
	<category: 'simulating'>
	(w isKindOf: DANMWire) 
	    ifTrue: [^w currentValue]
	    ifFalse: [^(sch wireByName: w) currentValue]
    ]

    widthOf: w [
	<category: 'simulating'>
	(w isKindOf: DANMWire) 
	    ifTrue: [^w width]
	    ifFalse: [^(sch wireByName: w) width]
    ]

    force: w to: v [
	<category: 'simulating'>
	(w isKindOf: DANMWire) 
	    ifTrue: [w forceTo: v]
	    ifFalse: [(sch wireByName: w) forceTo: v]
    ]

    run [
	"run until all stimuli go out"
	<category: 'simulating'>
	^self runUpto: SmallInteger largest
    ]

    stop: source [
	"stop the simulation from eg. an error condition happened within,
	 at the end of the current timestep"
	<category: 'simulating'>
	stopper := source.
	shouldContinue := false
    ]

    isFinished [
	<category: 'simulating'>
	^shouldContinue
    ]

    runUpto: limit [
	"run until all stimuli go out, or timeout, return the time
	 * intertupt signal; return the signal
	 * assertion fired, return the assertion
	 * triggering wire triggered. return the wire.
	 in the last case the simulator is expected to resume shortly so
	 some clean up is not done. If you do not want to resume you need to
	 call -finish"
	<category: 'simulating'>
	shouldContinue ifFalse: [
	    (stopper isKindOf: DANMWire) ifFalse: [self postEvent: #SimulationResumed].
	    stopper := nil.
	    shouldContinue := true.
	    "outside might have changed something"
	    self reEvaluate ].
	[
	    [   currentTime < limit & (stimuli size > 0) & shouldContinue ] whileTrue: [
		self runOnce.
		self heartBeat ]
	] on: SystemExceptions.UserInterrupt do: [ :sig | 
	    self stop: sig.
	    sig resume ].
	shouldContinue ifTrue: [ self stop: currentTime ].
	(stopper isKindOf: DANMWire) ifFalse: [
	    self postEvent: #SimulationEnded.
	    Transcript nextPutAll: 'Simulation stopped at: %1' % {currentTime}; nl ].
	(stopper isKindOf: DANMAssertion) ifTrue: [
	    self error: 'assertion triggered, cannot continue'].
	^stopper
    ]

    runOnce [
	"run one time step"
	<category: 'simulating'>
	currentTime := stimuli first fireTime.
	self fireStimuli.
	self reEvaluate
    ]

    reEvaluate [
	<category: 'simulating'>
	evSets do: [:s | self runOneSet: s].
	changeSet do: [:w | 
	    w dataRefSet do: [:each | each setDataDirty].
	    (w == trigger and: [w nextValue == triggeringValue]) ifTrue: [
		self stop: w ].
	    w flip ].
	changeCount := changeCount + changeSet size.
	stepCount := stepCount + 1.
	self postEvent: #SimulationStepEnded.
	changeSet empty
    ]

    heartBeat [
	<category: 'simulating'>
	evCount > 100000 ifTrue: [
	    Transcript nextPutAll: 'Info: at %1: %2 steps, %3 evaluations and %4 changes since last log' %
		{currentTime. stepCount. evCount. changeCount}; nl.
	    stepCount := 0.
	    changeCount := 0.
	    evCount := 0]
    ]

    runOneSet: s [
	<category: 'simulating'>
	s do: [ :w | 
	    w isDirty ifTrue: [
		w evaluate notNil ifTrue: [self addTriggerOn: w].
		evCount := evCount + 1.
		w resetDirty ]]
    ]

    fireStimuli [
	<category: 'simulating'>
	| s w |
        [ stimuli size > 0 and: [ stimuli first fireTime == currentTime ]] whileTrue: [
	    s := stimuli first.
	    w := s context.
	    stimuli removeFirst.
	    w evaluate notNil ifTrue: [self addTriggerOn: w].
	    s fireTime notNil ifTrue: [
		s fireTime <= currentTime ifTrue: [
		    self error: 'stimuli %1 did not advance time at %2.' % 
			{w. currentTime}; nl ].
		stimuli add: s ]]
    ]

    addStimuli: s [
	<category: 'simulating'>
	stimuli add: s
    ]

    settleStimuli [
	<category: 'simulating'>
	| sc |
	sc := stimuli asArray.
	stimuli empty.
	sc do: [:s | 
	    s context evaluate.
	    s fireTime notNil ifTrue: [stimuli add: s]]
    ]

    addTriggerOn: w [
	<category: 'simulating'>
	changeSet add: w.
	w directRefSet do: [:each | each setDirty].
	w fastWidth == 1 & (w nextValue == 1) ifTrue: [
	    "clock rising"
	    w clockRefSet do: [:each | each setClockDirty ]]
    ]

    addStaticTriggerOn: w [
	"a static trigger triggers all loads, including D pin of a flop"
	<category: 'simulating'>
	w flip.
	w directRefSet do: [:each | each setDirty].
	w dataRefSet do: [:each | 
	    each
		setDataDirty;
		setClockDirty ]
    ]

    postEvent: event [
	<category: 'simulating'>
	| hooks |
	hooks := callbacks at: event ifAbsent: [nil].
	hooks isNil ifTrue: [^self].
	hooks do: [:block | block value: self]
    ]
]

DANMWire extend [

    trySettleTo: v [
	<category: 'simulating'>
	value isNil ifTrue: [
	    Transcript nextPutAll: 'Warning: wire %1 is undriven, set to %2 now for simulation' % 
		{self name. v}; nl.
	    value := v ]
    ]

    settleTo: v [
	<category: 'simulating'>
	^self
    ]

    forceTo: v [
	"force me to some new value and trigger all down stream.
	 This should only be called inside simulation"
	<category: 'simulating'>
	self value: v.
	context context addTriggerOn: self
    ]

]

DANMExpressionWire extend [

    trySettleTo: v [
	<category: 'simulating'>
	^self
    ]

    forceTo: v [
	"force me to some new value and trigger all down stream.
	 This should only be called inside simulation"
	<category: 'simulating'>
	self nextValue: v.
	self flip.
	context context addTriggerOn: self
    ]

]

DANMFlipflop extend [

    settleTo: v [
	<category: 'simulating'>
	value isNil ifTrue: [
	    Transcript nextPutAll: 'Warning: flop %1 fails to reach quiescent, set to %2 now for simulation' % 
		{self name. v}; nl.
	    self nextValue: v.
	    context context addStaticTriggerOn: self ]
    ]

]
