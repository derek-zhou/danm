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

DANMExpressionWire subclass: #DANMMonostable
    instanceVariableNames: 'delay stimuli'
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

DANMMonostable comment:
    'I am a monostable which goes back to 0 after certain delay'!

!DANMMonostable methodsFor: 'accessing'!

delay: d
    delay := d!

delay
    ^delay!
!

!DANMMonostable methodsFor: 'basic'!

staticValue
    self nextValue: 0.
    nextValue ~= value ifTrue: [ ^nextValue ].
    ^nil!

evaluate
    |v|
    stimuli notNil ifTrue: [
        (context context isKindOf: DANMSimulator) ifTrue: [ 
            stimuli fireTime == context context currentTime ifTrue: [ 
                stimuli fireTime: nil.
                stimuli := nil.
                self nextValue: 0.
                nextValue ~= value ifTrue: [ ^nextValue ]]].
        ^nil ].
    ^super evaluate!

flip
    (nextValue ~= 0 & (context context isKindOf: DANMSimulator)) ifTrue: [
        stimuli := TimeSeries new.
        stimuli fireTime: context context currentTime + delay.
        stimuli context: self type: #DIRECT.
        context context addStimuli: stimuli ].
    ^super flip!
!

!DANMMonostable methodsFor: 'printing'!

printOn: aStream
    aStream nextPutAll: ('(%1\_%2) ' % {expression. delay})!

basicPrintVerilogOn: aStream
    self printVerilogRegsOn: aStream.
    expression printAdditionalVerilogOn: aStream.
    expression printVerilogOn: aStream withAlias: 'Monostable'!

printBlockVerilogOn: aStream
    |w name|
    name := self verilogName.
    aStream nl.
    aStream 
        nextPutAll: '    always @(posedge %1 or posedge %2)' 
            % {expression printStringStyle: #VERILOG. name}; nl;
        nextPutAll: '        if (%1)' % {name}; nl;
        nextPutAll: '            %1 <= #%2 0;' % {name. delay} ; nl;
        nextPutAll: '        else'; nl;
        nextPutAll: '            %1 <= %2;' 
            % {name. expression printStringStyle: #VERILOG. name}; nl;
        nextPutAll: '    initial %1=0;' % {name}; nl.
    expression clearAlias!
!
