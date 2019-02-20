DANMSchematic subclass: DANMSchematic_sync_fifo [    
    <comment: 'I am a synchronous fifo'>
    <category: ''>

    subpressDangleCheck [
	"I have many dangles by design"
	<category: 'accessing'>
	^true
    ]

    depth [
	<category: 'accessing'>
	(self hasParameter: 'depth') ifFalse: [^2].
	^self parameterValue: 'depth'
    ]

    width [
	<category: 'accessing'>
	(self hasParameter: 'width') ifFalse: [^64].
	^self parameterValue: 'width'
    ]

    slowSlave [
	"slow the rdy by one cycle to help timing. This is useful for deep fifo"
	<category: 'accessing'>
	(self hasParameter: 'slow_slave') ifFalse: [^false].
	^(self parameterValue: 'slow_slave') = 1
    ]

    slowMaster [
	"slow the rdy by one cycle to help timing. This is useful for deep fifo"
	<category: 'accessing'>
	(self hasParameter: 'slow_master') ifFalse: [^false].
	^(self parameterValue: 'slow_master') = 1
    ]

    depthWidth [
	<category: 'accessing'>
	^(self depth log: 2) ceiling
    ]

    init [
	<category: 'construction'>
	self
	    createPort: 'clk';
	    createPort: 'reset_';
	    createPort: 'din' width: self width;
	    createPort: 'dout' width: self width;
	    createPort: 'master_en';
	    createPort: 'master_rdy';
	    createPort: 'slave_en';
	    createPort: 'slave_rdy'.

	"input data shall not contain x"
	self assert: '(master_en?((^din==1b1)|(^din==1b0)):1)$clk'.
	"a one deep fifo maks some sense in certain case. Please note
	 it cannot be fully pipelined"
	self depth == 1 ifTrue: [
	    self defaultClock: 'clk'.
	    self let: 'master_rdy' beClockedIfs: 
		{ '~reset_' -> '1b1'.
		  'master_en' -> '1b0'.
		  'slave_en' -> '1b1' }.
	    self let: 'slave_rdy' be: '~master_rdy'.
	    self let: 'dout' beClockedIfs: {'master_en' -> 'din'}.
	    ^self ].
	(self addInstanceOf: 'fifo_control_sync' name: 'control')
	    setParameter: 'slow_slave' to: (self slowSlave ifTrue: [1] ifFalse: [0]);
	    setParameter: 'slow_master' to: (self slowMaster ifTrue: [1] ifFalse: [0]);
	    setParameter: 'master_depth' to: self depth.
	(self addInstanceOf: 'dpram_simple' name: 'ram')
	    setParameter: 'depth' to: self depth;
	    setParameter: 'depth_width' to: self depthWidth;
	    setParameter: 'width' to: self width.
	self connect: {'control/master_addr'. 'ram/addr_in'}.
	self connect: {'control/slave_addr'. 'ram/addr_out'}.
	self connect: {'control/master_en'. 'ram/we'} name: 'master_en'.
	self
	    autoConnect;
	    conceal: 'next_slave_addr';
	    conceal: 'next_master_addr';
	    autoExposeOutputs
    ]
]
