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

DANMEntity subclass: DANMWire [
    | connections context refs value myWidth clockRefSet dataRefSet directRefSet |
    <comment: nil>
    <category: 'DANM'>

    DANMWire class >> newNamed: aName inContext: c [
	<category: 'instance creation'>
	| oldWire newWire |
	oldWire := c findWireByName: aName.
	oldWire notNil ifTrue: [
	    (oldWire isKindOf: self) ifTrue: [^oldWire]].
	newWire := self new.
	oldWire notNil ifTrue: [
	    newWire mergeWith: oldWire.
	    c addWire: newWire byName: oldWire name.
	    ^newWire].
	c addWire: newWire byName: aName.
	^newWire
    ]

    DANMWire class >> newReplacementNamed: aName inContext: c [
	<category: 'instance creation'>
	| oldWire newWire |
	oldWire := c wireByName: aName.
	newWire := self new.
	newWire mergeWith: oldWire.
	c addWire: newWire byName: oldWire name.
	^newWire
    ]

    isDriven [
	"whether the wire is driven"
	<category: 'testing'>
	^self isDrivenInternally | self isTriState or: [
	    | port |
	    port := context findPortByName: entityName.
	    port isNil ifTrue: [false] ifFalse: [port isInput]]
    ]

    isDrivenInternally [
	<category: 'testing'>
	^self connections inject: false into: [ :result :each |
	    result | each isOutput]
    ]

    isTriState [
	<category: 'testing'>
	^self connections inject: false into: [ :result :each |
	    result | each isInout]
    ]

    isSequential [
	<category: 'testing'>
	^false
    ]

    isSystemNamed [
	"whether the name come from the system or the user"
	<category: 'testing'>
	^context containsGeneratedName: self name
    ]

    driverCount [
	"How many driver exist"
	<category: 'testing'>
	| port result |
	result := self connections inject: 0 into: [ :r :each |
	    each isOutput ifTrue: [r + 1] ifFalse: [r]].
	result > 0 ifTrue: [^result].
	port := context findPortByName: entityName.
	(port ~= nil and: [port isInput]) ifTrue: [^1].
	^0
    ]

    directFanins [
	<category: 'testing'>
	| result |
	result := OrderedCollection new.
	self connections do: [:each |
	    each isOutput ifTrue: [result add: each context]].
	^result
    ]

    isPort [
	<category: 'testing'>
	| port |
	port := context findPortByName: entityName.
	^port notNil
    ]

    isLoaded [
	"whether the wire has load"
	<category: 'testing'>
	| port result |
	(refs notNil and: [refs size > 0]) ifTrue: [^true].
	result := self connections inject: false into: [ :r :each |
	    r | each isInput].
	result ifTrue: [^true].
	port := context findPortByName: entityName.
	^port notNil and: [port isOutput | port isInout]
    ]

    isDangle [
	"no driver, no load"
	<category: 'testing'>
	^self isDriven not & self isLoaded not
    ]

    isExposed [
	"whether there is a port of the same name"
	<category: 'testing'>
	^(context findPortByName: entityName) ~= nil
    ]

    isDirty [
	<category: 'testing'>
	^false
    ]

    printBinaryValueOn: fs [
	<category: 'testing'>
	| num cut |
	num := value.
	cut := 2 raisedToInteger: myWidth.
	myWidth timesRepeat: [
	    cut := cut / 2.
	    num >= cut 
		ifTrue: [
		    fs nextPut: $1.
		    num := num - cut]
		ifFalse: [fs nextPut: $0]]
    ]

    addRef: r [
	<category: 'accessing'>
	refs isNil ifTrue: [refs := OrderedCollection new].
	refs add: r
    ]

    removeRef: r [
	<category: 'accessing'>
	refs remove: r.
	refs size == 0 ifTrue: [refs := nil]
    ]

    refs [
	<category: 'accessing'>
	refs isNil ifTrue: [^#()].
	^refs
    ]

    aka [
	<category: 'accessing'>
	| arr |
	arr := self attribute: #AlsoKnownAs.
	arr notNil ifTrue: [^arr asArray].
	^#()
    ]

    addAka: n [
	<category: 'accessing'>
	| arr |
	arr := self attribute: #AlsoKnownAs.
	arr notNil 
	    ifTrue: [arr add: n]
	    ifFalse: [self setAttribute: #AlsoKnownAs to: (OrderedCollection with: n)]
    ]

    addAkas: s [
	<category: 'accessing'>
	| arr |
	arr := self attribute: #AlsoKnownAs.
	arr notNil 
	    ifTrue: [arr addAll: s]
	    ifFalse: [s size > 0 ifTrue: [self setAttribute: #AlsoKnownAs to: s]]
    ]

    prefixAkaWith: prefix [
	<category: 'accessing'>
	| arr |
	arr := self attribute: #AlsoKnownAs.
	arr notNil ifTrue: [
	    self setAttribute: #AlsoKnownAs to: (arr collect: [:each | prefix , '/' , each])]
    ]

    clockRefSet [
	<category: 'accessing'>
	| set |
	clockRefSet notNil ifTrue: [^clockRefSet].
	set := IdentitySet new.
	self refs do: [ :each |
	    each type == #CLOCK ifTrue: [set add: each context]].
	"optimization. Literals are shared so it saves an object"
	set size > 0 
	    ifTrue: [clockRefSet := set asArray]
	    ifFalse: [clockRefSet := #()].
	^clockRefSet
    ]

    dataRefSet [
	<category: 'accessing'>
	| set |
	dataRefSet notNil ifTrue: [^dataRefSet].
	set := IdentitySet new.
	self refs do: [ :each | 
	    each type == #DATA | (each type == #LATCHDATA) ifTrue: [
		set add: each context]].
	set size > 0 
	    ifTrue: [dataRefSet := set asArray]
	    ifFalse: [dataRefSet := #()].
	^dataRefSet
    ]

    directRefSet [
	<category: 'accessing'>
	| set |
	directRefSet notNil ifTrue: [^directRefSet].
	set := IdentitySet new.
	self refs do: [:each | 
	    each type == #DIRECT | (each type == #LATCHDATA) ifTrue: [
		set add: each context]].
	set size > 0 
	    ifTrue: [directRefSet := set asArray]
	    ifFalse: [directRefSet := #()].
	^directRefSet
    ]

    context [
	"My context is the schematic that instances me"
	<category: 'accessing'>
	^context
    ]

    context: newContext [
	<category: 'accessing'>
	context := newContext
    ]

    evaluationOrder [
	<category: 'accessing'>
	^0
    ]

    clearDerivedData [
	"some data is derived from more fundimental data; the derived ones are
	 kept mainly for performance reason. However, sometimes there is a need
	 to clear all that because structural change that make them stale"
	<category: 'accessing'>
	value := nil.
	dataRefSet := nil.
	directRefSet := nil.
	clockRefSet := nil.
	self tag: nil
    ]

    optimize [
	<category: 'accessing'>
	^self
    ]

    nextValue [
	<category: 'accessing'>
	^value
    ]

    currentValue [
	<category: 'accessing'>
	^value
    ]

    staticValue [
	<category: 'accessing'>
	^value
    ]

    flip [
	<category: 'accessing'>
	^self
    ]

    value: v [
	<category: 'accessing'>
	value := v bitAnd: (1 bitShift: self width) - 1
    ]

    expression [
	<category: 'accessing'>
	^nil
    ]

    width [
	"getting width. it tries harder than fastWidth. However don't call this
	 if there is a possibility to casue recursion"
	<category: 'accessing'>
	myWidth notNil & (myWidth ~= 0) ifTrue: [^myWidth].
	myWidth := self minWidth.
	^myWidth
    ]

    fastWidth [
	"getting width. it may return 0 if recursion is detected"
	<category: 'accessing'>
	myWidth notNil ifFalse: [
	    "it looks strange, but it avoids recursion. subclass may override
	     minwidth and call fastWidth on some other wire so if recursion
	     happens it will stop here"
	    myWidth := 0.
	    myWidth := self minWidth].
	^myWidth
    ]

    minWidth [
	<category: 'accessing'>
	^0
    ]

    width: newWidth [
	<category: 'accessing'>
	myWidth := newWidth
    ]

    recalculateWidth [
	<category: 'accessing'>
	myWidth := self connections inject: self minWidth into: [ :maxW :pin |
	    maxW max: pin width]
    ]

    connections [
	"connections is an array of pin"
	<category: 'accessing'>
	connections isNil ifTrue: [^#()].
	^connections
    ]

    connectionsSize [
	<category: 'accessing'>
	^self connections size
    ]

    startingFanins [
	<category: 'accessing'>
	^self faninTreeInject: IdentitySet new into: [ :set :each | 
	    ((each isKindOf: DANMPort) or: [each isSequential]) ifTrue: [set add: each].
	    set]
    ]

    endingFanouts [
	<category: 'accessing'>
	^self fanoutTreeInject: IdentitySet new into: [ :set :each | 
	    ((each isKindOf: DANMPort) or: [each isSequential]) ifTrue: [set add: each].
	    set]
    ]

    faninTreeInject: value into: block [
	"treverse the fanin tree and call block for each. Block is a 2 input block,
	 first one argument is the result of previous invocation and second is
	 myself"
	<category: 'accessing'>
	| result port |
	result := value.
	self connections do: [ :each |
	    each isOutput ifTrue: [result := block value: result value: each]].
	port := context findPortByName: entityName.
	(port notNil and: [port isInput]) ifTrue: [
	    result := block value: result value: port].
	^result
    ]

    fanoutTreeInject: value into: block [
	"treverse the fanout tree and call block for each. Block is a 2 input
	 block, first one argument is the result of previous invocation and second
	 is myself"
	<category: 'accessing'>
	| result port |
	result := value.
	self connections do: [:each |
	    each isInput ifTrue: [result := block value: result value: each]].
	port := context findPortByName: entityName.
	(port notNil and: [port isOutput]) ifTrue: [
	    result := block value: result value: port].
	self refs do: [:each | 
	    each type == #DIRECT | (each type == #LATCHDATA) ifTrue: [
		result := each context fanoutTreeInject: result into: block].
	    result := block value: result value: each context].
	^result
    ]

    complexity [
	<category: 'accessing'>
	| mw fi fo ci co |
	mw := self width.
	fi := self startingFanins inject: 0 into: [ :s :each |
	    s + (each width / mw) ceiling].
	ci := ((fi max: 1) log: 2) ceiling.
	fo := self endingFanouts inject: 0 into: [ :s :each |
	    s + (each width / mw) ceiling].
	co := ((fo max: 1) log: 4) ceiling.
	^self isSequential ifTrue: [ci max: co] ifFalse: [ci + co]
    ]

    renameTo: newName [
	<category: 'connecting'>
	| oldName oldContext anotherWire |
	anotherWire := context findWireByName: newName.
	anotherWire notNil ifTrue: [self mergeWith: anotherWire].
	oldName := entityName.
	oldContext := context.
	oldContext removeWireByName: oldName.
	oldContext addWire: self byName: newName
    ]

    connectPins: pins [
	<category: 'connecting'>
	pins do: [:each | 
	    | oldWire |
	    oldWire := each context wireOnPort: each.
	    oldWire notNil ifTrue: [
		oldWire isDriven & oldWire isLoaded ifTrue: [
		    Transcript nextPutAll: 'Instance %1 port %2 is already connected to wire %3' % 
			{each context. each. oldWire}; nl ].
			"Undriven or unloaded wire can be safely disconnected"
		oldWire disconnectPort: each.
		each context disconnectPort: each].
	    self connectPort: each.
	    each context connectWire: self toPort: each]
    ]

    connectPort: p [
	<category: 'connecting'>
	| w pw |
	w := self width.
	pw := p width.
	pw > w ifTrue: [myWidth := pw].
	connections isNil ifTrue: [connections := OrderedCollection new].
	connections add: p
    ]

    disconnectPort: p [
	<category: 'connecting'>
	connections remove: p.
	connections size == 0 ifTrue: [connections := nil].
	self isDangle ifTrue: [
	    context removeWireByName: entityName.
	    self context: nil]
    ]

    destroy [
	<category: 'connecting'>
	(context findPortByName: entityName) notNil ifTrue: [
	    context removePort: (context portByName: entityName)].
	context removeWireByName: entityName.
	self context: nil
    ]

    expose [
	<category: 'transforming'>
	self shouldConceal ifTrue: [self unsetAttribute: #ShouldConceal].
	self isExposed ifFalse: [
	    context addPort: (DANMSchematicPort newFromWire: self)]
    ]

    conceal [
	<category: 'transforming'>
	self setAttribute: #ShouldConceal to: true.
	self isExposed ifTrue: [
	    context removePort: (context portByName: entityName)]
    ]

    shouldConceal [
	<category: 'transforming'>
	^(self attribute: #ShouldConceal) notNil
    ]

    pushUpHierarchy [
	<category: 'transforming'>
	| upperWire port newName upperContext |
	self prefixAkaWith: context name.
	newName := context hierNamePrefix , entityName.
	port := context findPortByName: entityName.
	port notNil ifTrue: [
	    upperWire := context wireOnPort: port.
	    self conceal].
	upperWire notNil ifTrue: [
	    "need to disconnect this port first to avoid confusion"
	    upperContext := upperWire context.
	    context disconnectPort: port.
	    upperWire disconnectPort: port.
	    self isDrivenInternally 
		ifTrue: [
		    self addAka: newName.
		    self mergeWith: upperWire.
		    upperContext addWire: self byName: upperWire name.
		    ^self]
		ifFalse: [
		    upperWire addAka: newName.
		    upperWire mergeWith: self.
		    "make sure upperwire is valid. It could have been disconnected"
		    upperWire context isNil ifTrue: [upperContext addWire: upperWire].
		    ^upperWire]].
	"internal wire, just rename and add"
	context context addWire: self byName: newName
    ]

    splitDownHierarchy: lower [
	"Create a lower wire of the same name and expose it, connect it to me"
	<category: 'transforming'>
	| newWire subPort |
	newWire := lower findWireByName: entityName.
	newWire isNil ifTrue: [
	    newWire := (DANMWire new)
		      name: entityName;
		      width: self width.
	    lower addWire: newWire].
	(lower findPortByName: entityName) isNil ifTrue: [newWire expose].
	self splitTo: newWire.
	subPort := lower portByName: entityName.
	(lower wireOnPort: subPort) notNil ifTrue: [
	    self error: 'port %1 is already connected' % {subPort}; nl].
	lower connectWire: self toPort: subPort.
	self connectPort: subPort
    ]

    splitUpHierarchy [
	"Expose myself and create a higher wire of the same name
	 and connect to the port"
	<category: 'transforming'>
	| higher newWire subPort |
	(context findPortByName: entityName) isNil ifTrue: [self expose].
	subPort := context portByName: entityName.
	newWire := context wireOnPort: subPort.
	newWire isNil ifTrue: [
	    newWire := (DANMWire new)
			name: entityName;
			width: self width.
	    context context addWire: newWire.
	    context connectWire: newWire toPort: subPort.
	    newWire connectPort: subPort].
	self splitTo: newWire
    ]

    repairHierarchy: lower [
	"the wire is currently either in lower or the higher schematic, but it may
	 really be in lower, or higher, or both. This method repair the
	 connectivity by either moving or spliting"
	<category: 'transforming'>
	| usage |
	usage := self realUsage: lower.
	context == lower
            ifTrue: [
		usage == 3 ifTrue: [self splitUpHierarchy].
		usage == 2 ifTrue: [
		    context removeWireByName: entityName.
		    self pushUpHierarchy]]
	    ifFalse: [
		usage == 3 ifTrue: [self splitDownHierarchy: lower].
		usage == 1 ifTrue: [
		    context removeWireByName: entityName.
		    lower addWire: self]]
    ]

    realUsage: lower [
	"return 1 if the wire is only driven/loaded in lower. 2 if only
	 driven/loaded in higher. 3 both, 0 neither"
	<category: 'transforming'>
	| result higher |
	result := 0.
	lower == self context 
	    ifTrue: [higher := self context context]
	    ifFalse: [higher := self context].
	(higher findPortByName: entityName) notNil ifTrue: [
	    result := result bitOr: 2].
	self connections do: [ :each | 
	    each context context == lower 
		ifTrue: [result := result bitOr: 1]
		ifFalse: [result := result bitOr: 2]].
	self refs do: [:each | 
	    each identifier context == lower 
		ifTrue: [result := result bitOr: 1]
		ifFalse: [result := result bitOr: 2]].
	^result
    ]

    mergeWith: anotherWire [
	<category: 'transforming'>
	"merge with another wire"
	| port |
	anotherWire connections do: [ :pin | 
	    self connectPort: pin.
	    pin context basicConnectWire: self toPort: pin].
	anotherWire refs do: [ :ref | 
	    self addRef: ref.
	    ref identifier: self].
	anotherWire context notNil ifTrue: [
	    port := anotherWire context findPortByName: anotherWire name.
	    port notNil ifTrue: [port wire: self]].
	self addAkas: anotherWire aka
    ]

    splitTo: anotherWire [
	"push foreign connections and references to anotherWire"
	<category: 'transforming'>
	self connections copy do: [ :pin | 
	    pin context context == anotherWire context ifTrue: [
		self disconnectPort: pin.
		anotherWire connectPort: pin.
		pin context basicConnectWire: anotherWire toPort: pin]].
	self refs copy do: [:ref | 
	    ref context context == anotherWire context ifTrue: [
		self removeRef: ref.
		anotherWire addRef: ref.
		ref identifier: anotherWire]]
    ]

    printOn: aStream [
	<category: 'printing'>
	self width == 1 
	    ifTrue:  [aStream nextPutAll: '%1' % {entityName}]
	    ifFalse: [aStream nextPutAll: '%1[%2:0]' % {entityName. self width - 1}]
    ]

    printAdditionalVerilogOn: aStream [
	<category: 'printing'>
	^self printVerilogOn: aStream
    ]

    printVerilogOn: aStream [
	<category: 'printing'>
	self tag notNil ifFalse: [^self].
	self tag: nil.
	self basicPrintVerilogOn: aStream
    ]

    printBlockVerilogOn: aStream [
	<category: 'printing'>
	^self
    ]

    nodeStyle [
	<category: 'printing'>
	^'[shape=diamond]'
    ]

    printDigraphOn: aStream [
	<category: 'printing'>
	aStream nextPutAll: '"%1" %2;' % {entityName. self nodeStyle}; nl.
	self clockRefSet do: [ :each | 
	    aStream nextPutAll: '"%1" -> "%2" [style=dashed];' % 
		{entityName. each name}; nl].
	self dataRefSet do: [ :each | 
	    aStream nextPutAll: '"%1" -> "%2" [style=dotted];' % 
		{entityName. each name}; nl].
	self directRefSet do: [ :each | 
	    aStream nextPutAll: '"%1" -> "%2" [style=solid];' % 
		{entityName. each name}; nl]
    ]

    basicPrintVerilogOn: aStream [
	<category: 'printing'>
	| w |
	w := self width.
	w == 1
            ifTrue: [
		aStream nextPutAll: '    wire %1;' % {self verilogName}; nl]
	    ifFalse: [
		aStream nextPutAll: '    wire [%1:0] %2;' % 
		    {w - 1. self verilogName}; nl]
    ]
]
