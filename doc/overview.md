Design Automation aNd Manipulation
==================================

DANM, short for "Design Automation aNd Manipulation", is a tool written by
Derek for use in synthesizable RTL design. It can do the following:

 * simplify authoring
 * generate documentation
 * generate design statistic and design rule check
 * programmably manipulate the design

# Concepts #

## blackbox ##

A blackbox is a module written in verilog. DANM can read it and
understand the interface such as ports and parameters, then
incorporate it into more complex designs. DANM does not try to
understand inner work of the module, jist interface. Only Verilog-1995
is supported currently.

## schematic ##

A schematic is a design unit written in smalltalk using the DANM
library. The basic idea is like drawing a schematic but with text; you
instantiate mudules, such as blackboxes or other schematics, connect
wires and label ports. The design is built up from the bottom.

## library ##

A library is a set of paths to be searched for sub modules, in either
plain verilog (blackboxes) or smalltalk (danm schematics)

## instance ##

An instance is a module instantiate inside the schematic. If it is
also a DANM schematic it is uniqified automatically. During the
instantiation process, it is elaborated with specific parameters (same
as verilog parameters)

## wire ##

A wire is a one or multibit connections between instances. It has to
have one source, could be:

 * an input port
 * an output port of an instance within the same level
 * an expression
 
It can have zero or more loads, such as:

 * an output port
 * an input port of an instance within the same level
 * an identifier used in other expression
 
## expression ##

An expression is the meat of the behaviorial modeling. It can be:

 * constant
 * identifier reference other wire
 * simple verilog arithmatic expression
 * more complex structure that map to verilog flop, latch, if or case
   statements
   
DANM does not cover unsynthesisable design; it is expected a higher
level test bench, for example in system verilog, will instantiate the
verilog output from DANM.

# authoring #

Please refer to the examples dir for a few concrate
examples. Basically, to make a schematic you need to subclass
DANMSchematic and name the subclass as DANMSchematic_xxx, where xxx is
the name you would have for the schematic. There is only one method
you have to overload, which is the init: method. Inside this method,
you can use the DANM api to progressively build up your schematic. The
following sections cite examples from the examples dir.

## adding instance ##

Example:

	(self addInstanceOf: 'fifo_control_sync' name: 'control')
	    setParameter: 'slow_slave' to: (self slowSlave ifTrue: [1] ifFalse: [0]);
	    setParameter: 'slow_master' to: (self slowMaster ifTrue: [1] ifFalse: [0]);
	    setParameter: 'master_depth' to: self depth.

This statement add an Instance of 'fifo_control_sync' into the design,
with the name as 'control'. 'fifo_control_sync' must be a blackbox or
schematic that can be found in your library. if you do not name your
instance danm will assign a name for you; it is highly recommand to
always name your instance, the auto-naming rule may be subject to
change. You have to know the name of your instance for further
connections.

Each module can have several parameters like in verilog. Parameters
must be integers. You can set parameters at instantiation time as a
way to customize the instance.

## connectiing instance ##

Example: 

	self connect: {'control/master_en'. 'ram/we'} name: 'master_en'.

This statement connect 2 pins together with a wire, and name the wire
'master_en'. If you do not name the wire, a system generated unique
name will be generated for you. If the name exists, the existing wire
will additionally connect to those pins. During design check, danm
will check to make sure there is only one driver and thw width of all
pins agree.

## making ports ##

Example: 

	self expose: 'master_en'.
	
A wire can be exposed, to become a port. The direction of the port is
automatically figured out; if there is no driver, it becomes an input
port; if there is a driver already, it becomes a output ports. You can
also do auto expose:

    self
		autoExposeOutputs;
		autoExposeInputs.
		
These statements will expose all unloaded wires and all undriven
wires. There could be also chance that you don't want to expose
something, but want to expose the rest; here is how you do it:

	self conceal: 'dangle'.
	
The wire 'dangle' will be marked as concealed, so it wont be exposed
in following auto expose. 

## using parameters ##

Parameters do not need to be declared. You can get the parameter value
by:

	self parameterValue: 'depth'
	
Usually, you want to have sane default and some sanity checking on the
value, so you can define a get accessor method:

    width [
	<category: 'accessing'>
	(self hasParameter: 'width') ifFalse: [^64].
	^self parameterValue: 'width'
    ]

# Summary #

With the above, you can do basic bottom-up hierachical design using
danm. The next section will deal with behavioral RTL design.
