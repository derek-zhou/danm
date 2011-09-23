PackageLoader fileInPackage: 'DANM'!

!UndefinedObject methodsFor: 'main function'!
main
    |s1 sim dumper|
    s1 := DANMLibrary moduleByName: 'tv_sim' fromPaths: {
        '../../verilog/misc'.
        '../../verilog/mul'.
        '../../verilog/tvdec'.
        '../../verilog/tvdec_sim'}.
    s1 checkDesign.
    Transcript nextPutAll: 'Flattening'; nl.
    s1 flattenAll.
    Transcript nextPutAll: 'Optimizing'; nl.
    s1 optimizeNoTrim.
    sim := DANMSimulator on: s1.
    dumper := DANMVCDDumper on: sim.
    Transcript nextPutAll: 'Settling'; nl.
    sim settle.
    Transcript nextPutAll: 'Running'; nl.
    sim runUpto: 10000.
    Transcript nextPutAll: 'Done'; nl!
!
nil main!
