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

DANMEntity subclass: #DANMBlackBox
           instanceVariableNames: 
               'ports parameters reference context connections'
           classVariableNames: ''
           poolDictionaries: ''
           category: 'DANM'!

DANMBlackBox comment: 'I am a black box module, only ports are known'!

!DANMBlackBox methodsFor: 'accessing'!

uniquifiedRefName
    |n|
    n := self attribute: #UNIQUIFIED_REF_NAME.
    n notNil ifTrue: [ ^n ].
    ^self referenceName!

isUniquified
    ^self reference returnThenSetTag notNil!

referencePrintName
    ^self referenceName!

uniquifiedRefName: n
    "only assign once"
    (self hasAttribute: #UNIQUIFIED_REF_NAME) ifTrue: [
        ^self ].
    n = self referenceName ifTrue: [ ^self ].
    self setAttribute: #UNIQUIFIED_REF_NAME to: n!

referenceName
    reference name notNil ifTrue: [ ^reference name ].
    ^entityName!

referencePath
    ^reference srcPath!

type
    ^'blackbox'!

context
"My context is the schematic that instances me"
    ^context!

canBeSynthesized
    "whether I can be synthesized. Modeled Expression cannot"
    ^true!

canBeFlatten
    "whether I can be flatten. black box cannot"
    ^false!

canBePrintedInLine
    "whether I can be printed as inline verilog. for now we only inline
     very short verilog file"
    reference isNil ifTrue: [ ^false ].
    reference srcPath isNil ifTrue: [ ^false ].
    self shouldBlackBox ifTrue: [ ^false ]. 
    self shouldNotPrint ifTrue: [ ^false ]. 
    (File name: reference srcPath) size > 4096 ifTrue: [ 
        Transcript nextPutAll: 'Warning: verilog source %1 for module %2 will not be printed inline because it is big' 
            % {reference srcPath. entityName}; nl.
        ^false ].
    ^true!

shouldBlackBox
    ^((self hasParameter: 'opaque') and: [ (self parameterValue: 'opaque') = 1 ])! 

shouldNotPrint
    ^((self hasParameter: 'omit') and: [ (self parameterValue: 'omit') = 1 ])! 

topPath
    context isNil ifTrue: [ ^'' ].
    ^context topPath, '../'!

fullPath
    context isNil ifTrue: [ ^entityName ].
    ^context fullPath, '/', entityName!
 
topLevel
    context isNil ifTrue: [ ^self ].
    ^context context!

context: newContext
    context := newContext!

elaborate
    "blackbox does not need to elaborate"
    ^self!

postProcess
    "nothing to do for post-process"
    ^self!

postCopy
    "ports and parameters need to be copied"
    |newParam newPorts|
    self clearConnections.
    parameters notNil ifTrue: [
        newParam := LookupTable new.
        parameters keysAndValuesDo: [ :k :v |
            newParam at: k put: v deepCopy ].
        parameters := newParam ].
    newPorts := LookupTable new.
    ports keysAndValuesDo: [ :k :v |
        newPorts at: k put: (v copy context: self) ].
    ports := newPorts.
    ^self!

copyFrom: anotherOne
    parameters := anotherOne parameters.
    ports := anotherOne ports.
    self postCopy!

reference
"return the referenced module"
    ^reference!
    
reference: newReference
    reference := newReference!

connections 
    "connections is a dictionary of wires keyed off port names. The detail bit
     connections to a wire is stored at the wire side. " 
    ^connections!

directFanins
    |result|
    result := OrderedCollection new.
    connections keysAndValuesDo: [ :pName :each |
        |p|
        p := self portByName: pName.
        p isInput ifTrue: [
            result add: each ]].
    ^result!

clearConnections
    connections := LookupTable new!

ports 
    ^ ports!

getOutputPort
    |oPorts|
    oPorts := self ports values select: [ :each | each isOutput ].
    oPorts size == 1 ifFalse: [
        self error: '%1 has non-unique output: %2' % {self. oPorts size} ].
    ^oPorts first!

portByName: pName
    |p|
    p := self findPortByName: pName.
    p isNil ifTrue: [
        self error: ('Port by the name of %1 does not exist in %2' % 
                         {pName. self}) ].
    ^p!

findPortByName: pName
    ^self ports at: pName ifAbsent: [ nil ]!

addPort: newPort
    |portName|
    portName := newPort name.
    (ports includesKey: portName) ifTrue: [
        self error: ('Port %1 already exist in %2!' 
                         % {portName. self})].
    ports at: portName put: newPort.
    newPort context: self!            

removePort: aPort
    |portName|
    portName := aPort name.
    (ports includesKey: portName) ifFalse: [
        self error: ('Port %1 does not exist in %2!' 
                         % {portName. self})].
    ports removeKey: portName!
    
clearPorts
    ports := LookupTable new!

setParameter: pName to: pValue
    parameters isNil ifTrue: [ parameters := LookupTable new ].
    (pValue == nil) 
        ifTrue: [parameters removeKey: pName ifAbsent: [nil]]
        ifFalse: [parameters at: pName 
                             put: (SimpleExprNode promote: pValue) ]!

setParameters: params
    params do: [ :each |
        self setParameter: each key to: each value ]!

hasParameter: pName
    parameters isNil ifTrue: [ ^false ].
    ^parameters includesKey: pName!

parameter: pName
    parameters isNil ifTrue: [ parameters := LookupTable new ].    
    ^parameters at: pName ifAbsent: [ nil ]!

parameters
    ^parameters!

parameterValue: pName
    |p|
    p := self parameter: pName.
    p isNil ifTrue: [ ^0 ].
    DANMCurrentDesign use: self during: [
        ^p value ]!

setTopModule
    "assume I am the top module and ignore everything outside"
    self context: nil.
    self clearConnections!

clearDerivedData
"some data is derived from more fundimental data; the derived ones are 
 kept mainly for performance reason. However, sometimes there is a need 
 to clear all that because structural change that make them stale"
    self tag: nil!

destroy
    "remove self from the context"
    context removeInstanceByName: entityName.
    context := nil!
!

!DANMBlackBox methodsFor: 'connecting'!

renameTo: newName
    |oldName oldContext anotherInst|
    anotherInst := context findInstanceByName: newName.
    anotherInst notNil ifTrue: [ 
	self error: 'Instance by the name of %1 already exists!' % newName ].
    oldName := entityName.
    oldContext := context.
    oldContext removeInstanceByName: oldName.
    oldContext addInstance: self byName: newName!
     
connectWire: aWire toPort: port
    |portName|
    portName := port name.
    (connections includesKey: portName) ifTrue: [
        self error: ('Port %1 of %2 already connected!' 
                         % {portName. self}) ].
    self basicConnectWire: aWire toPort: port!

basicConnectWire: aWire toPort: port
    |portName|
    portName := port name.
    connections at: portName put: aWire!

disconnectPort: port
    |portName|
    portName := port name.
    (connections includesKey: portName) ifFalse: [
        self error: ('Port %1 of %2 not connected!' 
                         % {portName. self}) ].
    connections removeKey: portName!
    
wireOnPort: port
    |portName|
    portName := port name.
    ^connections at: portName ifAbsent: [nil]!
!

!DANMBlackBox class methodsFor: 'instance creation'!

new
    ^super new 
        clearPorts;
        clearConnections!

newNamed: aName
    ^(super newNamed: aName)
        clearPorts!
!

!DANMBlackBox class methodsFor: 'verilog parsing'!

parseVerilog: aTokenizer
    "Parse a black box module from a tokenizer, nil if EOF is reached"
    |blackbox|
    blackbox := self new.
    DANMCurrentDesign use: blackbox during: [
        (blackbox parseModuleHead: aTokenizer) == nil ifTrue: [ ^nil ].
        blackbox comment: aTokenizer docString.
        aTokenizer clearDocString.
        [ blackbox parseStatement: aTokenizer ] whileTrue.
    "skip to endmodule, cheat here because we assume one module per file"
"    [ aTokenizer nextToken = 'endmodule' ] whileFalse. 
 "    blackbox validate ].
    ^blackbox!
!

!DANMBlackBox methodsFor: 'verilog parsing'!

parseModuleHead: aTokenizer
    "parse module head like:
     module mod(port1, port2);"
    |name|
    aTokenizer atEnd ifTrue: [ ^nil ].
    aTokenizer expect: 'module'.
    name := aTokenizer nextToken.
    (name isMemberOf: String) ifFalse: [
        aTokenizer parseError: 'Expecting module name' ].
    self name: name.
    aTokenizer expect: $(.
    self parsePortNames: aTokenizer.
    aTokenizer expect: $;!

parsePortNames: aTokenizer
    "parse: port1, port2) , consume the )"
    |token|
    [   token := aTokenizer nextToken.
        token ~= $) ] whileTrue: [
            (token isMemberOf: String) ifFalse: [
                aTokenizer parseError: 'Expecting port name' ].
            "The false is only a place holder"
            ports at: token put: false.
            token := aTokenizer nextToken.
            token == $) ifTrue: [ ^self ].
            token == $, ifFalse: [
                aTokenizer parseError: 'Expecting ,' ]]!

parseStatement: aTokenizer
    ^(self parsePort: aTokenizer) or: [
        self parseParameter: aTokenizer ]!

parseParameter: aTokenizer
    |token value width|
    (aTokenizer testNext: 'parameter') ifFalse: [ ^false ].
    width := self tryParseWidth: aTokenizer.
    width notNil ifTrue: [ 
        "ignore parameter with width for now"
        [ aTokenizer nextToken = $; ] whileFalse.
        ^true ].
    token := aTokenizer nextToken.
    (token isMemberOf: String) ifFalse: [
        aTokenizer parseError: 'Expecting parameter name' ].
    aTokenizer expect: $=.
    value := (SimpleExprParser on: aTokenizer) parseExpression.
    aTokenizer expect: $;.
    self setParameter: token to: value.
    ^ true!

parsePort: aTokenizer
    "parse input [3:0] a;"
    |token dir width|
    dir := self tryParseDirection: aTokenizer.
    dir isNil ifTrue: [ ^ false ].
    width := self tryParseWidth: aTokenizer.
    width isNil ifTrue: [ width := 1 ].
    (width isKindOf: SimpleExprConstant) ifTrue: [ width := width value ]. 
    [ token := self parseOnePort: aTokenizer width: width direction: dir.
      token ~= $; ] whileTrue: [
          token == $, ifFalse: [ aTokenizer parseError: 'Expecting ,' ]].
    aTokenizer clearDocString.
    ^true!

parseOnePort: aTokenizer width: width direction: dir
    |token port|
    token := aTokenizer nextToken.
    (token isMemberOf: String) ifFalse: [
        aTokenizer parseError: 'Expecting port name' ].
    (ports includesKey: token) ifFalse: [
        aTokenizer parseError: 'Port %1 is not found' % {token} ].
    port := DANMPort newNamed: token width: width direction: dir.
    port comment: aTokenizer docString.
    ports at: token put: port.
    port context: self.
    ^aTokenizer nextToken!
    
tryParseDirection: aTokenizer
    |token|
    token := aTokenizer nextToken.
    (token isMemberOf: String) ifFalse: [ 
        aTokenizer pushBackLastToken.
        ^nil ].
    ((token = 'input') | (token = 'output') | (token = 'inout')) ifFalse: [
        aTokenizer pushBackLastToken.
        ^nil ].
    ^token asSymbol!

tryParseWidth: aTokenizer
    "parse 3:0"
    |w|
    (aTokenizer testNext: $[) ifFalse: [ ^ nil ].
    w := (SimpleExprParser on: aTokenizer) parseExpression.
    aTokenizer expect: $:.
    aTokenizer expect: 0.
    aTokenizer expect: $].
    ^(w + 1) optimize!
    
validate
    ports keysAndValuesDo: [ :k :v |
        v = false ifTrue: [
            self error: 'Port %1 is not found' % {k} ]]!
!

!DANMBlackBox methodsFor: 'printing'!

printVerilogOn: aStream
    self printVerilogHeaderOn: aStream.
    self printVerilogCoreOn: aStream.
    self printVerilogFooterOn: aStream!

printBlackBoxVerilogOn: aStream
    aStream 
        nl; 
        nextPutAll: '// this is a blackbox for %1 as a placeholder for synthesis' 
        % {self referencePrintName}; nl.
    self printVerilogHeaderOn: aStream.
    self printVerilogFooterOn: aStream!

printFullVerilogOn: aStream
    aStream nl. "make sure there are newlines around"
    reference printTextOn: aStream.
    aStream nl!
 
printFullVerilogToDir: dirName
    |fs|
    reference tag notNil ifTrue: [ ^self ].
    fs := (File name: dirName, '/', self referencePrintName, '.v') 
        writeStream.
    [ self printFullVerilogOn: fs ] 
        ensure: [ fs close ]!

printVerilogCoreOn: aStream
    ^self!

printVerilogFooterOn: aStream
    aStream 
        nextPutAll: 'endmodule'; nl!

printVerilogHeaderOn: aStream
    |sortedPorts lastPort|
    sortedPorts := ports asSortedCollection.
    sortedPorts size > 0 ifTrue: [
        lastPort := sortedPorts last ].
    aStream 
        nl;
        nextPutAll: '/**'; nl;
        nextPutAll: self comment; nl;
        nextPutAll: '*/'; nl;
        nextPutAll: 'module %1 (' % {self referencePrintName}; nl.
    sortedPorts do: [ :port |
        port == lastPort 
            ifFalse: [ aStream nextPutAll: '    %1,' % {port verilogName}; nl ]
            ifTrue:  [ aStream nextPutAll: '    %1' % {port verilogName} ]].
    aStream
        nextPutAll: ');'; nl.
    ports asSortedCollection do: [ :port |
        port printVerilogOn: aStream ].
    parameters notNil ifTrue: [
        parameters keys asSortedCollection do: [ :k |
            aStream nextPutAll: '    parameter %1 = %2;' 
                % {k. self parameter: k}; nl ]]!

printInstanceVerilogOn: aStream
    |sortedPorts lastPort|
    sortedPorts := ports asSortedCollection.
    sortedPorts do: [ :port |
        |w|
        w := (self wireOnPort: port).
        w notNil ifTrue: [
            lastPort := port ]].
    aStream 
        nl;
        nextPutAll: '// instance of %1 (%2)' % {entityName. 
                                                self type}; nl;
        nextPutAll: '    %1 %2 (' % {self referencePrintName. 
                                     self verilogName}; nl.
    sortedPorts do: [ :port |
        |w pw ww ws|
        w := (self wireOnPort: port).
        pw := port width.
        w isNil ifFalse: [
            ww := w width.
            ws := pw == ww ifTrue: [ w verilogName ]
                           ifFalse: [ '%1[%2:0]' % {w verilogName. pw - 1} ].
            port == lastPort 
                ifFalse: [ 
                    aStream nextPutAll: '        .%1(%2),' 
                        % {port verilogName. ws}; nl ]
                ifTrue: [ 
                    aStream nextPutAll: '        .%1(%2)' 
                        % {port verilogName. ws} ]]].
    aStream
        nextPutAll: ');'; nl.
    parameters notNil ifTrue: [
        parameters keys asSortedCollection do: [ :k |
            "those 2 parameters are used for controlling printing only"
            (k = 'omit') | (k = 'opaque') ifFalse: [ 
            aStream nextPutAll: '    defparam %1.%2 = %3;' 
                % {self verilogName. k. self parameterValue: k}; nl ]]]!
!
