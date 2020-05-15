DANMSchematic subclass: DANMSchematic_rrscan_arbiter [
    
    <comment: 'I am a round robin arbiter, that grant access according to request. 
If you care about fairness, do not use me and use scan_arbiter instead.
I am smaller and faster, but imprecise. I do not waste cycle and I will not
starve anyone.'>
    <category: ''>

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
	(self addInstanceOf: 'rr_arbiter' name: 'arb') setParameter: 'width'
	    to: self width.
	self let: 'long_busy' be: 'lag|busy'.

	"it is possible that busy is not asserted in the same cycle"
	self 
	    let: 'lag'
	    beIfs: 
		{'~reset_' -> '1b0'.
		'busy' -> '1b0'.
		'|request' -> '1b1'}
	    clockedBy: 'clk'.
	0 to: self width - 1
	    do: 
		[:i | 
		self 
		    let: 'client%1_en' % {i}
		    beIfs: 
			{'~reset_' -> '1b0'.
			'grant[%1]' % {i} -> '1b1'.
			'~long_busy' -> '1b0'}
		    clockedBy: 'clk'.
		i == 0 
		    ifTrue: [string := 'client0_en']
		    ifFalse: [string := 'client%1_en,' % {i} , string]].
	self let: 'client_en' be: string.
	self connect: {'arb/busy'} name: 'long_busy'.
	self autoConnect
    ]
]

