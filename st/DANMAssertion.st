DANMExpressionWire subclass: #DANMAssertion
         instanceVariableNames: ''
         classVariableNames: ''
         poolDictionaries: ''
         category: 'DANM'!

DANMAssertion comment: 'I am an assertion in simulation, the value has to be 
as expected, otherwise simulation will abort'!

!DANMAssertion methodsFor: 'basic'!

isLoaded
    "supress unloaded warning for assertion"
    ^true!

flip
    super flip.
    value == 0 ifTrue: [ 
        Transcript nextPutAll: 'Assertion %1 failed in %2!' %
            {entityName. self context fullPath}; nl.
        "in simulation the design is flattened, so context context is the 
simulator"
        (context context isKindOf: DANMSimulator) ifTrue: [ 
            context context stop: self]]!
!

!DANMAssertion methodsFor: 'printing'!

nodeStyle
    ^'[shape=diamond]'!

printOn: aStream
    aStream nextPutAll: ('<%1> ' % {expression})!

printHTMLHeadOn: aStream
    aStream 
        nextPutAll: ('<h3><a name="WIRE_%1">Assertion %1</a></h3><ul>' 
                         % {entityName});
        nl;
        nextPutAll: '<li>condition: %1</li>' % 
            {expression printStringStyle: #HTML};
        nl!

basicPrintVerilogOn: aStream
    super basicPrintVerilogOn: aStream.
    aStream nextPutAll: '`ASSERT(%1, %2)' % 
        {self verilogName. self context fullPath}; nl!
!
