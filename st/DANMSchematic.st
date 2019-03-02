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

DynamicVariable subclass: DANMCurrentDesign [
    <category: ''>
    <comment: ''>
]

DANMBlackBox subclass: DANMSchematic [
    | instances wires userData generatedNames |
    <comment: 'I am a module that is modeled by a schematic 
containing instances of modules and the wires among them.'>
    <category: 'DANM'>

    DANMSchematic class >> emptySchematic [
	<category: 'accessing'>
	^DANMClasslessSchematic new elaborate
    ]

    init [
	"this method should not be called unless the init method of the
	 schematic is wrong"
	<category: 'init'>
	self error: '%1 cannot be elaborated' % {entityName}
    ]

    hierNamePrefix [
	"return the name prefix when hier is flattened. In most cases the name
	 and slash should be used; however wrappers are invisible"
	<category: 'accessing'>
	self reference isNil ifFalse: [^entityName , '/'].
	^''
    ]

    referencePrintName [
	<category: 'accessing'>
	"do not uniqify if not printed inline"
	| prefix |
	self canBePrintedInLine ifFalse: [^self referenceName].
	self context isNil ifTrue: [^self uniquifiedRefName].
	prefix := Smalltalk getenv: 'MODULE_PREFIX'.
	prefix isNil ifTrue: [^self uniquifiedRefName].
	^prefix , self uniquifiedRefName
    ]

    isUniquified [
	<category: 'accessing'>
	^self uniquifiedRefName ~= self referenceName
    ]

    mayMunge [
	<category: 'accessing'>
	^true
    ]

    shouldMunge [
	<category: 'accessing'>
	^self mayMunge & ((Smalltalk getenv: 'MUNGE') = '1')
    ]

    shouldObfuscate [
	<category: 'accessing'>
	^(Smalltalk getenv: 'OBFUSCATE') = '1'
    ]

    skipBlackBox [
	<category: 'accessing'>
	^(Smalltalk getenv: 'SKIPBLACKBOX') = '1'
    ]

    shouldPrintParameterInVerilog [
	<category: 'accessing'>
	^false
    ]

    uniqueWireNameLike: wName [
	<category: 'accessing'>
	| salt newName |
	generatedNames isNil ifTrue: [generatedNames := LookupTable new].
	newName := wires uniqueKeyLike: wName.
	generatedNames at: newName put: 1.
	^newName
    ]

    containsGeneratedName: wName [
	<category: 'accessing'>
	generatedNames isNil ifTrue: [^false].
	^generatedNames includesKey: wName
    ]

    removeGeneratedName: wName [
	<category: 'accessing'>
	generatedNames removeKey: wName
    ]

    isFlat [
	"a flat schematic does not contains any instance"
	<category: 'accessing'>
	instances isNil ifTrue: [^false].
	^instances size > 0
    ]

    canBeFlatten [
	"whether I can be flatten. schematic can"
	<category: 'accessing'>
	self shouldBlackBox ifFalse: [^true].
	self isUniquified ifTrue: [^true].
	^false
    ]

    canBePrintedInLine [
	"whether I can be printed as inline verilog. For schematic the printing
	 will be recursive. Any schematic that do not want to be printed inline
	 should override this method."
	<category: 'accessing'>
	self shouldBlackBox ifTrue: [^false].
	self shouldNotPrint ifTrue: [^false].
	^true
    ]

    ports [
	<category: 'accessing'>
	wires isNil ifTrue: [self elaborate].
	^super ports
    ]

    type [
	<category: 'accessing'>
	^'schematic'
    ]

    instanceByName: iName [
	<category: 'accessing'>
	| inst |
	inst := self findInstanceByName: iName.
	inst isNil ifTrue: [
	    self error: 'Instance by the name of %1 does not exist in %2' % 
		{iName. self}].
	^inst
    ]

    findInstanceByName: iName [
	<category: 'accessing'>
	^instances at: iName ifAbsent: [nil]
    ]

    clearUserData [
	"userData is for user to stash some data"
	<category: 'accessing'>
	userData := LookupTable new
    ]

    clearInstances [
	"instances is a dictionary of instances, keyed by the instance name"
	<category: 'accessing'>
	instances := LookupTable new
    ]

    instances [
	<category: 'accessing'>
	^instances
    ]

    userData [
	<category: 'accessing'>
	^userData
    ]

    userDataAt: key [
	<category: 'accessing'>
	^userData at: key
    ]

    userDataAt: key ifAbsent: block [
	<category: 'accessing'>
	^userData at: key ifAbsent: block
    ]

    userDataAt: key put: v [
	<category: 'accessing'>
	userData at: key put: v
    ]

    getWire: w [
	<category: 'accessing'>
	(w isKindOf: DANMWire) ifTrue: [^w].
	^self wireByName: w
    ]

    wireByName: wName [
	<category: 'accessing'>
	| w |
	w := self findWireByName: wName.
	w isNil ifTrue: [
	    self error: 'Wire by the name of %1 does not exist in %2' % 
		{wName. self}].
	^w
    ]

    removeWireByName: wName [
	<category: 'accessing'>
	| w |
	w := self findWireByName: wName.
	w notNil ifTrue: [wires removeKey: wName]
    ]

    findWireByName: wName [
	<category: 'accessing'>
	^wires at: wName ifAbsent: [nil]
    ]

    addWire: w byName: wName [
	<category: 'accessing'>
	"if there is a port by the same name, replace the wire it points to"
	| port |
	port := self findPortByName: wName.
	port notNil ifTrue: [port wire: w].
	w name: wName.
	w context: self.
	wires at: wName put: w
    ]

    addWire: w [
	<category: 'accessing'>
	"if there is a port by the same name, replace the wire it points to"
	| port wName |
	wName := w name.
	port := self findPortByName: wName.
	port notNil ifTrue: [port wire: w].
	w context: self.
	wires at: wName put: w
    ]

    addInstance: i byName: iName [
	<category: 'accessing'>
	i name: iName.
	i context: self.
	instances at: iName put: i
    ]

    addInstance: i [
	<category: 'accessing'>
	i context: self.
	instances at: i name put: i
    ]

    clearWires [
	"wires is a doctionary of wires, keyed by the wire name"
	<category: 'accessing'>
	wires := LookupTable new
    ]

    wires [
	<category: 'accessing'>
	^wires
    ]

    maxEvaluationOrder [
	<category: 'accessing'>
	^wires inject: 1 into: [:s :each | s max: each evaluationOrder + 1]
    ]

    addInstanceOf: moduleName [
	"make a unique name and add it"
	<category: 'accessing'>
	^self addInstanceOf: moduleName
	      name: (instances uniqueKeyLike: 'u_%1' % {moduleName})
    ]

    addInstanceOf: moduleName name: iName [
	"add the instance"
	<category: 'accessing'>
	| module |
	(instances includesKey: iName) ifTrue: [
	    self error: 'An instance named %1 already exists.' % {iName}].
	module := DANMLibrary moduleByName: moduleName.
	module isNil ifTrue: [
	    self error: 'Module %1 does not exist.' % {moduleName}].
	self addInstance: module byName: iName.
	^module
    ]

    removeInstanceByName: iName [
	<category: 'accessing'>
	| i |
	i := self findInstanceByName: iName.
	i notNil ifTrue: [instances removeKey: iName]
    ]

    removeInstance: i [
	<category: 'accessing'>
	i ports do: [:port | self disconnectInstance: i port: port].
	instances removeKey: i name
    ]

    elaborateAll [
	"make sure everything is elaborated. It is usually an no-op because
	 instances should be elaborated in the connection phase but there
	 could be isolated instances"
	<category: 'accessing'>
	instances do: [:each | each elaborate]
    ]

    elaborate [
	<category: 'accessing'>
	wires notNil ifTrue: [^self].
	Transcript nextPutAll: 'Elaborating schematic %1 for %2' % 
	    {self referenceName. entityName}; nl.
	DANMCurrentDesign use: self during: [
	    self
		clearUserData;
		clearWires;
		clearInstances;
		init;
		elaborateAll]
    ]

    postProcess [
	"give each instance a chance to run something after elaborate"
	<category: 'accessing'>
	instances do: [:each | each postProcess]
    ]

    pinFromString: pinString [
	"pin string is like instanceName/portName, return {instance. port}"
	<category: 'accessing'>
	pinString =~ '^([\w/]+)/(\w+)$$' 
	    ifNotMatched: [self error: 'No / found in %1' % {pinString}]
	    ifMatched: [:r | ^(self instanceByName: (r at: 1)) portByName: (r at: 2)]
    ]

    createPort: pName [
	<category: 'accessing'>
	^self createPort: pName width: 1
    ]

    createPort: pName width: w [
	<category: 'accessing'>
	| wire port |
	wire := DANMWire newNamed: pName inContext: self.
	wire width: w.
	port := DANMSchematicPort newFromWire: wire.
	self addPort: port.
	^port
    ]

    disconnectInstance: i port: p [
	<category: 'accessing'>
	| wire |
	wire := i wireOnPort: p.
	wire == nil ifFalse: [
	    i disconnectPort: p.
	    wire disconnectPort: p]
    ]

    generateVerilogTo: fn [
	<category: 'printing'>
	| fs |
	fs := (File name: fn) writeStream.
	[   self printVerilogBoilerplateOn: fs.
	    self printVerilogOn: fs ] ensure: [fs close]
    ]

    assignUniqueRefName [
	<category: 'printing'>
	| pastModules |
	pastModules := LookupTable new.
	self assignUniqueRefNameAndRecordIn: pastModules
    ]

    assignUniqueRefNameAndRecordIn: pastModules [
	<category: 'printing'>
	self uniquifiedRefName: (pastModules uniqueKeyLike: self referenceName).
	pastModules at: self uniquifiedRefName put: 1.
	instances do: 
		[:i | 
		(i isKindOf: DANMSchematic) 
		    ifTrue: [i assignUniqueRefNameAndRecordIn: pastModules]]
    ]

    generateFullVerilogTo: fn [
	"print all verilog in one file"
	<category: 'printing'>
	| fs |
	DANMCloningTemplate clearTag.
	self assignUniqueRefName.
	fs := (File name: fn) writeStream.
	[   self printVerilogBoilerplateOn: fs.
	    self printFullVerilogOn: fs ] ensure: [fs close]
    ]

    generateFullVerilogsToDir: dirName [
	"print all verilog in one dir, one module per file"

	<category: 'printing'>
	| dir |
	DANMCloningTemplate clearTag.
	self assignUniqueRefName.
	dir := File name: dirName.
	dir exists ifFalse: [dir createDirectory].
	^self printFullVerilogToDir: dirName
    ]

    generateSubModuleFullVerilogToDir: dirName [
	<category: 'printing'>
	instances do: [:i | 
	    (i isKindOf: DANMSchematic) & i isUniquified not ifTrue: [
		i shouldBlackBox ifTrue: [
		    i shouldMunge ifTrue: [i munge].
		    i generateFullVerilogTo: dirName , '/' , i referencePrintName , '.v'].
		i generateSubModuleFullVerilogToDir: dirName]]
    ]

    printVerilogBoilerplateOn: fs [
	"print some boiler headers for verilog. This could be put into a .vh file
	 if it gets longer"
	<category: 'printing'>
	fs nl; nextPutAll: '// This file is generated by DANM on %1' % {DateTime now}; nl
    ]

    printFullVerilogOn: fs [
	<category: 'printing'>
	self printVerilogOn: fs.
	instances do: [:i | 
	    i canBePrintedInLine 
		ifTrue: [ i printFullVerilogOn: fs]
		ifFalse: [
		    self skipBlackBox not & i shouldBlackBox & i isUniquified not ifTrue: [
			i printBlackBoxVerilogOn: fs]]]
    ]

    printFullVerilogToDir: dirName [
	<category: 'printing'>
	| fs |
	fs := (File name: dirName , '/' , self referencePrintName , '.v') writeStream.
	[   self printVerilogBoilerplateOn: fs.
	    self printVerilogOn: fs ] ensure: [fs close].
	instances do: [ :i |
	    i canBePrintedInLine ifTrue: [i printFullVerilogToDir: dirName]]
    ]

    printVerilogCoreOn: aStream [
	"print the verilog meat. Only synthesizable code have valid verilog code"
	<category: 'printing'>
	self canBeSynthesized ifTrue: [
	    self printWiresInVerilogOn: aStream.
	    self printInstancesInVerilogOn: aStream]
    ]

    printInstancesInVerilogOn: aStream [
	<category: 'printing'>
	instances size == 0 ifTrue: [^self].
	aStream nl; nextPutAll: '// %1 instances.' % {instances size}; nl.
	instances asSortedCollection do: [:inst |
	    inst printInstanceVerilogOn: aStream]
    ]

    printWiresInVerilogOn: aStream [
	<category: 'printing'>
	| wiresSorted |
	wiresSorted := wires asSortedCollection.
	wires size == 0 ifTrue: [^self].
	aStream nl; nextPutAll: '// %1 wires.' % {wires size}; nl.
	"this is a flag indicating it should be printed"
	wires do: [ :wire | wire tag: true].
	"may add temp wires when generating verilog"
	CurrentIdentifierDirectory use: wires copy during: [
	    wiresSorted do: [:wire | wire printVerilogOn: aStream].
	    wiresSorted do: [:wire | wire printBlockVerilogOn: aStream]]
    ]

    clearDerivedData [
	"some data is derived from more fundimental data; the derived ones are
	 kept mainly for performance reason. However, sometimes there is a need
	 to clear all that because structural change that make them stale"
	<category: 'transforming'>
	instances do: [:i | i clearDerivedData].
	wires do: [:w | w clearDerivedData]
    ]

    munge [
	<category: 'transforming'>
	Transcript nextPutAll: 'Munging schematic %1 for %2' % 
	    {self referenceName. entityName}; nl.
	self
	    flattenAll;
	    optimize.
	self shouldObfuscate ifTrue: [self obfuscate]
    ]

    obfuscate [
	"rename all instance and wires to uninteresting name"
	<category: 'transforming'>
	| newName |
	instances copy do: [ :i | 
	    newName := 'inst_' , (i name hash printString: 16).
	    [ instances includesKey: newName ] whileTrue: [
		newName := 'inst_' , (newName hash printString: 16)].
	    i renameTo: newName ].
	wires copy do: [:w | 
	    w isPort ifFalse: [
		newName := 'wire_' , (w name hash printString: 16).
		[ wires includesKey: newName ] whileTrue: [
		    newName := 'wire_' , (newName hash printString: 16)].
		w renameTo: newName]]
    ]

    flattenAll [
	<category: 'transforming'>
	self flattenAllSatisfy: [:i | i canBeFlatten]
    ]

    flattenAllForSynthesis [
	<category: 'transforming'>
	self flattenAllSatisfy: [:i | i canBeSynthesized]
    ]

    flattenAllSatisfy: testBlock [
	<category: 'transforming'>
	DANMCurrentDesign use: self during: [
	    [
		| changed |
		changed := false.
		instances do: [:ins | 
		    (testBlock value: ins) ifTrue: [
			ins flatten.
			self removeInstance: ins.
			changed := true]].
		changed ] whileTrue ].
	self clearDerivedData
    ]

    flatten [
	<category: 'transforming'>
	instances do: [:i |
	    self context addInstance: i byName: self hierNamePrefix , i name].
	wires do: [:w | w pushUpHierarchy]
    ]

    expelInstancesSatisfy: testBlock [
	"move all instances that satisfy the the block. The connectivity likely
	 need to be repaired"
	<category: 'transforming'>
	| toBeRemoved |
	toBeRemoved := OrderedCollection new.
	instances do: [:i | 
	    (testBlock value: i) ifTrue: [
		toBeRemoved add: i name.
		self context addInstance: i byName: self hierNamePrefix , i name]].
	toBeRemoved do: [:each | instances removeKey: each]
    ]

    expelWiresSatisfy: testBlock [
	"move all wires that satisfy the the block. The connectivity likely
	 need to be repaired"
	<category: 'transforming'>
	| toBeRemoved |
	toBeRemoved := OrderedCollection new.
	wires do: [:w | 
	    (testBlock value: w) ifTrue: [
		toBeRemoved add: w name.
		w pushUpHierarchy]].
	toBeRemoved do: [:each | wires removeKey: each]
    ]

    expelAllInstances [
	<category: 'transforming'>
	self expelInstancesSatisfy: [:i | true].
	self repairConnection
    ]

    wrapAll [
	"wrap everything with a thin layer."
	<category: 'transforming'>
	| wrapper |
	wrapper := DANMSchematic emptySchematic.
	self addInstance: wrapper byName: self referenceName , '_wrapper'.
	self wrapInstancesSatisfy: [:i | true] in: wrapper.
	self wrapWiresSatisfy: [:w | true] in: wrapper.
	wrapper repairConnection.
	^wrapper
    ]

    wrapInstancesSatisfy: testBlock in: wrapper [
	"push instances that satisfy the the block into wrapper.
	 The connectivity likely need to be repaired"
	<category: 'transforming'>
	| toBeRemoved |
	toBeRemoved := OrderedCollection new.
	instances do: [ :i | 
	    i ~~ wrapper & (testBlock value: i) ifTrue: [
		toBeRemoved add: i name.
		wrapper addInstance: i byName: i name]].
	toBeRemoved do: [:each | instances removeKey: each].
	^wrapper
    ]

    wrapWiresSatisfy: testBlock in: wrapper [
	"push wires that satisfy the the block into wrapper.
	 The connectivity likely need to be repaired"
	<category: 'transforming'>
	| toBeRemoved |
	toBeRemoved := OrderedCollection new.
	wires copy do: [ :w | 
	    (testBlock value: w) ifTrue: [
		toBeRemoved add: w name.
		wrapper addWire: w]].
	toBeRemoved do: [:each | wires removeKey: each].
	^wrapper
    ]

    repairConnection [
	"repair connection of myself and my context so proper seperation is
	 maintained. This is mainly used right after an expel and wrap operation.
	 One special case is a total wrap, which does not need to repair.
	 A few things will be done:
	 * if a wire is only used in either low or high level, it will be move
	 there.
	 * if a wire is used in both levels it will be splited"
	<category: 'transforming'>
	wires asArray do: [:w | w repairHierarchy: self].
	context wires asArray do: [:w | w repairHierarchy: self]
    ]

    optimize [
	<category: 'transforming'>
	| eos |
	eos := self buildEvaluationOrderSet.
	[self propagateConstant: eos] whileTrue.
	self
	    markUseful;
	    sweepGarbage;
	    clearDerivedData
    ]

    markUseful [
	"This is the mark phase of the mark and sweep fat trimming.
	 All useful stuff (those that eventually fanout to outputs) are marked"
	<category: 'transforming'>
	| set1 set2 |
	set1 := IdentitySet new.
	ports do: [:p | p isOutput ifTrue: [set1 add: p wire]].
	[ set1 size > 0 ] whileTrue: [
	    set2 := IdentitySet new.
	    set1 do: [:each | each tag: true].
	    set1 do: [:each |
		set2 addAll: (each directFanins reject: [:fanin | fanin tag notNil])].
	    set1 := set2]
    ]

    sweepGarbage [
	"This is the sweep phase of the mark and sweep fat trimming"
	<category: 'transforming'>
	| toBeDestroyed |
	toBeDestroyed := OrderedCollection new.
	wires do: [:w |
	    w tag isNil & w isExposed not ifTrue: [toBeDestroyed add: w]].
	instances do: [:i |
	    i tag notNil ifFalse: [toBeDestroyed add: i]].
	toBeDestroyed do: [:each | each destroy]
    ]

    optimizeNoTrim [
	<category: 'transforming'>
	| eos |
	eos := self buildEvaluationOrderSet.
	[self propagateConstant: eos] whileTrue.
	self clearDerivedData
    ]

    propagateConstant: eos [
	<category: 'transforming'>
	| result optimized |
	result := false.
	1 to: eos size do: [:i | 
	    optimized := self propagateConstantInSet: (eos at: i).
	    eos at: i put: IdentitySet new.
	    optimized size > 0 ifTrue: [result := true].
	    optimized do: [:each | 
		each refs do: [:ref | 
		    | w |
		    w := ref context.
		    (eos at: w evaluationOrder + 1) add: w]]].
	^result
    ]

    propagateConstantInSet: aSet [
	<category: 'transforming'>
	| newSet |
	newSet := IdentitySet new.
	aSet do: [:each | 
	    | newWire |
	    newWire := each optimize.
	    (newWire notNil and: [newWire expression isKindOf: ASTConstant]) ifTrue: [
		newSet add: newWire]].
	^newSet
    ]

    trimDangle: eos [
	<category: 'transforming'>
	| result optimized |
	result := false.
	eos size to: 1 by: -1 do: [ :i | 
	    optimized := self trimDangleInSet: (eos at: i).
	    eos at: i put: IdentitySet new.
	    optimized size > 0 ifTrue: [result := true].
	    optimized do: [ :each | 
		each directFanins do: [:w | (eos at: w evaluationOrder + 1) add: w].
		each destroy]].
	^result
    ]

    trimDangleInSet: aSet [
	<category: 'transforming'>
	^aSet select: [:each | 
	    (each expression notNil and: [each isLoaded not]) and: [each isPort not]]
    ]

    allPinNames [
	"return a set of pin names that exist in the design"
	<category: 'searching'>
	| set |
	set := Set new.
	instances do: [:each |
	    set addAll: (each ports collect: [:port | port name])].
	^set
    ]

    allUnconnectedPinsWithName: pName [
	<category: 'searching'>
	| pins |
	pins := OrderedCollection new.
	instances do: [:each | 
	    | port |
	    port := each findPortByName: pName.
	    (port ~= nil and: [(each wireOnPort: port) isNil]) ifTrue: [
		pins add: port]].
	^pins
    ]

    allUnconnectedInputPinsWithName: pName [
	<category: 'searching'>
	| pins |
	pins := OrderedCollection new.
	instances do: [:each | 
	    | port |
	    port := each findPortByName: pName.
	    (port ~= nil and: [port isInput & ((each wireOnPort: port) == nil)]) ifTrue: [
		pins add: port]].
	^pins
    ]

    buildEvaluationOrderSet [
	<category: 'statistic'>
	| orders |
	orders := OrderedCollection new.
	wires do: [:each | 
	    | o os |
	    o := each evaluationOrder + 1.
	    os := orders size.
	    os < o ifTrue: [o - os timesRepeat: [orders add: IdentitySet new]].
	    (orders at: o) add: each].
	^orders
    ]

    printDigraphOn: aStream [
	<category: 'statistic'>
	| orders |
	aStream
	    nextPutAll: 'digraph dependency {'; nl;
	    nextPutAll: 'rankdir = LR;'; nl.
	orders := OrderedCollection new.
	wires do: [:each | 
	    | o os |
	    o := each evaluationOrder + 1.
	    os := orders size.
	    each printDigraphOn: aStream.
	    os < o ifTrue: [o - os timesRepeat: [orders add: OrderedCollection new]].
	    (orders at: o) add: each].
	orders do: [:nodes | 
	    aStream nextPutAll: '{ rank = same; '.
	    nodes do: [:each | aStream nextPutAll: '"%1"; ' % {each name}].
	    aStream nextPutAll: '}'; nl].
	aStream nextPutAll: '}'; nl
    ]
]

DANMSchematic subclass: DANMModeledSchematic [
    <comment: 'I am a schematic that should not be synthesised'>
    <category: ''>

    type [
	<category: 'accessing'>
	^'model'
    ]

    canBeSynthesized [
	<category: 'accessing'>
	^false
    ]
]

DANMSchematic subclass: DANMClasslessSchematic [
    | referenceName |
    <comment: 'I am a schematic that has no class, but built on the fly'>
    <category: ''>

    reference [
	<category: 'accessing'>
	^nil
    ]

    referenceName [
	<category: 'accessing'>
	^referenceName
    ]

    referencePath [
	<category: 'accessing'>
	^nil
    ]

    name: n [
	<category: 'accessing'>
	super name: n.
	referenceName isNil ifTrue: [referenceName := n]
    ]

    elaborate [
	<category: 'accessing'>
	self
	    clearInstances;
	    clearWires
    ]
]

DANMSchematic subclass: DANMReplicatedSchematic [
    <comment: 'I am a schematic that is instantiated several times with all instances replicated'>
    <category: ''>

    DANMReplicatedSchematic class >> primary [
	<category: 'primary accessing'>
	^self subclassResponsibility
    ]

    DANMReplicatedSchematic class >> primary: p [
	<category: 'primary accessing'>
	^self subclassResponsibility
    ]

    isPrimary [
	<category: 'accessing'>
	^self = self class primary
    ]

    referencePrintName [
	"not uniqified"

	<category: 'accessing'>
	^self referenceName
    ]

    isUniquified [
	<category: 'accessing'>
	^(self = self class primary) not
    ]

    canBeFlatten [
	<category: 'accessing'>
	^false
    ]

    elaborate [
	<category: 'accessing'>
	wires notNil ifTrue: [^self].
	self class primary isNil ifTrue: [
	    super elaborate.
	    self class primary: self.
	    ^self].
	Transcript nextPutAll: 'Copying schematic %1 for %2' % 
	    {self referenceName. entityName}; nl.
	self
	    clearUserData;
	    clearWires;
	    clearInstances;
	    copyFrom: self class primary
    ]

    generateFullVerilogTo: fn [
	"only primt primary one"
	<category: 'printing'>
	self isPrimary ifTrue: [super generateFullVerilogTo: fn].
	^self
    ]

    generateFullVerilogsToDir: dirName [
	"only primt primary one"
	<category: 'printing'>
	self isPrimary ifTrue: [super generateFullVerilogsToDir: dirName].
	^self
    ]

    printFullVerilogOn: fs [
	"only primt primary one"
	<category: 'printing'>
	self isPrimary ifTrue: [super printFullVerilogOn: fs].
	^self
    ]

    printFullVerilogToDir: dirName [
	"only primt primary one"
	<category: 'printing'>
	self isPrimary ifTrue: [super printFullVerilogToDir: dirName].
	^self
    ]

    generateSubModuleFullVerilogToDir: dirName [
	"only primt primary one"
	<category: 'printing'>
	self isPrimary ifTrue: [super generateSubModuleFullVerilogToDir: dirName].
	^self
    ]
]
