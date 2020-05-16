DANMSchematic subclass: DANMSchematic_scan_arbiter [
    
    <comment: 'I am a round robin arbiter, that grant access according to request in a fair way by scanning forward. Unlike rr_arbiter, I am completely fair but bigger and slower'>
    <category: ''>

    subpressDangleCheck [
	<category: 'accessing'>
	^true
    ]

    width [
	<category: 'accessing'>
	(self hasParameter: 'width') ifFalse: [^2].
	^self parameterValue: 'width'
    ]

    init [
	<category: 'construction'>
	| string |
	self
	    createPort: 'clk';
	    createPort: 'reset_';
	    createPort: 'request' width: self width;
	    createPort: 'grant' width: self width;
	    createPort: 'client_en' width: self width;
	    createPort: 'busy'.
	"one bit from each client, deassert after grant"
	"one cycle pulse back to each client"
	"latch and hold grant until not busy"
	"assert after grant, deassert after release"

	"it is possible that busy is not asserted in the same cycle"
	self let: 'lag' beIfs: {
	    '~reset_' -> '1b0'.
	    'busy' -> '1b0'.
	    '|request' -> '1b1' }  clockedBy: 'clk'.
	0 to: self width - 1 do: [
	    :i | 
	    self let: 'client%1_en' % {i} beIfs: {
		'~reset_' -> '1b0'.
		'grant[%1]' % {i} -> '1b1'.
		'~(busy|lag)' -> '1b0' } clockedBy: 'clk'.
	    i == 0
	      ifTrue: [string := 'client0_en']
	      ifFalse: [string := 'client%1_en,' % {i} , string]].
	self let: 'client_en' be: string.

	"degenerated case"
	self width = 1 ifTrue: [
	    self let: 'grant' be: '(busy|lag)?0:request'.
	    ^self ].
	self let: 'last' beIfs: {
	    '~reset_' -> ('%1d%2' % {self width. 2 raisedTo: self width - 1}).
	    '~(busy|lag)&|request' -> 'next' } clockedBy: 'clk'.
	(self addInstanceOf: 'bitscan' name: 'scanner')
	    setParameter: 'width' to: self width.
	self connect: {'scanner/in'} name: 'request'.
	self connect: {'scanner/last'} to: 'last, 1b0'.
	self connect: {'scanner/out'} name: 'next'.
	self let: 'grant' be: '(busy|lag)?0:(next[%1:%2]&~next[%3:0],next[0])' %
	     {self width - 1. 1. self width - 2}
    ]
]
