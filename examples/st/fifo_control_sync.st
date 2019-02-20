DANMSchematic subclass: DANMSchematic_fifo_control_sync [
    <comment: nil>
    <category: ''>

    subpressDangleCheck [
	"some pin are unloaded"
	<category: 'accessing'>
	^true
    ]

    masterDepth [
	<category: 'accessing'>
	(self hasParameter: 'master_depth') ifFalse: [^11].
	^self parameterValue: 'master_depth'
    ]

    masterDepthWidth [
	<category: 'accessing'>
	^(self masterDepth log: 2) ceiling
    ]

    slowSlave [
	"slow the rdy by one cycle to help timing. This is useful for deep fifo"
	<category: 'accessing'>
	(self hasParameter: 'slow_slave') ifFalse: [^self delayAddr].
	^(self parameterValue: 'slow_slave') = 1
    ]

    slowMaster [
	"slow the rdy by one cycle to help timing. This is useful for deep fifo"
	<category: 'accessing'>
	(self hasParameter: 'slow_master') ifFalse: [^self delayAddr].
	^(self parameterValue: 'slow_master') = 1
    ]

    slaveDepth [
	<category: 'accessing'>
	(self hasParameter: 'slave_depth') ifFalse: [^self masterDepth].
	^self parameterValue: 'slave_depth'
    ]

    slaveDepthWidth [
	<category: 'accessing'>
	^(self slaveDepth log: 2) ceiling
    ]

    delayAddr [
	"whether to delay the addr to the other side. This is to protect
	 real ram from hazard"
	<category: 'accessing'>
	(self hasParameter: 'delay_addr') ifFalse: [^false].
	^(self parameterValue: 'delay_addr') = 1
    ]

    init [
	<category: 'construction'>
	self 
	    comment: 'i am a synchronized fifo controller that convert data from 
one end (master) to another (slave). master and slave sides are
synchronized to eachother however with different enables. master side 
initiate the data flow and slave side follows. master side and slave side
may have different width with ratio as power of 2. Could be 1:2 or 2:1, etc.
The depth of the fifo depends on the buffering requirement'.
	self
	    createPort: 'clk';
	    createPort: 'reset_';
	    createPort: 'master_en';
	    createPort: 'master_rdy';
	    createPort: 'master_addr' width: self masterDepthWidth;
	    createPort: 'slave_en';
	    createPort: 'slave_rdy';
	    createPort: 'slave_addr' width: self slaveDepthWidth.
	"master side interface"
	"slave side interface"
	(self addInstanceOf: 'half_fifo_control' name: 'master')
	    setParameter: 'slow_start' to: (self slowMaster ifTrue: [1] ifFalse: [0]);
	    setParameter: 'depth' to: self masterDepth.
	(self addInstanceOf: 'half_fifo_control' name: 'slave')
	    setParameter: 'slow_start' to: (self slowSlave ifTrue: [1] ifFalse: [0]);
	    setParameter: 'depth' to: self slaveDepth.
	self connect: {'master/next_addr'} name: 'next_master_addr'.
	self connect: {'slave/next_addr'} name: 'next_slave_addr'.
	self connect: {'master/other_addr'} name: 'slave_addr_master'.
	self connect: {'slave/other_addr'} name: 'master_addr_slave'.
	self connect: {'master/gap'} name: 'master_gap'.
	self connect: {'master/en'} name: 'master_en'.
	self connect: {'master/rdy'} name: 'master_rdy'.
	self connect: {'master/addr'} name: 'master_addr'.
	self connect: {'master/is_master'} name: 'one'.
	self connect: {'slave/en'} name: 'slave_en'.
	self connect: {'slave/gap'} name: 'slave_gap'.
	self connect: {'slave/rdy'} name: 'slave_rdy'.
	self connect: {'slave/addr'} name: 'slave_addr'.
	self connect: {'slave/is_master'} name: 'zero'.
	self connect: {'master/other_addr_changed'} name: 'slave_addr_changed'.
	self connect: {'slave/other_addr_changed'} name: 'master_addr_changed'.
	self
	    let: 'one' be: '1b1';
	    let: 'zero' be: '1b0'.
	self delayAddr 
	    ifTrue: [
		self
		    let: 'slave_addr_changed' be: 'slave_en$clk$clk';
		    let: 'master_addr_changed' be: 'master_en$clk$clk';
		    let: 'slave_addr_d' be: 'slave_addr$clk';
		    let: 'master_addr_d' be: 'master_addr$clk' ]
	    ifFalse: [
		self
		    let: 'slave_addr_changed' be: 'slave_en$clk';
		    let: 'master_addr_changed' be: 'master_en$clk';
		    let: 'slave_addr_d' be: 'slave_addr';
		    let: 'master_addr_d' be: 'master_addr' ].

	"keep msb, pad zero or truncate"
	self masterDepthWidth > self slaveDepthWidth ifTrue: [
	    self
                let: 'slave_addr_master' be: 'slave_addr_d,%1d0' %
		{self masterDepthWidth - self slaveDepthWidth};
		let: 'master_addr_slave' be: 'master_addr_d[%1:%2]' %
		{self masterDepthWidth - 1. self masterDepthWidth - self slaveDepthWidth} ].
	self masterDepthWidth < self slaveDepthWidth ifTrue: [
	    self
		let: 'slave_addr_master' be: 'slave_addr_d[%1:%2]' %
		{self slaveDepthWidth - 1. self slaveDepthWidth - self masterDepthWidth};
		let: 'master_addr_slave' be: 'master_addr_d,%1d0' %
		{self slaveDepthWidth - self masterDepthWidth} ].
	self masterDepthWidth = self slaveDepthWidth ifTrue: [
	    self
		let: 'slave_addr_master' be: 'slave_addr_d';
		let: 'master_addr_slave' be: 'master_addr_d' ].
	self autoConnect.
	self autoExposeInputs.
	self autoExposeOutputs
    ]
]

