DANMBlackBox extend [

    generateHTML [
	<category: 'html-printing'>
	"entity name may contain /, create all the dir"
	| fs dir |
	dir := entityName copyUpToLast: $/.
	dir = entityName ifFalse: [(File name: dir) createDirectories].
	fs := (File name: '%1.html' % {entityName}) writeStream.
	[self printHTMLOn: fs] ensure: [fs close]
    ]

    hideInHTML [
	<category: 'html-printing'>
	^false
    ]

    printHTMLOn: aStream [
	<category: 'html-printing'>
	self printHTMLHeaderOn: aStream.
	self printHTMLPortSummaryOn: aStream.
	self printHTMLPortsOn: aStream.
	self printHTMLFooterOn: aStream
    ]

    printHTMLPortSummaryOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<h2>Port Summary</h2><table  border="1">'; nl;
	    nextPutAll: '<tr><th>port name</th><th>direction</th><th>width</th></tr>'; nl.
	ports asSortedCollection do: [ :p | 
	    aStream nextPutAll: '<tr><td><a href="#WIRE_%1">%1</a></td><td>%2</td><td>%3</td></tr>' %
		{p name. p direction asString. p width}; nl].
	aStream nextPutAll: '</table><hr/>'; nl
    ]

    printHTMLSummaryOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<tr><td>%1</td><td><a href="#INST_%1">instance</a></td><td><a href="%2/%1.html">%3</a></td></tr>' %
	    {entityName. context name. self type}; nl
    ]

    printHTMLHeaderOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<html><head><title>'; nl;
	    nextPutAll: '%1 (%2 %3) Documentation' % 
	    {self fullPath. self type. self referenceName}; nl;
	    nextPutAll: '</title></head><body>'; nl;
	    nextPutAll: '<p><a href="%1hierarchy.html">Hierarchy</a>' % {self topPath}.
	context notNil ifTrue: [
	    aStream
		nextPutAll: ' | <a href="../%1.html#INST_%2">Up (%1)</a>' % 
		{context name. entityName}; nl].
	aStream
	    nextPutAll: ' | <a href="%1top.html">Top</a></p>' % {self topPath}; nl;
	    nextPutAll: '<h1>%1 (%2 %3) Documentation</h1>' %
	    {self fullPath. self type. self referenceName}; nl;
	    nextPutAll: '<p>%1</p>' % {self comment};
	    nextPutAll: '<p>Defined in: %1</p><hr/>' % {self referencePath}; nl
    ]

    printHTMLFooterOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<p>This document is generated on %1' % {DateTime now}; nl;
	    nextPutAll: '</p></body></html>'; nl
    ]

    printHTMLHierOn: aStream [
	<category: 'html-printing'>
	^self
    ]

    printHTMLPortsOn: aStream [
	<category: 'html-printing'>
	aStream nextPutAll: '<h2>%1 ports</h2><ul>' % {ports size}; nl.
	ports asSortedCollection do: [ :w | 
	    aStream nextPutAll: '<li>'.
	    w printHTMLOn: aStream.
	    aStream nextPutAll: '</li>'; nl].
	aStream nextPutAll: '</ul><hr/>'; nl
    ]

    printHTMLParametersOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<li>Parameters:<table  border="1">'; nl;
	    nextPutAll: '<tr><th>parameter name</th><th>value</th></tr>'; nl.
	parameters keys asSortedCollection do: [:k | 
	    aStream
		nextPutAll: '<tr><td>%1</td><td>%2</td></tr>' %
		{k. (parameters at: k) printStringStyle: #HTML}; nl].
	aStream nextPutAll: '</table></li>'; nl
    ]

    printInstanceHTMLOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<h3>Instance <a name="INST_%1">%1</a>(%2) <a href="%3/%1.html">%4</a></h3>' % 
	    {entityName. self referenceName. context name. self type}; nl;
	    nextPutAll: '<ul><li>Defined in: %1</li>' % {self referencePath}; nl.
	connections size > 0 ifTrue: [self printHTMLConnectionsOn: aStream].
	parameters notNil ifTrue: [self printHTMLParametersOn: aStream].
	aStream nextPutAll: '</ul>'; nl
    ]

    printHTMLConnectionsOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<li>Connections:<table  border="1">'; nl;
	    nextPutAll: '<tr><th>port name</th><th>direction</th><th>width</th><th>wire</th></tr>'; nl.
	ports asSortedCollection do: [:p | 
	    | w wName |
	    w := self wireOnPort: p.
	    wName := w isNil ifTrue: ['nil'] ifFalse: [w name].
	    aStream
		nextPutAll: '<tr><td><a href="%1/%2.html#WIRE_%3">%3</a></td><td>%4</td><td>%5</td><td><a href="#WIRE_%6">%6</a></td></tr>' % 
		{context name. entityName. p name. p direction asString. p width. wName}; nl].
	aStream nextPutAll: '</table></li>'; nl
    ]

]

DANMSchematic extend [

    generateHTMLAsTop [
	<category: 'html-printing'>
	^self generateHTMLAsTopIn: '%1_html'
    ]

    generateHTMLAsTopIn: dirName [
	<category: 'html-printing'>
	| fs savedDir dir |
	dir := File name: dirName.
	dir exists ifFalse: [dir createDirectory].
	savedDir := Directory working.
	Directory working: dir.
	self generateHTML.
	fs := (File name: 'hierarchy.html') writeStream.
	[self printFullHTMLHierOn: fs] ensure: [fs close].
	Directory working: savedDir
    ]

    printFullHTMLHierOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<html><head>'; nl;
	    nextPutAll: '<title>Module Hierachy</title>'; nl;
	    nextPutAll: '</head><body>'; nl;
	    nextPutAll: '<p><a href="hierarchy.html">Hierarchy</a> | <a href="%1.html">Top</a></p>' %
	    {self name}; nl;
	    nextPutAll: '<h1>Module Hierarchy</h1>'; nl;
	    nextPutAll: '<div id="tree">'; nl.
	self printHTMLHierOn: aStream.
	aStream
	    nextPutAll: '</div>'; nl;
	    nextPutAll: '<hr/><p>This document is generated on %1' % {DateTime now}; nl;
	    nextPutAll: '</p></body></html>'; nl
    ]

    generateHTML [
	<category: 'html-printing'>
	| dir |
	super generateHTML.
	instances size = 0 ifTrue: [^self].
	dir := File name: entityName.
	dir exists ifFalse: [dir createDirectory].
	Directory working: dir.
	instances do: [:i | i generateHTML].
	Directory working: '..'
    ]

    printHTMLOn: aStream [
	<category: 'html-printing'>
	self printHTMLHeaderOn: aStream.
	self printHTMLPortSummaryOn: aStream.
	instances size > 0 ifTrue: [
	    self printHTMLInstanceSummaryOn: aStream.
	    self printHTMLInstancesOn: aStream].
	self printHTMLWiresOn: aStream.
	self printHTMLFooterOn: aStream
    ]

    printHTMLInstanceSummaryOn: aStream [
	<category: 'html-printing'>
	aStream nextPutAll: '<h2>Instance Summary</h2><table  border="1">'; nl.
	instances asSortedCollection do: [:i |
	    i printHTMLSummaryOn: aStream ].
	aStream nextPutAll: '</table><hr/>'; nl
    ]

    printHTMLHierOn: aStream [
	<category: 'html-printing'>
	instances size = 0 ifTrue: [^self].
	aStream nextPutAll: '<ul>'; nl.
	instances asSortedCollection do: [ :i |
	    i hideInHTML ifFalse: [
		aStream nextPutAll:
		    '<li><a href="%1/%2.html">%2</a> (%3: %4)' %
		    {self fullPath. i name. i type. i referenceName}; nl.
		i printHTMLHierOn: aStream.
		aStream nextPutAll: '</li>'; nl]].
	aStream nextPutAll: '</ul>'; nl
    ]

    printHTMLInstancesOn: aStream [
	<category: 'html-printing'>
	aStream nextPutAll: '<h2>%1 instances</h2><ul>' % {instances size}; nl.
	instances asSortedCollection do: [:i | 
	    aStream nextPutAll: '<li>'.
	    i printInstanceHTMLOn: aStream.
	    aStream nextPutAll: '</li>'; nl].
	aStream nextPutAll: '</ul><hr/>'; nl
    ]

    printHTMLWiresOn: aStream [
	<category: 'html-printing'>
	aStream nextPutAll: '<h2>%1 wires</h2><ul>' % {wires size}; nl.
	wires asSortedCollection do: [ :w | 
	    aStream nextPutAll: '<li>'.
	    w printHTMLOn: aStream.
	    aStream nextPutAll: '</li>'; nl].
	aStream nextPutAll: '</ul><hr/>'; nl
    ]

]

DANMAssertion extend [

    hideInHTML [
	<category: 'html-printing'>
	"assertion is hiden in html"
	^true
    ]

    printHTMLSummaryOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<tr><td>%1</td><td><a href="#INST_%1">instance</a></td><td><a href="%2/%1.html">%3</a></td></tr>' % 
	    {entityName. context name. self referenceName}; nl
    ]

    printInstanceHTMLOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<h3>Assertion <a name="INST_%1">%1</a>(%2) <a href="%3/%1.html">%4</a></h3>' %
	    {entityName. self referenceName. context name. self type}; nl;
	    nextPutAll: '<p>%1</p><ul>' % {self comment}; nl.
	connections size > 0 ifTrue: [self printHTMLConnectionsOn: aStream].
	parameters notNil ifTrue: [self printHTMLParametersOn: aStream].
	aStream nextPutAll: '</ul>'; nl
    ]

]

DANMWire extend [

    topName [
	<category: 'html-printing'>
	| upperWire port s |
	context isNil ifTrue: [
	    self error: 'I ,%1, have no context!' % {self}; nl].
	port := context findPortByName: entityName.
	port notNil ifTrue: [upperWire := context wireOnPort: port].
	upperWire = self ifTrue: [
	    self error: 'hier violation on %1' % {entityName}].
	upperWire notNil ifTrue: [^upperWire topName].
	s := context fullPath , '/' , entityName.
	^s copyFrom: (s indexOf: $/) + 1
    ]

    printHTMLOn: aStream [
	<category: 'html-printing'>
	self printHTMLHeadOn: aStream.
	self printHTMLTailOn: aStream
    ]

    printHTMLHeadOn: aStream [
	<category: 'html-printing'>
	aStream nextPutAll: '<h3>Wire <a name="WIRE_%1">%1</a></h3><ul><li>width is %2.</li>' %
	    {entityName. self width}; nl
    ]

    printHTMLTailOn: aStream [
	<category: 'html-printing'>
	| port |
	aStream nextPutAll: '<li>top name: %1</li>' % {self topName}.
	port := context findPortByName: entityName.
	port notNil ifTrue: [self printPort: port inHTMLOn: aStream].
	self connectionsSize > 0 ifTrue: [self printHTMLConnectionsOn: aStream].
	refs notNil ifTrue: [self printHTMLRefsOn: aStream].
	aStream nextPutAll: '</ul>'; nl
    ]

    printHTMLRefsOn: aStream [
	<category: 'html-printing'>
	| clockSet dataSet directSet |
	clockSet := self clockRefSet.
	clockSet size > 0 ifTrue: [
	    aStream nextPutAll: '<li>drives clock of:'.
	    clockSet do: [:each |
		aStream nextPutAll: ' <a href="#WIRE_%1">%1</a>' % {each name}].
	    aStream nextPutAll: '</li>'; nl].
	dataSet := self dataRefSet.
	dataSet size > 0 ifTrue: [
	    aStream nextPutAll: '<li>drives data of:'.
	    dataSet do: [ :each |
		aStream nextPutAll: ' <a href="#WIRE_%1">%1</a>' % {each name}].
	    aStream nextPutAll: '</li>'; nl].
	directSet := self directRefSet.
	directSet size > 0 ifTrue: [
	    aStream nextPutAll: '<li>directly drives:'.
	    directSet do: [ :each |
		aStream nextPutAll: ' <a href="#WIRE_%1">%1</a>' % {each name}].
	    aStream nextPutAll: '</li>'; nl]
    ]

    printPort: port inHTMLOn: aStream [
	<category: 'html-printing'>
	| upperSch upperWire |
	upperSch := context context.
	upperWire := context wireOnPort: port.
	aStream nextPutAll: '<li>%1 port. ' % {port direction asString}.
	upperSch notNil & upperWire notNil ifTrue: [
	    aStream 
		nextPutAll: '<a href="../%1.html#WIRE_%2">upper level</a>' % 
		{upperSch name. upperWire name}].
	aStream nextPutAll: '</li>'; nl
    ]

    printHTMLConnectionsOn: aStream [
	<category: 'html-printing'>
	aStream
	    nextPutAll: '<li>connections:<table  border="1">'; nl;
	    nextPutAll: '<tr><th>instance</th><th>port</th><th>direction</th></tr>'; nl.
	self connections do: [ :p | 
	    aStream
		nextPutAll: '<tr><td><a href="#INST_%1">%1</a></td><td><a href="%2/%1.html#WIRE_%3">%3</a></td><td>%4</td></tr>' %
		{p context name. context name. p name. p direction asString}; nl].
	aStream nextPutAll: '</table></li>'
    ]

]
