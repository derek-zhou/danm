DANMSchematic subclass: #DANMSchematic_sch1
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: ''!

!DANMSchematic_sch1 methodsFor: 'construction'!

init
    self comment: 'test schematic'.
    (self addInstance: 'addressgen' name: 'u1') 
        setParameter:'A' to: 10.
    self addInstance: 'states_gen' name: 'u2'.
    self connectAllPins: 'CLK'.
    self connectAllPins: 'RSTB'.
    self connectAllPins: 'SCLK'.
    self autoConnect.
    self connect: {'u1/DIN'} to: 'ADDR,STATE*4' name: 'DIN'.
    self autoExposeInputs: true outputs: true!
!
