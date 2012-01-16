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

DANMSchematic methodsFor: 'connecting'!

connect: pinNames
    ^self connectPins: (pinNames collect: [ :each|
        self pinFromString: each ])!

connect: pinNames name: wName
    ^self connectPins: (pinNames collect: [ :each|
        self pinFromString: each ])
         name: wName!

connect: pinNames to: expression
    ^self connectPins: (pinNames collect: [ :each|
        self pinFromString: each ])
          to: expression!
    
connectPins: pins to: expression
    |wName|
    pins size > 0 ifFalse: [ 
        self error: 'No pin to connect' ].
    wName := (pins at: 1) name.
    wName := wires uniqueKeyLike: wName.
    ^self connectPins: pins to: expression name: wName!

connect: pinNames to: expression name: wName
    ^self connectPins: (pinNames collect: [ :each|
        self pinFromString: each ])
          to: expression name: wName!

connectPins: pins
    |wName|
    pins size > 0 ifFalse: [ 
        self error: 'No pin to connect' ].
    wName := (pins at: 1) name.
    wName := wires uniqueKeyLike: wName.
    ^self connectPins: pins name: wName!

connectPins: pins name: wName
    |wire|
    wire := DANMWire newNamed: wName inContext: self.
    wire connectPins: pins.
    ^wire!

connectPins: pins to: exp name: wName
    |wire|
    wire := self let: wName be: exp.
    wire connectPins: pins.
    ^wire!

let: wName be: mName on: conns
    self let: wName be: mName on: conns with: #()!

let: wName be: mName on: conns with: params
    |module oPort wire|
    module := self addInstanceOf: mName.
    module setParameters: params.
    oPort := module getOutputPort.
    wire := DANMWire newNamed: wName inContext: self.
    wire connectPort: oPort.
    module connectWire: wire toPort: oPort.
    "connect all inputs"
    conns do: [ :each |
        | port exp|
        port := module portByName: each key.
        exp := (ExpressionAST newFrom: each value).
        self connectInstance: module port: port to: exp ].
    "connect all unconnected inputs"
    self autoConnect: module!
    
connectInstance: module port: port to: exp
    |wire wName|
    (exp isKindOf: ASTIdentifier) 
        ifTrue: [
            wire := exp identifier.
            exp destroy ]
        ifFalse: [
            wName := wires uniqueKeyLike: module name, '/', port name.
            wire := DANMExpressionWire newNamed: wName inContext: self.
            wire expression: exp ].
    wire connectPort: port.
    module connectWire: wire toPort: port!

assert: exp
    |wire e wName|
    e := ExpressionAST newFrom: exp.
    (e isKindOf: ASTIdentifier) 
        ifTrue: [ wName := 'ASSERT_' , e identifier name ]
        ifFalse: [ wName := DANMCurrentDesign value wires 
                       uniqueKeyLike: 'ASSERT'].
    wire := DANMAssertion newNamed: wName inContext: self.
    wire expression: e.
    ^wire!
    
let: wName beAssertion: exp
    |wire e|
    wire := DANMAssertion newNamed: wName inContext: self.
    wire expression: (ExpressionAST newFrom: exp).
    ^wire!

let: wName be: exp resetAfter: delay
    |wire e|
    wire := DANMMonostable newNamed: wName inContext: self.
    wire expression: (ExpressionAST newFrom: exp).
    wire delay: delay.
    ^wire!
    
let: wName be: exp delay: delay
    |wire e|
    wire := DANMDelayLine newNamed: wName inContext: self.
    wire expression: (ExpressionAST newFrom: exp).
    wire delay: delay.
    ^wire!
    
let: wName be: exp
    |wire e|
    e := ExpressionAST newFrom: exp.
    wire := DANMExpressionWire newNamed: wName inContext: self.
    wire expression: e.
    ^wire!

defaultClock: clk
    self userDataAt: 'defaultClock' put: clk!

defaultClock
    ^ self userDataAt: 'defaultClock' ifAbsent: [ 
        self error: 'no default clock defined' ]!

let: wName beClocked: exp
    ^self let: wName be: exp clockedBy: (self defaultClock)!

let: wName beLatched: exp
    ^self let: wName be: exp latchedBy: (self defaultClock)!

let: wName be: exp clockedBy: clk
    |wire|
    wire := DANMFlipflop newNamed: wName inContext: self.
    wire expression: (ExpressionAST newFrom: exp).
    wire clock: (ExpressionAST newFrom: clk).
    ^wire!

let: wName be: exp latchedBy: clk
    |wire|
    wire := DANMLatch newNamed: wName inContext: self.
    wire expression: (ExpressionAST newFrom: exp).
    wire clock: (ExpressionAST newFrom: clk).
    ^wire!

let: wName beIfs: ifs
    ^ self let: wName be: (ASTIfsOp newIfs: ifs)!

let: wName beClockedIfs: ifs
    ^self let: wName be: (ASTIfsOp newIfs: ifs) 
          clockedBy: (self defaultClock)!
    
let: wName beLatchedIfs: ifs
    ^self let: wName be: (ASTIfsOp newIfs: ifs) 
          latchedBy: (self defaultClock)!
    
let: wName beIfs: ifs clockedBy: clk
    ^ self let: wName be: (ASTIfsOp newIfs: ifs) clockedBy: clk!

let: wName beIfs: ifs latchedBy: clk
    ^ self let: wName be: (ASTIfsOp newIfs: ifs) latchedBy: clk!

let: wName beCases: table on: subject
    ^self let: wName be: (ASTCasesOp newCases: table on: subject)!

let: wName beClockedCases: table on: subject
    ^self let: wName be: (ASTCasesOp newCases: table on: subject)
          clockedBy: (self defaultClock)!

let: wName beLatchedCases: table on: subject
    ^self let: wName be: (ASTCasesOp newCases: table on: subject)
          latchedBy: (self defaultClock)!

let: wName beCases: table on: subject clockedBy: clk
    ^self let: wName be: (ASTCasesOp newCases: table on: subject) 
          clockedBy: clk!

let: wName beCases: table on: subject latchedBy: clk
    ^self let: wName be: (ASTCasesOp newCases: table on: subject) 
          latchedBy: clk!

let: wName beRetimingOf: w by: n 
    ^(self retime: w by: n) renameTo: wName!

let: wName beRetimingOf: w by: n valid: v
    ^(self retime: w by: n valid: v) renameTo: wName!

let: wName beRetimingOf: w by: n strobe: s
    ^(self retime: w by: n strobe: s) renameTo: wName!

let: wName beRetimingOf: w by: n valid: v strobe: s
    ^(self retime: w by: n valid: v strobe: s) renameTo: wName!

let: wName beRetimingOf: w on: clk by: n 
    ^(self retime: w on: clk by: n) renameTo: wName!

let: wName beRetimingOf: w on: clk by: n valid: v
    ^(self retime: w on: clk by: n valid: v) renameTo: wName!

let: wName beRetimingOf: w on: clk by: n strobe: s
    ^(self retime: w on: clk by: n strobe: s) renameTo: wName!

let: wName beRetimingOf: w on: clk by: n valid: v strobe: s
    ^(self retime: w on: clk by: n valid: v strobe: s) renameTo: wName!

let: wName beFSM: fsm
    ^self let: wName beFSM: fsm clockedBy: (self defaultClock)!

let: wName beFSM: fsm clockedBy: clk
    |wire width counter cases choices state exp|
    cases := OrderedCollection new.
    choices := OrderedCollection new.
    width := (fsm size log: 2) ceiling.
    counter := 0.
    fsm do: [ :each |
        wire := DANMMacro newNamed: each key inContext: self.
        state := (ASTConstant newConstant: counter width: width).
        wire expression: state.
        counter := counter + 1.
        cases add: (ASTIdentifier basicNewIdentifier: wire).
        choices add: (ExpressionAST newFrom: each value) ].
    "must have default, so FSM will not stuck"
    cases add: ASTDefault new.
    choices add: (ASTConstant newConstant: 0 width: width).
    exp := (ASTCasesOp newSubject: (ASTIdentifier newIdentifier: wName)
                       cases: cases choices: choices).
    wire := self let: 'next_',wName be: exp.
    wire := wire defaultTo: (ASTIdentifier newIdentifier: wName).
    ^self let: wName be: wire clockedBy: clk!
                     
retime: w by: n
    ^self retime: w on: (self defaultClock) by: n!

retime: w on: clk by: n
    |wire name|
    wire := self getWire: w.
    name := wire name.
    1 to: n do: [ :i |
        wire := self let: ('%1_rt%2' % {name. i}) 
                     be: (ASTIdentifier basicNewIdentifier: wire) 
                     clockedBy: clk ].
    ^wire!
    
retime: w by: n strobe: s
    ^self retime: w on: (self defaultClock) by: n strobe: s!

retime: w on: clk by: n strobe: s
    |wire name|
    wire := self getWire: w.
    name := wire name.
    1 to: n do: [ :i |
        wire := self let: ('%1_rt%2' % {name. i}) 
                     beIfs: {s -> (ASTIdentifier 
                                       basicNewIdentifier: wire)} 
                     clockedBy: clk ].
    ^wire!
    
retime: w on: clk by: n valid: v
    ^self retime: w on: (self defaultClock) by: n valid: v!

retime: w on: clk by: n valid: v
    |wire name vWire vName|
    wire := self getWire: w.
    vWire := self getWire: v.
    name := wire name.
    vName := vWire name.
    1 to: n do: [ :i |
        wire := self let: ('%1_rt%2' % {name. i}) 
                     beIfs: {vWire name -> 
                                 (ASTIdentifier basicNewIdentifier: wire)}
                     clockedBy: clk.
        vWire := self let: ('%1_rt%2' % {vName. i}) 
                      be: (ASTIdentifier basicNewIdentifier: vWire) 
                      clockedBy: clk ].
    ^wire!

retime: w on: clk by: n valid: v strobe: s
    ^self retime: w on: (self defaultClock) by: n valid: v strobe: s!

retime: w on: clk by: n valid: v strobe: s
    |wire name vWire vName|
    wire := self getWire: w.
    vWire := self getWire: v.
    name := wire name.
    vName := vWire name.
    1 to: n do: [ :i |
        wire := self let: ('%1_rt%2' % {name. i}) 
                     beIfs: {'%1&(%2)' %{vWire name. s} -> 
                                 (ASTIdentifier basicNewIdentifier: wire)}
                     clockedBy: clk.
        vWire := self let: ('%1_rt%2' % {vName. i}) 
                      beIfs: {s -> (ASTIdentifier 
                                        basicNewIdentifier: vWire)} 
                      clockedBy: clk ].
    ^wire!
    
"connect all unconnected input port"
autoConnect: mod
    mod ports keys do: [ :pName |
        |port wire |
        port := mod portByName: pName.
        (port isInput and: [(mod wireOnPort: port) isNil]) ifTrue: [
            wire := self findWireByName: pName.
            (wire notNil and: [wire width == port width]) ifTrue: [
                wire connectPort: port.
                mod connectWire: wire toPort: port ]]]!

autoConnect
    |allPinNames|
    allPinNames := self allPinNames.
    allPinNames do: [ :pName|
        self tryConnect: pName ]!

tryConnect: pName
    |pins width driverCount wire pin|
    pins := self allUnconnectedPinsWithName: pName.
    pins size == 0 ifTrue: [ ^self ].
    width := (pins at: 1) width.
    wire := self findWireByName: pName.
    driverCount := 0.
    (wire notNil and: [ wire isDrivenInternally ]) ifTrue: [
        driverCount := 1 ].
    1 to: pins size do: [ :i |
        pin := pins at: i.
        (pin width == width) ifFalse: [ ^self ].
        pin isOutput ifTrue: [ driverCount := driverCount + 1 ]].
    "if there is no driver but it is a port, then we can assume the port will
     drive"
    driverCount == 0 & (self findPortByName: pName) notNil ifTrue: [
        driverCount := 1 ].
    driverCount == 1 ifFalse: [ ^self ].
    "All check passed, connect them"
    self connectPins: pins name: pName!

tryConnectInputs: pName
    |pins width|
    pins := self allUnconnectedInputPinsWithName: pName.
    pins size == 0 ifTrue: [ ^self ].
    width := (pins at: 1) width.
    pins do: [ :each |
        (each width == width) ifFalse: [ ^self ]].
    "All check passed, connect them"
    self connectPins: pins name: pName!

expose: wName
    (self wireByName: wName) expose!

conceal: wName
    (self wireByName: wName) conceal!

reset: wName byLow: reset to: resetTo
    |w|
    w := self wireByName: wName.
    (w isKindOf: DANMFlipflop) ifFalse: [
        self error: 'Only flop is resettable. Got: %1' % {wName} ].
    (self wireByName: wName) resetBy: (ExpressionAST newFrom: reset) 
                             to: (ExpressionAST newFrom: resetTo)!

default: wName to: d
    |w|
    w := self wireByName: wName.
    (w isKindOf: DANMExpressionWire) ifFalse: [
        self error: 'Only wire with expression can have default. Got: %1' 
            % {wName} ].
    (self wireByName: wName) defaultTo: (ExpressionAST newFrom: d)!
    
syncReset: wName by: reset to: resetTo
    |w|
    w := self wireByName: wName.
    w expression: (ASTIfsOp newIfs: {reset -> resetTo.
                                     1 -> w expression})!

autoExposeInputs
    |allPinNames|
    allPinNames := self allPinNames.
    allPinNames do: [ :pName|
        |wire|
        wire := self findWireByName: pName.
        (wire isNil or: [wire isDriven not])  ifTrue: [
            self tryConnectInputs: pName ]].
    wires do: [ :wire|
        (wire shouldConceal not & wire isExposed not and: [wire isDriven not]) 
            ifTrue: [ wire expose ]]!

autoExposeOutputs
    wires do: [ :wire|
        (wire shouldConceal not & wire isExposed not and: [wire isLoaded not])
            ifTrue: [ wire expose ]]!
!
