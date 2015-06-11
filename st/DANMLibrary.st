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

DANMEntity subclass: #DANMTemplate
    instanceVariableNames: 'reference srcPath'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'DANM'!

!DANMTemplate methodsFor: 'accessing'!

srcPath
    ^srcPath!

srcPath: p
    srcPath := p!
!

!DANMTemplate class methodsFor: 'instance creation'!

newNamed: n fromPath: p
    ^(super newNamed: n) 
        srcPath: p!
!

!DANMTemplate methodsFor: 'producing'!

printOn: aStream
    aStream nextPutAll: entityName!        

produce
    self subclassResponsibility!
!

DANMTemplate subclass: #DANMCloningTemplate
    instanceVariableNames: 'reference'
    classVariableNames: ''
    poolDictionaries: ''
    category: 'DANM'!

DANMCloningTemplate comment:
    'I am used to reproduce real module used in a schematic by cloning a 
reference box'!

!DANMCloningTemplate class methodsFor: 'instance creation'!

newNamed: n fromPath: p ofReference: r
    ^(super newNamed: n) 
        srcPath: p;
        reference: r;
        name: r name!
!

!DANMCloningTemplate class methodsFor: 'tagging'!

clearTag
    self allInstancesDo: [ :each |
        each clearTag ]!
!

!DANMCloningTemplate methodsFor: 'accessing'!

reference
    ^reference!
 
reference: ref
    ref reference: self.
    reference := ref!
!

!DANMCloningTemplate methodsFor: 'producing'!

produce
    ^reference copy!
!

!DANMCloningTemplate methodsFor: 'printing'!

clearTag
    tag := nil!

returnThenSetTag
    "se the tag then return old tag"
    |t| 
    t := tag.
    tag := true.
    ^t!

printTextOn: aStream
    |s|
    self returnThenSetTag notNil ifTrue: [ ^self ].
    s := (File name: srcPath) readStream.
    [ s nextPutAllOn: aStream ] ensure: [s close ]!
!

DANMTemplate subclass: #DANMClassicTemplate
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMClassicTemplate comment:
    'I am used to reproduce real module by instanciating a class'!

!DANMClassicTemplate methodsFor: 'producing'!

produce
    |className class|
    className := ('DANMSchematic_',self name) asSymbol.
    class := (nil metaclassFor: className) instanceClass.
    ^class new reference: self!
!

Object subclass: #DANMLibrary
       instanceVariableNames: 'library topModule paths 
stFiles vFiles pathIndex'
       classVariableNames: 'sharedLibrary'
       poolDictionaries: ''
       category: 'DANM'!

DANMLibrary comment: 'I am a singleton class that does library look up'!

!DANMLibrary methodsFor: 'accessing'!

init
    paths := OrderedCollection new.
    library := LookupTable new.
    stFiles := LookupTable new.
    vFiles := LookupTable new.
    pathIndex := 0!

addPath: p
    paths add: p!

paths
    ^paths asArray!

paths: ps
    ^paths := ps asOrderedCollection!

moduleByName: mName
    |m|
    m := library at: mName ifAbsent: [ nil ].
    m == 0 ifTrue: [ 
        "the module is still loading, so this is a illegal recursion"
        self error: 'Circular reference on module %1' % {mName} ].
    m notNil ifTrue: [ ^m produce ].
    m :=self loadModuleByName: mName.
    self addModule: m.
    ^m produce!

addModule: mod
    library at: mod name put: mod!
    
topModule: mod
    mod name: 'top'.
    mod elaborate.
    topModule := mod!

topModule
    ^topModule!

size
    ^library size!

list
    ^library printString!
!

!DANMLibrary methodsFor: 'loading'!

loadModuleByName: mName
    "Load a module from either st schematic or verilog blackbox"
    |m|
    "This is a tag indicating we are loading this module. Wil be overwritten 
     after the module is successfully loaded"
    library at: mName put: 0.
    [ m := self tryLoadModuleByName: mName.
      m isNil & self searchMorePath ] whileTrue.
    m isNil ifTrue: [ m := self tryLoadBlackBoxModuleByName: mName ].
    m isNil ifTrue: [
        self error: 'The module %1 is not found in search paths: %2' 
            % {mName. self paths} ].
    ^m!

tryLoadBlackBoxModuleByName: mName
    |fileName m fs|
    fileName := vFiles at: mName ifAbsent: [ nil ].
    fileName notNil ifTrue: [
        Transcript 
            nextPutAll: 'Loading blackbox %1 from %2' % {mName. fileName};
            nl.
        fs := (Tokenizer on: (File name: fileName) readStream).
        [ m := DANMBlackBox parseVerilog: fs ] ensure: [ fs close ].
        ^DANMCloningTemplate newNamed: mName 
                             fromPath: fileName 
                             ofReference: m ].
    ^nil!
    
tryLoadModuleByName: mName
    |fileName m className class|
    fileName := stFiles at: mName ifAbsent: [ nil ].
    fileName notNil ifTrue: [
        className := ('DANMSchematic_',mName) asSymbol.
        class := (nil metaclassFor: className) instanceClass.
        class isNil ifTrue: [ 
            Transcript 
                nextPutAll: 'Loading schematic %1 from %2' % {mName. fileName};
                nl.
            [ FileStream fileIn: fileName ] 
                ifError: [ self error: '%1 cannot be loaded' % {fileName} ]].
        class := (nil metaclassFor: className) instanceClass.
        class isNil ifTrue: [
            self error: 'Error: class %1 is not defined in %2' 
                % {className. fileName} ].
        ^DANMClassicTemplate newNamed: mName fromPath: fileName ].
    ^nil!
    
searchMorePath
    |dir|
    pathIndex < paths size ifFalse: [ ^false ].
    dir := File name: (paths at: pathIndex + 1).
    (dir exists and: [dir isDirectory]) ifFalse: [
        self error: 'the dir %1 does not exist!' % {dir}; nl ].
    dir namesDo: [ :name |
        |fullname|
        fullname := FilePath append: name to: dir name.
        name =~ '^(\w+)\.st$$' ifMatched: [ :result |
            (stFiles includesKey: (result at: 1)) ifFalse: [
            stFiles at: (result at: 1) put: fullname ]].
        name =~ '^(\w+)\.v$$' ifMatched: [ :result |
            (vFiles includesKey: (result at: 1)) ifFalse: [
            vFiles at: (result at: 1) put: fullname ]].
        ].
    pathIndex := pathIndex + 1.
    ^true!
!

!DANMLibrary class methodsFor: 'accessing'!

sharedLibrary
    sharedLibrary isNil ifTrue: [ sharedLibrary := self new init ].
    ^sharedLibrary!

clearLibrary
    sharedLibrary := nil!

addPath: p
    self sharedLibrary addPath: p!

paths
    ^self sharedLibrary paths!

moduleByName: mName
    ^self sharedLibrary moduleByName: mName!

addModule: mod
    self sharedLibrary addModule: mod!

topModule: mod
    self sharedLibrary topModule: mod!

topModule
    ^self sharedLibrary topModule!

size
    ^self sharedLibrary size!

list
    ^self sharedLibrary list!

moduleByName: mName fromPaths: ps
    |mod|
    sharedLibrary := self new init.
    sharedLibrary paths: ps.
    mod := (sharedLibrary moduleByName: mName) 
        name: 'top';
        elaborate.
    sharedLibrary := nil.
    ^mod!
!
