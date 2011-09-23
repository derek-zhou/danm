PackageLoader fileInPackage: 'SUnit'!

TestCase subclass: #ExpressionTest
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

ExpressionTest comment:
    'test for expression parsing and evaluating'!

!ExpressionTest methodsFor: 'tests'!

testTruncate
    |e1|
    "4d23 should be truncated to 4 bit which is 7"
    e1 := ExpressionAST newFrom: '1+4d23'.
    self should: [ e1 evaluate == 8 ]!

testExtract
    |e1|
    e1 := ExpressionAST newFrom: '(1+6d23)[3:1]'.
    Transcript nextPutAll: 'evaluate %1 to %2' % {e1. e1 evaluate}; nl.
    self should: [ e1 evaluate == 4 ]!

testGeneralExtract
    |e1|
    e1 := ExpressionAST newFrom: '6d23[3:0:2]'.
    Transcript nextPutAll: 'evaluate %1 to %2' % {e1. e1 evaluate}; nl.
    self should: [ e1 evaluate == 1 ]!
!
