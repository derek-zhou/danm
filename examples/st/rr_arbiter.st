DANMSchematic subclass: #DANMSchematic_rr_arbiter!

DANMSchematic_rr_arbiter comment:
    'I am a round robin arbiter, that grant access according to request. 
If you care about fairness, do not use me and use scan_arbiter instead.
I am smaller and faster, but imprecise. I do not waste cycle and I will not
starve anyone.'!

!DANMSchematic_rr_arbiter methodsFor: 'accessing'!

width
    (self hasParameter: 'width') ifFalse: [ ^8 ].
    ^self parameterValue: 'width'!
!

!DANMSchematic_rr_arbiter methodsFor: 'construction'!

init
    self
        "one bit from each client, deassert after grant"
        createPort: 'request' width: self width;
        "one cycle pulse back to each client"
        createPort: 'grant' width: self width;
        createPort: 'exist';
        "assert after grant, deassert after release"
        createPort: 'busy'.

    "degenerated case"
    self width == 1 ifTrue: [
        self let: 'grant' be: 'request&~busy'.
        self let: 'exist' be: 'request'.
        ^self ].
    
    self 
        createPort: 'clk';
        createPort: 'reset_'.

    (self addInstanceOf: 'rr_arbiter' name: 'top')
        setParameter: 'width' to: (self width / 2) ceiling.
    (self addInstanceOf: 'rr_arbiter' name: 'bottom')
        setParameter: 'width' to: (self width / 2) floor.
    
    self connect: {'top/grant'} name: 'top_grant'. 
    self connect: {'top/request'} name: 'top_requests'. 
    self connect: {'top/exist'} name: 'top_exist'. 
    self connect: {'top/busy'} name: 'top_busy'. 
    self connect: {'bottom/grant'} name: 'bottom_grant'. 
    self connect: {'bottom/request'} name: 'bottom_requests'.
    self connect: {'bottom/exist'} name: 'bottom_exist'. 
    self connect: {'bottom/busy'} name: 'bottom_busy'. 
    self let: 'top_requests' be: 'request[%1:%2]' %
        { self width - 1. (self width / 2) floor}.
    self let: 'bottom_requests' be: 'request[%1:0]' %
        { (self width / 2) floor - 1}.

    self let: 'exist' be: 'top_exist|bottom_exist'.
    self let: 'next' be: 'state?~bottom_exist:top_exist'.
    self let: 'state' beIfs: 
        { '~reset_' -> '1b0'.
          '~busy' -> 'next' } clockedBy: 'clk'.
    self let: 'top_busy' be: 'busy|(state&bottom_exist)'.
    self let: 'bottom_busy' be: 'busy|(~state&top_exist)'.
    self let: 'grant' be: 'top_grant,bottom_grant'.
    self autoConnect!
!


