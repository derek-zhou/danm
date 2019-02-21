Float extend [

    printOn: aStream precision: p [
	"print the float with p digit after ."
	<category: 'precision printing'>
	| up int frac fracStr ratio |
	ratio := 10 raisedToInteger: p.
	up := (self * ratio + 0.5) floor.
	self >= 0 ifFalse: [
	    aStream nextPut: $-.
	    (up = 0) - up ].
	int := up // ratio.
	frac := up \\ ratio.
	aStream nextPutAll: int printString.
	frac == 0 ifTrue: [^self].
	fracStr := frac printString.
	aStream
	    nextPut: $.;
	    next: p - fracStr size put: $0;
	    nextPutAll: fracStr
    ]

    printStringWithPrecision: p [
	<category: 'precision printing'>
	| stream |
	stream := String new writeStream.
	self printOn: stream precision: p.
	^stream contents
    ]

]

String extend [

    rightAdjust: len [
	"return a new sting which is receiver right adjusted to len with space padding"
	<category: 'adjusting'>
	| stream padding meat |
	stream := (String new: len) writeStream.
	self size <= len 
	    ifTrue: [
		padding := len - self size.
		meat := self ]
	    ifFalse: [
		padding := 0.
		meat := self copyFrom: self size - len + 1 ].
	stream
	    space: padding;
	    nextPutAll: meat.
	^stream contents
    ]

    leftAdjust: len [
	"return a new sting which is receiver left adjusted to len with space padding"
	<category: 'adjusting'>
	| stream padding meat |
	stream := (String new: len) writeStream.
	self size <= len 
	    ifTrue: [
		padding := len - self size.
		meat := self ]
	    ifFalse: [
		padding := 0.
		meat := self copyFrom: 1 to: len ].
	stream
	    nextPutAll: meat;
	    space: padding.
	^stream contents
    ]

]

Object subclass: DataPoint [
    | name value weight |
    <category: ''>
    <comment: 'I have a name and value representing a data sample point'>

    DataPoint class >> newName: n value: v weight: w [
	<category: 'instance creation'>
	^(self new)
	    name: n;
	    value: v;
	    weight: w
    ]

    name [
	<category: 'accessing'>
	^name
    ]

    value [
	<category: 'accessing'>
	^value
    ]

    weight [
	<category: 'accessing'>
	^weight
    ]

    name: n [
	<category: 'accessing'>
	name := n
    ]

    value: v [
	<category: 'accessing'>
	value := v
    ]

    weight: w [
	<category: 'accessing'>
	weight := w
    ]

    <= anotherData [
	<category: 'accessing'>
	^value <= anotherData value
    ]
]

Object subclass: DistributionPlot [
    | data lowend highend buckets thresholds |
    
    <category: ''>
    <comment: nil>

    height := nil.
    width := nil.

    DistributionPlot class >> list: data [
	<category: 'instance creation'>
	^(self new)
	    data: data;
	    list
    ]

    DistributionPlot class >> plot: data [
	<category: 'instance creation'>
	height := 20.
	width := 50.
	^(self new)
	    data: data;
	    plot
    ]

    DistributionPlot class >> test: num [
	<category: 'instance creation'>
	| data |
	data := (1 to: num) collect: [:i | 
	    | v |
	    v := (1 to: 4) inject: 0 into: [ :s :i | s + Random next ].
	    DataPoint newName: 'a' value: v weight: 1 ].
	Transcript nl.
	self plot: data
    ]

    data [
	<category: 'accessing'>
	^data
    ]

    data: d [
	<category: 'accessing'>
	data := d
    ]

    list [
	<category: 'plot'>
	data := data asSortedCollection.
	lowend := data first value.
	highend := data last value.
	buckets := (1 to: highend - lowend + 1) collect: [:i | 0].
	data do: [:each | 
	    | index |
	    index := each value - lowend + 1.
	    buckets at: index put: (buckets at: index) + each weight].
	Transcript nextPutAll: '----------------'; nl.
	lowend to: highend do: [:y | 
	    Transcript
		nextPutAll: (y printString leftAdjust: 4);
		nextPutAll: '| %1' % {buckets at: y + 1 - lowend}; nl].
	Transcript nextPutAll: 'Max is %1 at: %2' % 
	    {data last name. data last value}; nl
    ]

    plot [
	<category: 'plot'>
	data := data asSortedCollection.
	self makeRange.
	self makeBuckets.
	self printPlot
    ]

    makeRange [
	<category: 'plot'>
	| l1 h1 s cut r0 |
	cut := 0.00135.	"correspond to 3 sigma for normal distribution"
	s := data size.
	lowend := data first value.
	highend := data last value.
	r0 := highend - lowend.
	r0 == 0 ifTrue: [^self].
	l1 := (data at: (s * cut) ceiling) value.
	h1 := (data at: (s * (1 - cut)) ceiling) value.
	"use shrinked range if it is more than 10% smaller"
	(l1 - lowend) / r0 > 0.1 ifTrue: [lowend := l1].
	(highend - h1) / r0 > 0.1 ifTrue: [highend := h1]
    ]

    makeBuckets [
	<category: 'plot'>
	| step index |
	step := (highend - lowend) / width.
	buckets := Array new: width + 2.
	thresholds := {lowend}  , (
	    (2 to: width) collect: [:i |
		(lowend + (i - 1)) * step ]
	    ) , {highend}.
	buckets := (1 to: width + 2) collect: [:i | 0].
	index := 1.
	data do: [:each | 
	    each value > highend 
		ifTrue: [
		    index := width + 2 ]
		ifFalse: [
		    [ each value > (thresholds at: index) ] whileTrue: [
			index := index + 1 ]].
	    buckets at: index put: (buckets at: index) + each weight ]
    ]

    printPlot [
	<category: 'plot'>
	| hStep maxNum char |
	maxNum := buckets fold: [:a :b | a max: b].
	hStep := (maxNum + height - 1) // height.
	Transcript
	    nextPutAll: 'Max is %1 at: %2' % {data last name.  data last value};  nl;
	    nextPutAll: 'Min is %1 at: %2' % {data first name. data first value}; nl;
	    nextPutAll: 'Each * is '; print: hStep; cr.
	height to: 1 by: -1 do: [:y | 
	    y \\ 5 = 0 ifTrue: [char := $#] ifFalse: [char := $*].
	    Transcript nextPutAll: ' '.
	    1 to: width + 2 do: [:x | 
		(buckets at: x) > ((y - 1) * hStep) 
		    ifTrue:  [ Transcript nextPut: char ]
		    ifFalse: [ Transcript nextPut: Character space ]].
	    Transcript cr ].
	Transcript nextPutAll: '-+---------+---------+---------+---------+---------+>'; cr; space.
	0 to: 5 do: [:i | 
	    Transcript nextPutAll: (((thresholds at: i * 10 + 1) asFloat 
			    printStringWithPrecision: 3) leftAdjust: 10) ].
	Transcript cr; cr
    ]
]

DANMSchematic extend [

    reportStatistic [
	<category: 'statistic'>
	self reportInstances.
	self reportWires.
	self reportEvaluationOrder.
	self reportComplexity
    ]

    reportEvaluationOrder [
	<category: 'statistic'>
	Transcript nextPutAll: 'evaluation order distribution:'; nl.
	DistributionPlot list: (
	    wires collect: [ :each | 
		DataPoint newName: each name value: each evaluationOrder weight: each width ])
    ]

    reportComplexity [
	<category: 'statistic'>
	Transcript nextPutAll: 'complexity distribution:'; nl.
	DistributionPlot list: (
	    wires collect: [ :each | 
		DataPoint newName: each name value: each complexity weight: each width ])
    ]

    reportInstances [
	<category: 'statistic'>
	| c1 |
	c1 := 0.
	instances do: [:each |
	    (each isMemberOf: DANMBlackBox) ifTrue: [c1 := c1 + 1 ]].
	Transcript
	    nextPutAll: '%1 instances:' % {instances size}; nl;
	    nextPutAll: '  %1 of them are blackboxes' % {c1}; nl
    ]

    reportWires [
	<category: 'statistic'>
	| c1 c2 c3 b0 b1 b2 b3 |
	c1 := 0.
	c2 := 0.
	c3 := 0.
	b0 := 0.
	b1 := 0.
	b2 := 0.
	b3 := 0.
	wires do: [ :each | 
	    | w |
	    w := each width.
	    b0 := b0 + w.
	    (each isKindOf: DANMExpressionWire) ifTrue: [
		c1 := c1 + 1.
		b1 := b1 + w.
		(each isKindOf: DANMFlipflop) ifTrue: [
		    c2 := c2 + 1.
		    b2 := b2 + w ].
		(each isKindOf: DANMLatch) ifTrue: [
		    c3 := c3 + 1.
		    b3 := b3 + w ]]].
	Transcript
	    nextPutAll: '%1 wires (%2 bits):' % {wires size. b0}; nl;
	    nextPutAll: '  %1 (%2 bits) of them are expressions:' % {c1. b1}; nl;
	    nextPutAll: '    %1 (%2 bits) of them are flipflops' % {c2. b2}; nl;
	    nextPutAll: '    %1 (%2 bits) of them are latches' % {c3. b3}; nl
    ]

]
