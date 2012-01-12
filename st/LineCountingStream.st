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

PositionableStream subclass: #LineCountingStream
                   instanceVariableNames: 
                       'stream lines pos line column lastPos'
                   classVariableNames: ''
                   poolDictionaries: ''
                   category: 'Streams-Files'!

LineCountingStream comment: 
'I am like a ReadStream, but I also keep track of the current line and column 
number. '!

!LineCountingStream class methodsFor: 'instance creation'!

on: aStream
    ^self new
        stream: aStream!
!

!LineCountingStream methodsFor: 'accessing'!

name
    ^stream name!

close
    stream close!

size 
    ^stream size!

line
    ^line!

column
    ^column!

position
    ^pos!

stream
    ^stream!

stream: aStream
    "init self to pristine state"
    stream := aStream.
    pos := 0.
    lastPos := 0.
    line := 1.
    column := 1.
    lines := OrderedCollection new.
    (stream isPositionable) ifTrue: [
        |oldPosition|
        "reset and re-seek to get the line and column info"
        oldPosition := stream position.
        (oldPosition == 0) ifFalse: [
            stream reset.
            self next: oldPosition ]]!
!

!LineCountingStream methodsFor: 'buffering'!

reset
    pos := 0.
    line := 1.
    column := 1!

lastPos
    ^lastPos!

gotoLastPos
    pos := lastPos.
    line := lines size + 1.
    column := 1!

computeLineAndColumn
    |count|
    count := 0.
    line := 1.
    [(lines size >= line) and: [(pos - count) >= (lines at: line) size]] 
        whileTrue: [
            count := count + ((lines at: line) size).
            line := line + 1 ].
    column := pos - count + 1!

nextFromBuffer
    |next thisLine|
    thisLine := lines at: line.
    next := thisLine at: column.
    (thisLine size == column) 
        ifTrue: [
            line := line + 1.
            column := 1]
        ifFalse: [
            column := column + 1 ].
    pos := pos + 1.
    ^next!

copyTo: last
    |wB|
    wB := WriteStream on: (String new: (last - pos)).
    last - pos timesRepeat: [ wB nextPut: self nextFromBuffer ].
    ^wB contents!

peek
    |char oldPos oldLine oldColumn|
    oldPos := pos.
    oldLine := line.
    oldColumn := column.
    char := self next.
    pos := oldPos.
    line := oldLine.
    column := oldColumn.
    ^char!

peekAvailable: len
    |chars oldPos oldLine oldColumn|
    oldPos := pos.
    oldLine := line.
    oldColumn := column.
    chars := self nextAvailable: len.
    pos := oldPos.
    line := oldLine.
    column := oldColumn.
    ^chars!

atEnd
    ^(pos == lastPos) and: [ stream atEnd]!

next
    (pos < lastPos) 
        ifFalse: [ self scanForward ifFalse: [ ^nil ]].
    ^self nextFromBuffer!

next: numberOfChars
    [(pos + numberOfChars >= lastPos) and: [self scanForward]]
        whileTrue.
    lastPos < (pos + numberOfChars) ifTrue: [
        SystemExceptions.NotEnoughElements signalOn: 
            pos + numberOfChars - lastPos ].
    ^self copyTo: pos + numberOfChars!

nextAvailable: numberOfChars
    [(pos + numberOfChars >= lastPos) and: [self scanForward]]
        whileTrue.
    ^self copyTo: (lastPos min: (pos + numberOfChars))!

nextLine
    |s|
    s := self nextRawLine.
    (s == nil) ifTrue: [ ^nil ].
    ^s chomp!

nextRawLine
    |chars neof|
    (line <= lines size) ifFalse: [ self scanForward ifFalse: [ ^nil ]].
    chars := (lines at: line) copyFrom: column.
    line := line + 1.
    column := 1.
    pos := pos + chars size.
    ^chars!

pushBack: n
    (n > pos) ifTrue: [
        self error: 'Can''t pushback %1 while the stream has only %2' %
            {n. pos} ].
    pos := pos - n.
    column > n 
        ifTrue: [ column := column - n ]
        ifFalse: [ self computeLineAndColumn ].
    ^self!

position: newPosition
    |chars|
    (newPosition <= lastPos) ifTrue: [
        pos := newPosition.
        self computeLineAndColumn.
        ^self ].
    self gotoLastPos.
    self nextAvailable: (newPosition - lastPos).
    ^self!
!

!LineCountingStream methodsFor: 'scaning'!
scanForward
    "scan the input some more, typically a line. return false if EOF,
     true otherwise."
    |thisLine|
    thisLine := self stream readNextRawLine.
    (thisLine == nil) ifTrue: [ ^false ].
    lines add: thisLine.
    lastPos := lastPos + thisLine size.
    ^true!
!

!LineCountingStream methodsFor: 'printing'!
printOn: aStream
    aStream nextPutAll: ('%1 on: (%2) at: (line: %3 column: %4)'
                             bindWithArguments: {self class name.
                                                 self name.
                                                 self line.
                                                 self column})!
!
