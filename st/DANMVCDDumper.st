Object subclass: #DANMDirectoryTree
    instanceVariableNames: 'name subDirs objects'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMDirectoryTree comment:
    'I am a auxillary class that represent a directory tree, each node has a 
name and can contain objects and sub nodes'!

!DANMDirectoryTree class methodsFor: 'instance creation'!

new: n
    ^super new 
        initWithName: n!
!

!DANMDirectoryTree methodsFor: 'accessing'!

initWithName: n
    name := n.
    objects := LookupTable new.
    subDirs := LookupTable new!

objects
    ^objects!

subDirs 
    ^subDirs!

name
    ^name!

at: n put: o
    |index dirName dir|
    index := n indexOf: $/.
    index == 0 ifTrue: [ 
        objects at: n put: o.
        ^self ].
    dirName := n copyFrom: 1 to: index - 1.
    (subDirs includesKey: dirName) 
        ifTrue: [ dir := subDirs at: dirName ]
        ifFalse: [
            dir := DANMDirectoryTree new: dirName.
            subDirs at: dirName put: dir].
    dir at: (n copyFrom: index + 1) put: o!

at: n
    |index dir|
    index := n indexOf: '/'.
    index == 0 ifTrue: [ 
        ^objects at: n ].
    dir := subDirs at: (n copyFrom: 1 to: index - 1).
    ^dir at: (n copyFrom: index + 1)!
!

Object subclass: #DANMVCDDumper
    instanceVariableNames: 'sim aliasGenerator fs'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMVCDDumper comment:
    'I am a auxillary object that implements VCD dumping for DANMSimulator'!

!DANMVCDDumper class methodsFor: 'instance creation'!

on: s
    ^super new initWith: s!
!

!DANMVCDDumper methodsFor: 'basic'!

initWith: s
    sim := s.
    fs := (File name: '%1.vcd' % {sim dut referenceName}) writeStream.
    sim setCallbackFrom: self on: #SimulationSettled do: [ :sim |
        self printHead ].
    sim setCallbackFrom: self on: #SimulationStepEnded do: [ :sim |
        self printTimeStep ].
    sim setCallbackFrom: self on: #SimulationEnded do: [ :sim |
        self close ].
    sim setCallbackFrom: self on: #SimulationResumed do: [ :sim |
        self reopen ].
    aliasGenerator := self makeAliasGenerator!

makeAliasGenerator
    ^ Generator on: [ :gen |
        |arr i|
        "valid alias are string of char from ASCII 33 to 126"
        arr := OrderedCollection with: 33.
        [
            gen yield: (arr collect: [ 
                :each | Character asciiValue: each ]) asString.
            i := arr size.
            [ i>0 and: [ (arr at: i)==126 ] ] whileTrue: [
                arr at: i put: 33.
                i := i - 1 ].
            i == 0 
                ifTrue: [ arr addFirst: 33 ]
                ifFalse: [ arr at: i put: ((arr at: i) + 1) ]] repeat ]!

reopen
    fs := (File name: '%1.vcd' % {sim dut referenceName}) 
        open: FileStream append!
    
close
    fs close!
!

!DANMVCDDumper methodsFor: 'vcd printing'!

printHead
    |topScope|
    fs 
        nextPutAll: '$date'; nl;
        tab; nextPutAll: DateTime now vcdString; nl;
        nextPutAll: '$end'; nl;
        nextPutAll: '$version'; nl;
        tab; nextPutAll: 'DANM Simulator'; nl;
        nextPutAll: '$end'; nl;
        nextPutAll: '$timescale'; nl;
        tab; nextPutAll: '1ns'; nl;
        nextPutAll: '$end'; nl.
    topScope := self buildScopes.
    self printScope: topScope.
    fs nextPutAll: '$enddefinitions $end'; nl.
    self printInitValues!

buildScopes
    |topScope|
    topScope := DANMDirectoryTree new: sim dut referenceName.
    sim wires do: [ :w |
        w tag: aliasGenerator next.
        topScope at: w name put: w.
        w aka do: [ :n | topScope at: n put: w ]].
    ^topScope! 
                
printTimeStep
    fs 
        nextPut: $#;
        nextPutAll: sim currentTime printString;
        nl.
    sim changeSet do: [ :w | self printWire: w ]!

printWire: w
    " faster than:    
     fs nextPutAll: 'b%1 %2' % {w valueAsBinaryString. w tag}; nl!"
    fs nextPut: $b.
    w printBinaryValueOn: fs.
    fs 
        space;
        nextPutAll: w tag;
        nl!
    
printInitValues
    fs 
        nextPutAll: '#0'; nl;
        nextPutAll: '$dumpvars'; nl.
    sim wires do: [ :w |  self printWire: w ].
    fs nextPutAll: '$end'; nl! 

printScope: scope
    fs nextPutAll: '$scope module %1 $end' % {scope name}; nl.
    scope objects keysAndValuesDo: [ :name :w |
        fs nextPutAll: '$var reg %1 %2 %3 $end' % 
            {w width. w tag. w vcdNameFrom: name}; nl ].
    scope subDirs do: [ :s |
        self printScope: s ].
    fs nextPutAll: '$upscope $end'; nl!
!

!DateTime methodsFor: 'VCD printing'!

vcdString
    |d|
    d := self asDate. 
    ^'%1 %2 %3 %4 %5' % {d dayOfWeekAbbreviation asString. 
                         d monthAbbreviation asString.
                         d day. self asTime. d year}! 
! 

!DANMWire methodsFor: 'VCD printing'!

vcdNameFrom: n
    self width == 1 ifTrue: [ ^n ].
    ^'%1[%2:0]' % {n. self width - 1}!
!
