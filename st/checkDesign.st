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

!DANMBlackBox methodsFor: 'check design'!

checkDesign
    "check to make sure all port are connected"
    |result|
    context isNil ifTrue: [ ^true ].
    result := true.
    self ports do: [ :port |
        |wire|
        wire := self wireOnPort: port.
        wire isNil ifTrue: [
            port isInput ifTrue: [
                result := false.
                Transcript nextPutAll: 'Check design error in %1: input port %2 is dangling on instance %3'
                    % {context fullPath. port name. entityName}; nl ].
            context subpressDangleCheck ifFalse: [
                Transcript nextPutAll: 'Check design warning in %1: port %2 is dangling on instance %3'
                    % {context fullPath. port name. entityName}; nl ]]].
    ^result!
!

!DANMSchematic methodsFor: 'check design'!

subpressDangleCheck
    "do not print warning for unloaded but driven wires/pins"
    ^false!

checkDesign
    |result|
    result := super checkDesign.
    result := instances inject: result into: [ :past :inst |
        past & inst checkDesign ]. 
    result := wires inject: result into: [ :past :wire | 
        past & wire checkDesign ]. 
    ^result!

checkQuiescentState
    "check to make sure every flop and latch is quiescent."
    |eos result|
    result := true.
    Transcript nextPutAll: '*** check to make sure all sequential elements are quiescent: '.
    eos := self buildEvaluationOrderSet.
    eos do: [ :each | each become: each asArray ].
    Transcript nextPutAll: 'took %1 cycles' % 
        {self calculateQuiescentState: eos}; nl.
    wires do: [ :each |
        (each isSequential and: [ each currentValue isNil ])
            ifTrue: [
                result := false.
                Transcript nextPutAll: 'Check design error in %1: sequential element %2 is not quiescent'
                    % {self referenceName. each name}; nl ]].
    self clearDerivedData!

checkFeedThrough
    "check to make sure there is no input to output direct path"
    |result|
    result := true.
    Transcript nextPutAll: '*** check to make sure there is no input to output direct path'; nl.
    ports do: [ :port |
        port isInput ifTrue: [
            port wire fanoutTreeInject: true into: [ :past :fanout |
                ((fanout isKindOf: DANMPort) and: [ fanout isOutput ]) 
                    ifTrue: [
                        Transcript nextPutAll: 'Check design error in %1: input port %2 fanout to output port %3'
                            % {self referenceName. port name. fanout name}; nl.
                        false ]
                    ifFalse: [ past ]]]].
    ^result!
                       
checkCascadingLatch
    "check to make sure there is no latch to latch direct path"
    |result|
    result := true.
    Transcript nextPutAll: '*** check to make sure there is no latch to latch direct path'; nl.
    wires do: [ :w |
        (w isKindOf: DANMLatch) ifTrue: [
            w fanoutTreeInject: true into: [ :past :fanout |
                (fanout isKindOf: DANMLatch) ifTrue: [
                    Transcript nextPutAll: 'Check design error in %1: latch %2 fanout to latch %3'
                        % {self referenceName. w name. fanout name}; nl.
                    false ]
                                            ifFalse: [ past ]]]].
    ^result!

calculateQuiescentState: eos
    "calculate the quiescent state of every wire. return number of cycle took"
    "check to make sure every flop and latch is quiescent."
    |cCount|
    cCount := 0.
    [ (self populateQuiescentState: eos) > 0 ] whileTrue: [
        cCount := cCount + 1 ].
    ^cCount!

populateQuiescentState: eos
    |changeSet|
    changeSet := OrderedCollection new.
    eos do: [ :set |
        set do: [ :w |
            w isDirty ifTrue: [
                w staticValue notNil ifTrue: [
                    changeSet add: w.
                    w directRefSet do: [ :each | each setDirty ]].
                w resetDirty ]]].
    changeSet do: [ :each | 
        each flip.
        "triggering flops. need to be done at the end of the cycle"
        each dataRefSet do: [ :w | w setDataDirty; setClockDirty ]].
    ^changeSet size!
!

!DANMWire methodsFor: 'check design'!

checkDesign
    "Check if I:
     * am loaded
     * am driven
     * have only one driver
     * width not 0
     * width match all pin width"
    |result dc width|
    result := true.
    self isLoaded | context subpressDangleCheck | self shouldConceal ifFalse: [
        Transcript nextPutAll: 'Check design warning in %1: wire %2 is unloaded'
            % {context fullPath. entityName}; nl ].
    self isDriven ifFalse: [
        result := false.
        Transcript nextPutAll: 'Check design error in %1: wire %2 is undriven'
            % {context fullPath. entityName}; nl ].
    dc := self driverCount.
    dc > 1 ifTrue: [ 
        result := false.
        Transcript nextPutAll: 'Check design error in %1: wire %2 is driven by %3 drivers'
            % {context fullPath. entityName. dc}; nl ].
    width := self width.
    width == 0 ifTrue: [      
        result := false.
        Transcript nextPutAll: 'Check design error in %1: width of wire %2 cannot be deduced'
            % {context fullPath. entityName}; nl ].
    self connections do: [ :pin |
        |pw|
        pw := pin width.
        pw ~= width ifTrue: [
            pin isOutput 
                ifTrue: [
                    result := false.
                    Transcript nextPutAll: 'Check design error in %1: wire %2 (width is %3) is driven by unmatched pin %4/%5 (width is %6)'
                        % {context fullPath. entityName. width.
                           pin context name. pin name. pw}; 
                        nl ]
                ifFalse: [
                    Transcript nextPutAll: 'Check design warning in %1: wire %2 (width is %3) is loaded by unmatched pin %4/%5 (width is %6)'
                        % {context fullPath. entityName. width.
                           pin context name. pin name. pw}; 
                        nl ]]].
    ^result!
!

!DANMExpressionWire methodsFor: 'check design'!

basicCheckDesign
    |w ew result o eo|
    result := super checkDesign.
    expression isNil 
        ifTrue: [
            result := false.
            Transcript nextPutAll: 'Check design error in %1: ExpressionWire %2 has no expression'
                % {context fullPath. entityName}; nl ]
        ifFalse: [ 
            expression checkDesign ifFalse: [ 
                result := false.
                Transcript nextPutAll: 'Check design error in %1: ExpressionWire %2 has bad expression %3'
                % {context fullPath. entityName. expression}; nl ]].
    w := self width.
    ew := self minWidth.
    (ew > 0) & (w ~= ew) ifTrue: [
        result := false.
        Transcript nextPutAll: 'Check design error in %1: ExpressionWire %2 (width is %3) is driven by unmatched expression %4 (width is %5)'
            % {context fullPath. entityName. w. expression. ew}; nl ].
    o := self evaluationOrder.
    eo := self basicEvaluationOrder.
    o ~= eo ifTrue: [ 
        result := false.
        Transcript nextPutAll: 'Check design error in %1: ExpressionWire %2 is part of a dependency loop.'
            % {context fullPath. entityName}; nl ].
    ^result!

checkDesign 
    |result|
    result := self basicCheckDesign.
    (expression notNil and: 
         [ expression isCombinatorial not ]) ifTrue: [
        result := false.
        Transcript nextPutAll: 'Check design error in %1: ExpressionWire %2 has non-combinatorial expression'
            % {context fullPath. entityName}; nl ].
    ^result!
!

!DANMFlipflop methodsFor: 'check design'!
checkDesign 
    |result|
    result := self basicCheckDesign.
    clock isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: Flipflop %2 has no clock'
            % {context fullPath. entityName}; nl.
        ^false ].
    (clock isKindOf: ASTIdentifier) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: Flipflop %2 has clock that is not existing wire: %3'
            % {context fullPath. entityName. clock}; nl ].
    clock width ~= 1 ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: Flipflop %2 ''s clock %3 is not one bit wide'
            % {context fullPath. entityName. clock}; nl.
        ^false ].
    ^result!
!

!DANMLatch methodsFor: 'check design'!
checkDesign 
    |result|
    result := self basicCheckDesign.
    clock isNil ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: Latch %2 has no clock'
            % {context fullPath. entityName}; nl.
        ^false ].
    (clock isKindOf: ASTIdentifier) ifFalse: [
        Transcript nextPutAll: 'Check design error in %1: Latch %2 has clock that is not existing wire: %3'
            % {context fullPath. entityName. clock}; nl ].
    clock width ~= 1 ifTrue: [
        Transcript nextPutAll: 'Check design error in %1: Latch %2 ''s clock %3 is not one bit wide'
            % {context fullPath. entityName. clock}; nl.
        ^false ].
    (expression notNil and: [ expression isCombinatorial not ]) 
        ifTrue: [
            Transcript nextPutAll: 'Check design error in %1: Latch %2 has non-combinatorial input'
                % {context fullPath. entityName}; nl.
            ^false ].
    ^result!
!
