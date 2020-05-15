DANMSchematic subclass: DANMSchematic_bitscan [
    <comment: 'I detact the first bit that is 1 after the location indicated by
a thermometer code:
111 -> 0
110 -> 1
100 -> 2.'>
    <category: ''>

    subpressDangleCheck [
	"I have many dangles by design"
	<category: 'accessing'>
	^true
    ]

    width [
	<category: 'accessing'>
	(self hasParameter: 'width') ifFalse: [^8].
	^self parameterValue: 'width'
    ]

    init [
	"inputs"

	<category: 'construction'>
	self
	    createPort: 'in' width: self width;
	    createPort: 'last' width: self width + 1;
	    createPort: 'out' width: self width;
	    createPort: 'exist';
	    createPort: 'exist_right'.

	"degenerated case"
	self width == 1 ifTrue: [
	    self let: 'exist' be: 'in'.
	    self let: 'exist_right' be: '~last[1]&in'.
	    self let: 'out' be: 'in'.
	    ^self ].
	(self addInstanceOf: 'bitscan' name: 'top')
	    setParameter: 'width' to: (self width / 2) ceiling.
	(self addInstanceOf: 'bitscan' name: 'bottom')
	    setParameter: 'width' to: (self width / 2) floor.
	self connect: {'top/in'} name: 'top_in'.
	self connect: {'top/last'} name: 'top_last'.
	self connect: {'top/out'} name: 'top_out'.
	self connect: {'top/exist'} name: 'top_exist'.
	self connect: {'top/exist_right'} name: 'top_exist_right'.
	self connect: {'bottom/in'} name: 'bottom_in'.
	self connect: {'bottom/last'} name: 'bottom_last'.
	self connect: {'bottom/out'} name: 'bottom_out'.
	self connect: {'bottom/exist'} name: 'bottom_exist'.
	self connect: {'bottom/exist_right'} name: 'bottom_exist_right'.
	self let: 'top_in' be: 'in[%1:%2]' % 
	     {self width - 1. (self width / 2) floor}.
	self let: 'bottom_in' be: 'in[%1:0]' % {(self width / 2) floor - 1}.
	self let: 'top_last' be: 'last[%1:%2]' % 
	     {self width. (self width / 2) floor}.
	self let: 'bottom_last' be: 'last[%1:0]' % {(self width / 2) floor}.
	self let: 'exist' be: 'top_exist|bottom_exist'.
	self let: 'exist_right' be: 'top_exist_right|bottom_exist_right'.
	self let: 'drop_top'
	     be: '(~top_exist_right&bottom_exist_right)|(~top_exist&bottom_exist)'.
	self let: 'drop_bottom'
	     be: 'top_exist_right|(~bottom_exist_right&top_exist)'.
	self let: 'top_mask' be: 'drop_top*%1' % {(self width / 2) ceiling}.
	self let: 'bottom_mask' be: '~drop_bottom*%1' % {(self width / 2) floor}.
	self let: 'out' be: '(top_out|top_mask), (bottom_out&bottom_mask)'
    ]
]

