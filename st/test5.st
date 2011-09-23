PackageLoader fileInPackage: 'DANM'!

Smalltalk at: #fs put: (File name: 'tv_wrapper_flat.sod') readStream!
Smalltalk at: #s1 put: (ObjectDumper loadFrom: fs)!
fs close!
