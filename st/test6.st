PackageLoader fileInPackage: 'DANM'.
Smalltalk at: #s1 put: (DANMLibrary moduleByName: 'tv_sim' fromPaths: {
        '../../verilog/misc'.
        '../../verilog/mul'.
        '../../verilog/tvdec'.
        '../../verilog/tvdec_sim'}).
s1 checkDesign 
    ifTrue: [ 
        Transcript nextPutAll: 'check design passed'; nl ]
    ifFalse: [ 
        Transcript nextPutAll: 'check design failed'; nl ].
s1 flattenAll.
s1 optimizeNoTrim.
Smalltalk at: #sim put: (DANMSimulator on: s1).
Smalltalk at: #dumper put: (DANMVCDDumper on: sim).
sim settle.

