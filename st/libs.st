"some handy methods for the standard classes"

!Stream methodsFor: 'line and column counting'!

readNextRawLine
    "nextLine chomp the cr/nl implicitly, sometimes you want to raw 
     un-chomped one"
    |chars len rlen pos|
    self atEnd ifTrue: [ ^nil ].
    pos := self position.
    chars := self nextLine.
    "nextLine is already chomp'ed, so we need to recover"
    rlen := self position - pos.
    len := chars size.          
    "rlen can only be:
     len, at eof so no nl missing, or
     len + 1, one nl missing, or
     len + 2, dos EOL, cr + nl"
    (len == rlen) ifFalse: [
        (len + 2 == rlen) ifTrue: [ 
            chars := chars copyWith: ##(Character cr).
            len := len + 1 ].
            chars := chars copyWith: ##(Character nl).
            len := len + 1 ].
    (len == rlen) ifFalse: [
        self error: 'length mismatch' ].
    ^chars!
!

!String methodsFor: 'perl style chomp'!
chomp 
    "trim nl or cr from the end of self"
    ^self copyFrom: 1 to: (self findLast: [ :ch |
            (ch ~= Character nl) & (ch ~= Character cr) ])!
!

!Collection methodsFor: 'uniquifying'!

uniquify
    |ds|
    ds := IdentitySet new.
    "remove duplicates"
    ds addAll: self.
    ^ds asArray!
!

!Dictionary methodsFor: 'generate unique key'!

"aKey is a string. If aKey does not exist, return aKey. Otherwise, return
aKey_{salt} so that the new key does not exist in the receiver"
uniqueKeyLike: aKey
    |newKey salt|
    (self includesKey: aKey) ifFalse: [ ^aKey ].
    salt := 0.
    [ salt := salt + 1.
      newKey := '%1_%2' % {aKey. salt}.
      self includesKey: newKey
        ] whileTrue.
    ^ newKey!
!
