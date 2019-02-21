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

DANMEntity subclass: DANMTemplate [
    | reference srcPath |
    <comment: nil>
    <category: 'DANM'>

    DANMTemplate class >> newNamed: n fromPath: p [
	<category: 'instance creation'>
	^(super newNamed: n) srcPath: p
    ]

    srcPath [
	<category: 'accessing'>
	^srcPath
    ]

    srcPath: p [
	<category: 'accessing'>
	srcPath := p
    ]

    printOn: aStream [
	<category: 'producing'>
	aStream nextPutAll: entityName
    ]

    produce [
	<category: 'producing'>
	self subclassResponsibility
    ]
]

DANMTemplate subclass: DANMCloningTemplate [
    | reference |
    <comment: 'I am used to reproduce real module used in a schematic by cloning a 
reference box'>
    <category: 'DANM'>

    DANMCloningTemplate class >> newNamed: n fromPath: p ofReference: r [
	<category: 'instance creation'>
	^(super newNamed: n)
	    srcPath: p;
	    reference: r;
	    name: r name
    ]

    DANMCloningTemplate class >> clearTag [
	<category: 'tagging'>
	self allInstancesDo: [:each | each clearTag]
    ]

    reference [
	<category: 'accessing'>
	^reference
    ]

    reference: ref [
	<category: 'accessing'>
	ref reference: self.
	reference := ref
    ]

    produce [
	<category: 'producing'>
	^reference copy
    ]

    clearTag [
	<category: 'printing'>
	tag := nil
    ]

    returnThenSetTag [
	"se the tag then return old tag"
	<category: 'printing'>
	| t |
	t := tag.
	tag := true.
	^t
    ]

    printTextOn: aStream [
	<category: 'printing'>
	| s |
	self returnThenSetTag notNil ifTrue: [^self].
	s := (File name: srcPath) readStream.
	[s nextPutAllOn: aStream] ensure: [s close]
    ]
]

DANMTemplate subclass: DANMClassicTemplate [
    <comment: 'I am used to reproduce real module by instanciating a class'>
    <category: ''>
    produce [
	<category: 'producing'>
	| className class |
	className := ('DANMSchematic_' , self name) asSymbol.
	class := (nil metaclassFor: className) instanceClass.
	^class new reference: self
    ]
]

Object subclass: DANMLibrary [
    | library topModule paths stFiles vFiles pathIndex |
    <category: 'DANM'>
    <comment: 'I am a singleton class that does library look up'>
    sharedLibrary := nil.

    DANMLibrary class >> sharedLibrary [
	<category: 'accessing'>
	sharedLibrary isNil ifTrue: [ sharedLibrary := self new init ].
	^sharedLibrary
    ]

    DANMLibrary class >> clearLibrary [
	<category: 'accessing'>
	sharedLibrary := nil
    ]

    DANMLibrary class >> addPath: p [
	<category: 'accessing'>
	self sharedLibrary addPath: p
    ]

    DANMLibrary class >> paths [
	<category: 'accessing'>
	^self sharedLibrary paths
    ]

    DANMLibrary class >> moduleByName: mName [
	<category: 'accessing'>
	^self sharedLibrary moduleByName: mName
    ]

    DANMLibrary class >> addModule: mod [
	<category: 'accessing'>
	self sharedLibrary addModule: mod
    ]

    DANMLibrary class >> topModule: mod [
	<category: 'accessing'>
	self sharedLibrary topModule: mod
    ]

    DANMLibrary class >> topModule [
	<category: 'accessing'>
	^self sharedLibrary topModule
    ]

    DANMLibrary class >> size [
	<category: 'accessing'>
	^self sharedLibrary size
    ]

    DANMLibrary class >> list [
	<category: 'accessing'>
	^self sharedLibrary list
    ]

    DANMLibrary class >> moduleByName: mName fromPaths: ps [
	<category: 'accessing'>
	| mod |
	sharedLibrary := self new init.
	sharedLibrary paths: ps.
	mod := (sharedLibrary moduleByName: mName)
		    name: 'top';
		    elaborate.
	sharedLibrary := nil.
	^mod
    ]

    init [
	<category: 'accessing'>
	paths := OrderedCollection new.
	library := LookupTable new.
	stFiles := LookupTable new.
	vFiles := LookupTable new.
	pathIndex := 0
    ]

    addPath: p [
	<category: 'accessing'>
	paths add: p
    ]

    paths [
	<category: 'accessing'>
	^paths asArray
    ]

    paths: ps [
	<category: 'accessing'>
	^paths := ps asOrderedCollection
    ]

    moduleByName: mName [
	<category: 'accessing'>
	| m |
	m := library at: mName ifAbsent: [nil].
	m == 0 ifTrue: [
	    "the module is still loading, so this is a illegal recursion"
	    self error: 'Circular reference on module %1' % {mName} ].
	m notNil ifTrue: [ ^m produce ].
	m := self loadModuleByName: mName.
	self addModule: m.
	^m produce
    ]

    addModule: mod [
	<category: 'accessing'>
	library at: mod name put: mod
    ]

    topModule: mod [
	<category: 'accessing'>
	mod name: 'top'.
	mod elaborate.
	topModule := mod
    ]

    topModule [
	<category: 'accessing'>
	^topModule
    ]

    size [
	<category: 'accessing'>
	^library size
    ]

    list [
	<category: 'accessing'>
	^library printString
    ]

    loadModuleByName: mName [
	"Load a module from either st schematic or verilog blackbox"
	<category: 'loading'>
	"This is a tag indicating we are loading this module. Wil be overwritten
	 after the module is successfully loaded"
	| m |
	library at: mName put: 0.
	[   m := self tryLoadModuleByName: mName.
	    m isNil & self searchMorePath ] whileTrue.
	m isNil ifTrue: [ m := self tryLoadBlackBoxModuleByName: mName ].
	m isNil ifTrue: [
	    self error: 'The module %1 is not found in search paths: %2' %
		{mName. self paths} ].
	^m
    ]

    tryLoadBlackBoxModuleByName: mName [
	<category: 'loading'>
	| fileName m fs |
	fileName := vFiles at: mName ifAbsent: [nil].
	fileName notNil ifTrue: [
	    Transcript nextPutAll: 'Loading blackbox %1 from %2' % {mName. fileName}; nl.
		fs := Tokenizer on: (File name: fileName) readStream.
		[m := DANMBlackBox parseVerilog: fs] ensure: [fs close].
		^DANMCloningTemplate 
		    newNamed: mName
		    fromPath: fileName
		    ofReference: m ].
	^nil
    ]

    tryLoadModuleByName: mName [
	<category: 'loading'>
	| fileName m className class |
	fileName := stFiles at: mName ifAbsent: [nil].
	fileName notNil ifTrue: [
	    className := ('DANMSchematic_' , mName) asSymbol.
	    class := (nil metaclassFor: className) instanceClass.
	    class isNil ifTrue: [
		Transcript nextPutAll: 'Loading schematic %1 from %2' % {mName. fileName}; nl.
		[FileStream fileIn: fileName] ifError: [
		    self error: '%1 cannot be loaded' % {fileName} ]].
	    class := (nil metaclassFor: className) instanceClass.
	    class isNil ifTrue: [
		self error: 'Error: class %1 is not defined in %2' % {className. fileName}].
	    ^DANMClassicTemplate newNamed: mName fromPath: fileName ].
	^nil
    ]

    searchMorePath [
	<category: 'loading'>
	| dir |
	pathIndex < paths size ifFalse: [^false].
	dir := File name: (paths at: pathIndex + 1).
	(dir exists and: [dir isDirectory]) ifFalse: [
	    self error: 'the dir %1 does not exist!' % {dir}; nl ].
	dir namesDo: [:name | 
	    | fullname |
	    fullname := FilePath append: name to: dir name.
	    name =~ '^(\w+)\.st$$' ifMatched: [ :result | 
		(stFiles includesKey: (result at: 1)) 
		    ifFalse: [ stFiles at: (result at: 1) put: fullname ]].
	    name =~ '^(\w+)\.v$$' ifMatched: [:result | 
		(vFiles includesKey: (result at: 1)) 
		    ifFalse: [ vFiles at: (result at: 1) put: fullname ]]].
	pathIndex := pathIndex + 1.
	^true
    ]
]
