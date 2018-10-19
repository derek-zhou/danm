DANMSchematic subclass: #DANMSchematic_half_fifo_control!

!DANMSchematic_half_fifo_control methodsFor: 'accessing'!

depth
    (self hasParameter: 'depth') ifFalse: [ ^8 ].
    ^self parameterValue: 'depth'!

depthWidth
    ^(self depth log: 2) ceiling!

slowStart
    "slow the rdy by one cycle to help timing. This is useful for deep fifo"
    (self hasParameter: 'slow_start') ifFalse: [ ^self depthWidth >= 6 ].
    ^(self parameterValue: 'slow_start')=1!
!

!DANMSchematic_half_fifo_control methodsFor: 'construction'!

init
    self comment: 'i am one side of a fifo controller'.
    self 
        "master side interface"
        createPort: 'clk';
        createPort: 'reset_';
        createPort: 'en';
        createPort: 'rdy';
        createPort: 'is_master';
        createPort: 'next_addr' width: self depthWidth;
        createPort: 'addr' width: self depthWidth;
        createPort: 'other_addr' width: self depthWidth;
        createPort: 'other_addr_changed';
        createPort: 'gap' width: self depthWidth.
            
        "initially, fifo is empty"
        self defaultClock: 'clk'.
        self let: 'legal' beAssertion: '(rdy|(~en)|(~reset_))$clk'.
        self let: 'next_addr' beIfs: 
            { '~en' -> 'addr'.
              'addr==%1' % {self depth - 1} -> 
                  ('%1d0' % {self depthWidth}).
              1 -> 'addr+1' }.
        self let: 'addr' beClockedIfs: 
            { '~reset_' -> ('%1d0' % {self depthWidth}).
              1 -> 'next_addr'}.
        self let: 'rdy_reg' beClockedIfs: 
            { '~reset_' -> 'is_master'.
              'en&(next_addr==other_addr)' -> '1b0'.
              'other_addr_changed' -> '1b1'}.
        "other addr can change due to reset"
	self slowStart
	    ifTrue: [ self let: 'rdy' be: 'rdy_reg' ]
	    ifFalse: [ self let: 'rdy' be: 'rdy_reg|(other_addr_changed&reset_)' ].
        self let: 'gap' be: 'other_addr-addr'!
!
