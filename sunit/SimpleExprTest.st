DynamicVariable subclass: DANMCurrentDesign [
    <category: ''>
    <comment: ''>
].

"mock a schematic with parameter"
Object subclass: MockSch [
    |parameters|

    parameters: params [
	<category: 'accessing'>
	parameters := LookupTable from: params
    ]

    parameter: pName [
	<category: 'accessing'>
	parameters isNil ifTrue: [parameters := LookupTable new].
	^parameters at: pName ifAbsent: [nil]
    ]
]

TestCase subclass: SimpleExprTest [
    <comment: 'test for simple expression parsing and evaluating'>

    parseError: str with: dict [
	|sch|
	sch := MockSch new.
	sch parameters: dict.
	DANMCurrentDesign use: sch during: [a+b)*
	    [ (SimpleExprParser newFromString: str) parse ]
		ifError: [ ^self ]
	].
	self error: 'Should have raise an error'
    ]

    parse: str with: dict expect: v [
	|sch|
	sch := MockSch new.
	sch parameters: dict.
	DANMCurrentDesign use: sch during: [
	    self should: [
		(SimpleExprParser newFromString: str) parse optimize value == v ]]
    ]

    testUnfoundIdentifier [
	^self parseError: '(a+b)*c' with: {'a'->2. 'b'->3}
    ]

    testAddMul [
	^self parse: '(-1+b)*c-a' with: {'a'->2. 'b'->3. 'c'->5} expect: 8
    ]

    testNegation [
	^self parse: '(b-a)*c' with: {'a'->-2. 'b'->3. 'c'->5} expect: 25
    ]
 
]
