TestCase subclass: ExpressionTest [
    <comment: 'test for expression parsing and evaluating'>

    expressionEvaluateString: str expect: v [
	|e1|
	e1 := ExpressionAST newFrom: str.
	Transcript nextPutAll: 'evaluate %1 to %2' % {e1. e1 evaluate}; nl.
	self should: [e1 evaluate == v]
    ]

    testTruncate [
	self expressionEvaluateString: '1+4d23' expect: 8
    ]

    testExtract [
	self expressionEvaluateString: '(1+6d23)[3:1]' expect: 4
    ]

    testGeneralExtract [
	self expressionEvaluateString: '6d23[3:0:-2]' expect: 1
    ]
]
