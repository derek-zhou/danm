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
you have to overload, which is the init: method. 
