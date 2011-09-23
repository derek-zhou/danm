PackageLoader fileInPackage: 'DANM'!

!UndefinedObject methodsFor: 'main function'!
main
    |s1 fs s2|
    s1 := DANMLibrary moduleByName: 'tv' fromPaths: {
        '../../verilog/misc'.
        '../../verilog/mul'.
        '../../verilog/tvdec'.
        '../../verilog/tvdec_sim'}.
    s1 checkDesign
        ifFalse: [ Transcript nextPutAll: 'Check design failed'; nl]
        ifTrue: [ Transcript nextPutAll: 'Check design passed'; nl].
    Transcript nextPutAll: 'Writing html docs'; nl.
    s1 generateHTMLAsTop.
    Transcript nextPutAll: 'Writing verilog'; nl.
    s1 generateFullVerilogTo: '%1.v' % {s1 referenceName}.
    Transcript nextPutAll: 'Flattening'; nl.
    s1 flattenAllForSynthesis.
    s2 := s1.
    s1 := s1 wrapAll.
    s1 expelAllInstances.
    Transcript nextPutAll: 'Wrapped'; nl.
    s2 checkDesign 
        ifFalse: [ Transcript nextPutAll: 'Check design failed'; nl]
        ifTrue: [ Transcript nextPutAll: 'Check design passed'; nl].
    s1 reportStatistic.
    Transcript nextPutAll: 'Optimizing'; nl.
    s1 optimize.
    s1 reportStatistic.
    s1 checkFeedThrough.
    s1 checkCascadingLatch.
    (s1 wireByName: 'RSTB') value: 0.
    s1 checkQuiescentState.
    Transcript nextPutAll: 'Writing flatten verilog'; nl.
    s2 generateFullVerilogTo: '%1_flat.v' % {s2 referenceName}.
    Transcript nextPutAll: 'Writing object dump'; nl.
    fs := (File name: '%1_flat.sod' % {s1 referenceName}) writeStream.
    s1 setTopModule.
    ObjectDumper dump: s1 to: fs.
    fs close.
"    Transcript nextPutAll: 'Writing dependency digram'; nl.
    fs := (File name: 'dependency.dot') writeStream.
    s1 printDigraphOn: fs.
    fs close"
!
!

nil main!
