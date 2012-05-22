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

DynamicVariable subclass: #DANMCurrentDesign
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMCurrentDesign comment:
    ''!

DANMBlackBox subclass: #DANMSchematic
             instanceVariableNames: 'instances wires userData generatedNames'
             classVariableNames: 'htmlRoot'
             poolDictionaries: ''
             category: 'DANM'!

DANMSchematic comment: 'I am a module that is modeled by a schematic 
containing instances of modules and the wires among them.'!

!DANMSchematic class methodsFor: 'accessing'!

htmlRoot
    ^htmlRoot!

htmlRoot: str
    htmlRoot := str!

emptySchematic
    ^DANMEmptyTemplate factory produce!
!

!DANMSchematic methodsFor: 'init'!

init
    "this method should not be called unless the init method of the 
     schematic is wrong"
    self error: '%1 cannot be elaborated' % {entityName}!
!

!DANMSchematic methodsFor: 'accessing'!

hierNamePrefix
    "return the name prefix when hier is flattened. In most cases the name 
     and slash should be used; however wrappers are invisible"
    (reference isKindOf: DANMEmptyTemplate) ifFalse: [ ^entityName, '/' ].
    ^''!

referencePrintName
    |prefix|
    "do not uniqify if not printed inline"
    self canBePrintedInLine ifFalse: [ ^self referenceName ].
    self context isNil ifTrue: [ ^self uniquifiedRefName ].
    prefix := Smalltalk getenv: 'MODULE_PREFIX'.
    prefix isNil ifTrue: [ ^self uniquifiedRefName ].
    ^prefix, self uniquifiedRefName!

isUniquified
    ^self uniquifiedRefName ~= self referenceName!

uniqueWireNameLike: wName
    |salt newName|
    generatedNames isNil ifTrue: [
        generatedNames := LookupTable new ].
    newName := wires uniqueKeyLike: wName.
    generatedNames at: newName put: 1.
    ^newName!

containsGeneratedName: wName
    generatedNames isNil ifTrue: [ ^false ].
    ^generatedNames includesKey: wName!

isFlat
    "a flat schematic does not contains any instance"
    instances isNil ifTrue: [ ^false ].
    ^(instances size > 0)!

canBeFlatten
    "whether I can be flatten. schematic can"
    ^true!

canBePrintedInLine
    "whether I can be printed as inline verilog. For schematic the printing
     will be recursive. Any schematic that do not want to be printed inline
     should override this method."
    self shouldBlackBox ifTrue: [ ^false ]. 
    self shouldNotPrint ifTrue: [ ^false ]. 
    ^true!

ports
    wires isNil ifTrue: [ self elaborate ].
    ^super ports!

type
    ^'schematic'!

instanceByName: iName
    |inst|
    inst := self findInstanceByName: iName.
    inst isNil ifTrue: [
        self error: ('Instance by the name of %1 does not exist in %2' % 
                         {iName. self}) ].
    ^inst!

findInstanceByName: iName
    ^instances at: iName ifAbsent: [ nil ]!

clearUserData
    "userData is for user to stash some data"
    userData := LookupTable new!

clearInstances
    "instances is a dictionary of instances, keyed by the instance name"
    instances := LookupTable new!

instances
    ^instances!

userData
    ^userData!

userDataAt: key
    ^userData at: key!

userDataAt: key ifAbsent: block
    ^userData at: key ifAbsent: block!

userDataAt: key put: v
    userData at: key put: v!
    
getWire: w
    (w isKindOf: DANMWire) ifTrue: [ ^w ].
    ^self wireByName: w!

wireByName: wName
    |w|
    w := self findWireByName: wName.
    w isNil ifTrue: [ 
        self error: ('Wire by the name of %1 does not exist in %2' % 
                         {wName. self}) ].
    ^w!

removeWireByName: wName
    |w|
    w := self findWireByName: wName.
    w notNil ifTrue: [ wires removeKey: wName ]!

findWireByName: wName
    ^wires at: wName ifAbsent: [ nil ]!

findInstanceByName: iName
    ^instances at: iName ifAbsent: [ nil ]!

addWire: w byName: wName
    |port|
    "if there is a port by the same name, replace the wire it points to"
    port := self findPortByName: wName.
    port notNil ifTrue: [ port wire: w ].
    w name: wName.
    w context: self.
    wires at: wName put: w!

addWire: w
    |port wName|
    "if there is a port by the same name, replace the wire it points to"
    wName := w name.
    port := self findPortByName: wName.
    port notNil ifTrue: [ port wire: w ].
    w context: self.
    wires at: wName put: w!

addInstance: i byName: iName
    i name: iName.
    i context: self.
    instances at: iName put: i!

addInstance: i
    i context: self.
    instances at: i name put: i!

clearWires
    "wires is a doctionary of wires, keyed by the wire name"
    wires := LookupTable new!

wires
    ^wires!

maxEvaluationOrder
    ^wires inject: 1 into: [ :s :each | s max: each evaluationOrder + 1 ]!

addInstanceOf: moduleName
    "make a unique name and add it"
    |iName|
    iName := 'u_%1' % {moduleName}.
    iName := instances uniqueKeyLike: iName.
    ^self addInstanceOf: moduleName name: iName!

addInstanceOf: moduleName name: iName
    "add the instance"
    |module|
    (instances includesKey: iName) ifTrue: [
        self error: 'An instance named %1 already exists.' % {iName} ].
    module := DANMLibrary moduleByName: moduleName.
    module isNil ifTrue: [
        self error: ('Module %1 does not exist.' % {moduleName}) ].
    self addInstance: module byName: iName.
    ^module!

removeInstanceByName: iName
    |i|
    i := self findInstanceByName: iName.
    i notNil ifTrue: [ instances removeKey: iName ]!

removeInstance: i
    i ports do: [ :port |
        self disconnectInstance: i port: port ].
    instances removeKey: (i name)!

elaborateAll
    "make sure everything is elaborated. It is usually an no-op because
     instances should be elaborated in the connection phase but there
     could be isolated instances"
    instances do: [ :each | each elaborate ]!

elaborate
    |old|
    wires notNil ifTrue: [ ^self ].
    Transcript 
        nextPutAll: 'Elaborating schematic %1 for %2' % {self referenceName.
                                                         entityName}; nl.
    DANMCurrentDesign use: self during: [
        self
            clearUserData;
            clearWires;
            clearInstances;
            init;
            elaborateAll ]!

pinFromString: pinString
"pin string is like instanceName/portName, return {instance. port}"
    pinString =~ '^([\w/]+)/(\w+)$$'
        ifNotMatched: [ self error: ('No / found in %1' % {pinString}) ]
        ifMatched: [:r |
            ^ (self instanceByName: (r at: 1)) portByName: (r at: 2) ]!
 
createPort: pName
    ^self createPort: pName width: 1!

createPort: pName width: w
    |wire port|
    wire := DANMWire newNamed: pName inContext: self.
    wire width: w.
    port := DANMSchematicPort newFromWire: wire.
    self addPort: port.
    ^port!

disconnectInstance: i port: p
    |wire|
    wire := i wireOnPort: p.
    (wire == nil) ifFalse: [
        i disconnectPort: p.
        wire disconnectPort: p ]!
!

!DANMSchematic methodsFor: 'printing'!

generateVerilogTo: fn
    |fs|
    fs := (File name: fn) writeStream.
    [ 
        self printVerilogBoilerplateOn: fs.
        self printVerilogOn: fs ] ensure: [ fs close ]!

assignUniqueRefName
    |pastModules|
    pastModules := LookupTable new.
    self assignUniqueRefNameAndRecordIn: pastModules!

assignUniqueRefNameAndRecordIn: pastModules
    self uniquifiedRefName: 
        (pastModules uniqueKeyLike: self referenceName).
    pastModules at: self uniquifiedRefName put: 1.
    instances do: [ :i |
        (i isKindOf: DANMSchematic) ifTrue: [
            i assignUniqueRefNameAndRecordIn: pastModules ]]!

generateFullVerilogTo: fn
    "print all verilog in one file"
    |fs|
    DANMCloningTemplate clearTag.
    self assignUniqueRefName.
    fs := (File name: fn) writeStream.
    [ 
        self printVerilogBoilerplateOn: fs.
        self printFullVerilogOn: fs ] ensure: [ fs close ]!

generateFullVerilogsToDir: dirName
    "print all verilog in one dir, one module per file"
    |dir|
    DANMCloningTemplate clearTag.
    self assignUniqueRefName.
    dir := File name: dirName.
    (dir exists) ifFalse: [
        dir createDirectory ].
    ^self printFullVerilogToDir: dirName!

printVerilogBoilerplateOn: fs
"print some boiler headers for verilog. This could be put into a .vh file 
if it gets longer"
    fs nextPutAll: '
// This file is generated by DANM on %1

`define ASSERT(condition, hier) always @(condition) \
   if (!condition) begin \
      $display("Assertion failure: condition in hier"); \
      #100; \
      $finish; \
   end
' % {DateTime now}!
    
printFullVerilogOn: fs
    self printVerilogOn: fs.
    instances do: [ :i |
        i canBePrintedInLine 
            ifTrue: [ i printFullVerilogOn: fs ]
            ifFalse: [ 
                i shouldBlackBox & 
                    i isUniquified not ifTrue: [
                        i printBlackBoxVerilogOn: fs ]]]!

printFullVerilogToDir: dirName
    |fs|
    fs := (File name: dirName, '/', self referencePrintName, '.v') 
        writeStream.
    [ self printVerilogBoilerplateOn: fs.
      self printVerilogOn: fs ] 
        ensure: [ fs close ].
    instances do: [ :i |
        i canBePrintedInLine ifTrue: [ i printFullVerilogToDir: dirName ]]!

printVerilogCoreOn: aStream
    "print the verilog meat. Only synthesizable code have valid verilog code"
    self canBeSynthesized ifTrue: [
        self printWiresInVerilogOn: aStream.
        self printInstancesInVerilogOn: aStream ]!

printInstancesInVerilogOn: aStream
    instances size == 0 ifTrue: [ ^self ].
    aStream nl;
        nextPutAll: '// %1 instances.' % {instances size}; nl.
    instances asSortedCollection do: [ :inst |
        inst printInstanceVerilogOn: aStream ]!

printWiresInVerilogOn: aStream
    |wiresSorted|
    wiresSorted := wires asSortedCollection.
    wires size == 0 ifTrue: [ ^self ].
    aStream nl;
        nextPutAll: '// %1 wires.' % {wires size}; nl.
    wires do: [ :wire |
        "this is a flag indicating it should be printed"
        wire tag: true ].
    "may add temp wires when generating verilog"
    CurrentIdentifierDirectory use: wires copy during: [
    wiresSorted do: [ :wire |
        wire printVerilogOn: aStream ].
    wiresSorted do: [ :wire |
        wire printBlockVerilogOn: aStream ]]!
!

!DANMSchematic methodsFor: 'transforming'!

clearDerivedData
"some data is derived from more fundimental data; the derived ones are 
 kept mainly for performance reason. However, sometimes there is a need 
 to clear all that because structural change that make them stale"
    instances do: [ :i | i clearDerivedData ].
    wires do: [ :w | w clearDerivedData ]!

flattenAll
    self flattenAllSatisfy: [ :i | i canBeFlatten ]!

flattenAllForSynthesis
    self flattenAllSatisfy: [ :i | i canBeSynthesized ]!

flattenAllSatisfy: testBlock
    DANMCurrentDesign use: self during: [
        [ |changed|
            changed := false.
            instances do: [ :ins |
                (testBlock value: ins) ifTrue: [
                    ins flatten.
                    self removeInstance: ins.
                    changed := true ]].
            changed ] whileTrue ].
    self clearDerivedData!

flatten
    instances do: [ :i | 
        self context addInstance: i byName: (self hierNamePrefix, i name) ].
    wires do: [ :w | 
        w pushUpHierarchy ]!

expelInstancesSatisfy: testBlock
    "move all instances that satisfy the the block. The connectivity likely
     need to be repaired"
    |toBeRemoved|
    toBeRemoved := OrderedCollection new.
    instances do: [ :i |
        (testBlock value: i) ifTrue: [ 
            toBeRemoved add: i name.
            self context addInstance: i 
                         byName: (self hierNamePrefix, i name) ]].
    toBeRemoved do: [ :each | instances removeKey: each ]!
    
expelWiresSatisfy: testBlock
    "move all wires that satisfy the the block. The connectivity likely
     need to be repaired"
    |toBeRemoved|
    toBeRemoved := OrderedCollection new.
    wires do: [ :w |
        (testBlock value: w) ifTrue: [
            toBeRemoved add: w name.
            w pushUpHierarchy ]].
    toBeRemoved do: [ :each | wires removeKey: each ]!

expelAllInstances
    self expelInstancesSatisfy: [ :i | true ].
    self repairConnection!

wrapAll
    "wrap everything with a thin layer."
    |wrapper|
    wrapper := DANMSchematic emptySchematic.
    self addInstance: wrapper byName: self referenceName, '_wrapper'.
    self wrapInstancesSatisfy: [ :i | true ] in: wrapper.
    self wrapWiresSatisfy: [ :w | true ] in: wrapper.
    "this is a specail case in tat everything is wrapped, so there is no need 
     to repair"
    ^wrapper!
 
wrapInstancesSatisfy: testBlock in: wrapper
    "push instances that satisfy the the block into wrapper.
     The connectivity likely need to be repaired"
    |toBeRemoved|
    toBeRemoved := OrderedCollection new.
    instances do: [ :i |
        i ~~ wrapper & (testBlock value: i) ifTrue: [
            toBeRemoved add: i name.
            wrapper addInstance: i byName: i name ]].
    toBeRemoved do: [ :each | instances removeKey: each ].
    ^wrapper!

wrapWiresSatisfy: testBlock in: wrapper
    "push wires that satisfy the the block into wrapper.
     The connectivity likely need to be repaired"
    |toBeRemoved|
    toBeRemoved := OrderedCollection new.
    wires do: [ :w |
        (testBlock value: w) ifTrue: [
            "Ports cannot be removed in wrapping"
            w isPort ifFalse: [ toBeRemoved add: w name ]. 
            w pushDownHierarchy: wrapper ]].
    toBeRemoved do: [ :each | wires removeKey: each ].
    ^wrapper!

repairConnection
    "repair connection of myself and my context so proper seperation is 
     maintained. This is mainly used right after an expel and wrap operation.
     One special case is a total wrap, which does not need to repair.
     A few things will be done:
     * if a wire is only used in either low or high level, it will be move 
     there. 
     * if a wire is used in both levels it will be splited"
    wires asArray do: [ :w | w repairHierarchy: self ].
    context wires asArray do: [ :w | w repairHierarchy: self ]!

optimize
    |eos|
    eos := self buildEvaluationOrderSet.
    [ self propagateConstant: eos ] whileTrue.
    self 
        markUseful;
        sweepGarbage;
        clearDerivedData!

markUseful
    "This is the mark phase of the mark and sweep fat trimming. 
     All useful stuff (those that eventually fanout to outputs) are marked"
    |set1 set2|
    set1 := IdentitySet new.
    ports do: [ :p |
        p isOutput ifTrue: [ set1 add: p wire ]].
    [set1 size > 0] whileTrue: [
        set2 := IdentitySet new.
        set1 do: [ :each | each tag: true ].
        set1 do: [ :each |
            set2 addAll: (each directFanins reject: [ :fanin |
                fanin tag notNil ])].
        set1 := set2 ]!

sweepGarbage
    "This is the sweep phase of the mark and sweep fat trimming"
    |toBeDestroyed|
    toBeDestroyed := OrderedCollection new.
    wires do: [ :w |
        (w tag notNil) ifFalse: [ toBeDestroyed add: w ]].
    instances do: [ :i |
        (i tag notNil) ifFalse: [ toBeDestroyed add: i ]].
    toBeDestroyed do: [ :each | each destroy ]!
    
optimizeNoTrim
    |eos|
    eos := self buildEvaluationOrderSet.
    [ self propagateConstant: eos ] whileTrue.
    self clearDerivedData!

propagateConstant: eos
    |result optimized|
    result := false.
    1 to: eos size do: [ :i |
        optimized := self propagateConstantInSet: (eos at: i).
        eos at: i put: IdentitySet new.
        optimized size > 0 ifTrue: [ result := true ].
        optimized do: [ :each |
            each refs do: [ :ref |
                |w|
                w := ref context.
                (eos at: (w evaluationOrder + 1)) add: w ]]].
    ^result!

propagateConstantInSet: aSet
    |newSet|
    newSet := IdentitySet new.
    aSet do: [ :each |
        |newWire|
        newWire := each optimize.
        (newWire notNil and: [ newWire expression isKindOf: ASTConstant ]) 
            ifTrue: [ newSet add: newWire ]].
    ^newSet!

trimDangle: eos
    |result optimized|
    result := false.
    eos size to: 1 by: -1 do: [ :i |
        optimized := self trimDangleInSet: (eos at: i).
        eos at: i put: IdentitySet new.
        optimized size > 0 ifTrue: [ result := true ].
        optimized do: [ :each |
            each directFanins do: [ :w |
                (eos at: (w evaluationOrder + 1)) add: w ].
            each destroy ]].
    ^result!

trimDangleInSet: aSet
    ^ aSet select: [ :each |
        (each expression notNil and: [ each isLoaded not ])
            and: [ each isPort not ]]!
!

!DANMSchematic methodsFor: 'searching'!

allPinNames
    "return a set of pin names that exist in the design"
    |set|
    set := Set new.
    instances do: [ :each |
        set addAll: (each ports collect: [ :port | 
            port name])].
    ^set!

allUnconnectedPinsWithName: pName
    |pins|
    pins := OrderedCollection new.
    instances do: [ :each |
        |port|
        port := each findPortByName: pName.
        (port ~= nil and: [ (each wireOnPort: port) isNil ]) ifTrue: [ 
            pins add: port ]].
    ^pins!

allUnconnectedInputPinsWithName: pName
    |pins|
    pins := OrderedCollection new.
    instances do: [ :each |
        |port|
        port := each findPortByName: pName.
        (port ~= nil and: [ 
            port isInput & ((each wireOnPort: port) == nil) ]) ifTrue: [ 
                pins add: port ]].
    ^pins!
!

!DANMSchematic methodsFor: 'statistic'!

buildEvaluationOrderSet
    |orders|
    orders := OrderedCollection new.
    wires do: [ :each |
        |o os|
        o := each evaluationOrder + 1.
        os := orders size.
        os < o ifTrue: [
            o - os timesRepeat: [ orders add: IdentitySet new ]].
        (orders at: o) add: each ].
    ^orders!

printDigraphOn: aStream
    |orders|
    aStream 
        nextPutAll: 'digraph dependency {'; nl;
        nextPutAll: 'rankdir = LR;'; nl.
    orders := OrderedCollection new.
    wires do: [ :each |
        |o os|
        o := each evaluationOrder + 1.
        os := orders size.
        each printDigraphOn: aStream.
        os < o ifTrue: [
            o - os timesRepeat: [ orders add: OrderedCollection new ]].
        (orders at: o) add: each ].
    orders do: [ :nodes |
        aStream nextPutAll: '{ rank = same; '.
        nodes do: [ :each |
            aStream nextPutAll: '"%1"; ' % {each name} ].
        aStream nextPutAll: '}'; nl ].
    aStream nextPutAll: '}'; nl!
!

DANMSchematic subclass: #DANMModeledSchematic
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMModeledSchematic comment:
    'I am a schematic that should not be synthesised'!

!DANMModeledSchematic methodsFor: 'accessing'!

type
    ^'model'!

canBeSynthesized
    ^false! 
!
